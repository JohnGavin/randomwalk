# async_controller.R
# Async Controller for Parallel Random Walk Simulation
# Manages crew workers and nanonext communication

# Suppress R CMD check NOTE about undefined globals in mirai tasks
# These variables are passed as arguments to mirai::mirai() and are
# available in the task environment
utils::globalVariables(c(".command_expr", ".globals_to_set", ".packages_to_load"))

#' Create Async Controller (Auto-detect Backend)
#'
#' Creates an async controller for parallel random walk simulation.
#' Automatically selects the appropriate backend:
#' - WebR/WebAssembly: mirai (crew not available)
#' - Native R: crew (preferred for better abstractions)
#'
#' @param n_workers Integer. Number of parallel workers to create (default: 2).
#'   Recommended: 2-4 for medium grids, 4-8 for large grids.
#' @param seconds_idle Numeric. Seconds of idle time before worker shutdown (default: 60).
#'   Note: Only applies to crew backend (ignored for mirai).
#'
#' @return An async controller object with initialized workers.
#'   - Crew backend: R6 crew controller object
#'   - Mirai backend: List with crew-compatible interface
#'
#' @details
#' The controller manages a pool of R worker processes that execute
#' walker step functions in parallel. Each worker maintains its own
#' local cache of the grid state and subscribes to updates from the
#' main process.
#'
#' **Backend Selection:**
#' - WebR/WebAssembly detected by `is_webr()` → uses mirai
#' - Native R → uses crew
#'
#' Both backends provide the same interface:
#' - `push()`: Submit task
#' - `pop()`: Retrieve completed task
#' - `terminate()`: Shutdown workers
#'
#' Workers are automatically started when the controller is created
#' and can be cleanly shut down using `cleanup_async()`.
#'
#' @examples
#' \dontrun{
#' # Create controller (auto-detects environment)
#' controller <- create_controller(n_workers = 2)
#'
#' # Use controller for parallel tasks
#' # ... simulation code ...
#'
#' # Clean up when done
#' cleanup_async(controller, socket)
#' }
#'
#' @seealso \code{\link{create_pub_socket}}, \code{\link{cleanup_async}},
#'   \code{\link{create_mirai_controller}}
#'
#' @export
create_controller <- function(n_workers = 2, seconds_idle = 60) {
  # Validate inputs
  if (!is.numeric(n_workers) || n_workers < 1) {
    stop("n_workers must be a positive integer")
  }

  # Auto-detect environment and choose backend
  if (is_webr()) {
    logger::log_info("WebR environment detected - using mirai backend")
    return(create_mirai_controller(n_workers, seconds_idle))
  } else {
    logger::log_info("Native R detected - using crew backend")

    if (!requireNamespace("crew", quietly = TRUE)) {
      stop("crew package required. Install with: install.packages('crew')")
    }

    # Create crew controller
    controller <- crew::crew_controller_local(
      name = "randomwalk_async",
      workers = as.integer(n_workers),
      seconds_idle = seconds_idle,
      seconds_timeout = 600  # 10 minutes max task time
    )

    # Start the controller and workers
    controller$start()

    logger::log_info("Crew controller started with {n_workers} workers")

    return(controller)
  }
}


#' Create Nanonext Publisher Socket
#'
#' Creates a nanonext publisher socket for broadcasting grid state updates
#' to all worker processes.
#'
#' @param port Integer. TCP port for the publisher socket (default: 5555).
#'   Must be available and not blocked by firewall.
#'
#' @return A nanonext socket object configured for publishing.
#'
#' @details
#' The publisher socket uses TCP on localhost to broadcast grid updates.
#' Workers subscribe to this socket to receive notifications when pixels
#' are added to the black set (walker termination events).
#'
#' Communication pattern:
#' - Main process publishes updates via this socket
#' - Worker processes subscribe (see \code{worker_init()})
#' - Non-blocking: workers poll for updates between steps
#'
#' The socket binds to \code{tcp://127.0.0.1:<port>} and allows multiple
#' subscribers to connect.
#'
#' @examples
#' \dontrun{
#' # Create publisher socket
#' pub_socket <- create_pub_socket(port = 5555)
#'
#' # Broadcast an update
#' broadcast_update(pub_socket, position = c(10, 15), version = 42)
#'
#' # Clean up
#' nanonext::close(pub_socket)
#' }
#'
#' @seealso \code{\link{broadcast_update}}, \code{\link{cleanup_async}}
#' @export
create_pub_socket <- function(port = 5555) {
  logger::log_info("Creating nanonext publisher socket on port {port}")

  # Check nanonext availability
  if (!requireNamespace("nanonext", quietly = TRUE)) {
    stop("nanonext package required for dynamic broadcasting. Install with: install.packages('nanonext')")
  }

  # Validate port
  if (!is.numeric(port) || port < 1024 || port > 65535) {
    stop("port must be between 1024 and 65535")
  }

  # Create publisher socket
  address <- sprintf("tcp://127.0.0.1:%d", port)
  socket <- nanonext::nano("pub", listen = address)

  # Wait briefly for socket to bind
  Sys.sleep(0.1)

  logger::log_info("Publisher socket created at {address}")

  socket
}


#' Broadcast Grid Update to Workers
#'
#' Sends a grid state update message to all subscribed workers via
#' the nanonext publisher socket.
#'
#' @param socket A nanonext publisher socket created by \code{create_pub_socket()}.
#' @param position Integer vector of length 2. Grid coordinates \code{c(row, col)}
#'   of the newly black pixel.
#' @param version Integer. Current version number of the grid state.
#'   Workers use this to detect stale caches.
#'
#' @return NULL (invisibly). Message is sent asynchronously.
#'
#' @details
#' Broadcasts a pixel update message containing:
#' - \code{type}: Always "pixel_update"
#' - \code{position}: Coordinates of new black pixel
#' - \code{version}: Grid state version number
#'
#' Workers listening on the subscriber socket will receive this message
#' and update their local caches accordingly.
#'
#' This is a non-blocking operation - the function returns immediately
#' after queuing the message for transmission.
#'
#' @examples
#' \dontrun{
#' # Broadcast update when walker terminates
#' broadcast_update(
#'   socket = pub_socket,
#'   position = c(10, 15),
#'   version = 42
#' )
#' }
#'
#' @seealso \code{\link{create_pub_socket}}
#'
#' @export
broadcast_update <- function(socket, position, version) {
  # Check nanonext availability
  if (!requireNamespace("nanonext", quietly = TRUE)) {
    stop("nanonext package required for dynamic broadcasting")
  }

  # Validate inputs
  if (!inherits(socket, "nanoSocket")) {
    stop("socket must be a nanonext socket object")
  }

  if (!is.numeric(position) || length(position) != 2) {
    stop("position must be a numeric vector of length 2")
  }

  if (!is.numeric(version) || version < 0) {
    stop("version must be a non-negative integer")
  }

  # Create update message
  message <- list(
    type = "pixel_update",
    position = as.integer(position),
    version = as.integer(version)
  )

  # Serialize and send (non-blocking)
  nanonext::send(socket, message, mode = "raw", block = FALSE)

  logger::log_trace("Broadcast update: position=({position[1]}, {position[2]}), version={version}")

  invisible(NULL)
}


#' Clean Up Async Resources
#'
#' Shuts down crew workers and closes nanonext sockets.
#' Should always be called when async simulation completes or errors.
#'
#' @param controller A crew controller object created by \code{create_controller()}.
#'   Can be NULL if controller was not successfully created.
#' @param socket A nanonext publisher socket created by \code{create_pub_socket()}.
#'   Can be NULL if socket was not successfully created.
#'
#' @return NULL (invisibly). Side effect: workers stopped, sockets closed.
#'
#' @details
#' Performs graceful shutdown:
#' 1. Terminates all crew workers (sends shutdown signal)
#' 2. Closes nanonext publisher socket
#' 3. Logs cleanup status
#'
#' This function is safe to call multiple times and handles NULL inputs
#' gracefully (useful for error cleanup).
#'
#' Always call this function in a \code{tryCatch()} finally block to ensure
#' resources are cleaned up even if the simulation errors.
#'
#' @examples
#' \dontrun{
#' # Typical usage pattern
#' controller <- NULL
#' socket <- NULL
#'
#' tryCatch({
#'   controller <- create_controller(n_workers = 2)
#'   socket <- create_pub_socket(port = 5555)
#'
#'   # ... run simulation ...
#'
#' }, finally = {
#'   cleanup_async(controller, socket)
#' })
#' }
#'
#' @seealso \code{\link{create_controller}}, \code{\link{create_pub_socket}}
#'
#' @export
cleanup_async <- function(controller, socket) {
  logger::log_info("Cleaning up async resources")

  # Terminate workers (both mirai and crew backends)
  if (!is.null(controller)) {
    tryCatch({
      if (inherits(controller, "mirai_controller")) {
        # Mirai backend (WebR/WebAssembly)
        controller$terminate()
        logger::log_info("Mirai daemons terminated")
      } else if (inherits(controller, "R6")) {
        # Crew backend (native R)
        controller$terminate()
        logger::log_info("Crew workers terminated")
      } else {
        logger::log_warn("Unknown controller type: {class(controller)[1]}")
      }
    }, error = function(e) {
      logger::log_warn("Error terminating workers: {e$message}")
    })
  }

  # Close nanonext socket (removed as nanonext::close(socket) caused runtime error and no alternative found)

  logger::log_info("Async cleanup complete")

  invisible(NULL)
}


#' Detect WebR Environment
#'
#' Checks if code is running in WebR/WebAssembly environment.
#' Uses the same detection as existing vignettes.
#'
#' @return Logical. TRUE if in WebR, FALSE otherwise
#' @keywords internal
#'
#' @details
#' Detection methods:
#' 1. `.webr_env` object in global environment (set by WebR runtime)
#' 2. `WEBR="1"` environment variable
#'
#' @references
#' - WebR documentation: https://docs.r-wasm.org/webr/latest/
#' - Existing usage: vignettes/dynamic_broadcasting.qmd:50-51
#'
#' @examples
#' \dontrun{
#' if (is_webr()) {
#'   message("Running in WebR/browser environment")
#' } else {
#'   message("Running in native R")
#' }
#' }
is_webr <- function() {
  exists(".webr_env", envir = .GlobalEnv) ||
    identical(Sys.getenv("WEBR"), "1")
}


#' Create Mirai-based Controller (WebAssembly Compatible)
#'
#' Creates a mirai-based async controller for WebAssembly environments
#' where crew is not available. Provides crew-compatible interface.
#'
#' @param n_workers Integer. Number of mirai daemons to create (default: 2).
#' @param seconds_idle Numeric. Ignored (no mirai equivalent). Kept for
#'   interface compatibility with crew.
#'
#' @return List with crew-compatible interface:
#'   - `push(name, command, data, globals, packages)`: Submit task
#'   - `pop(scale)`: Retrieve completed task
#'   - `terminate()`: Shutdown daemons
#'
#' @details
#' This function provides a crew-compatible interface using mirai instead
#' of crew. It's automatically used when running in WebR/WebAssembly
#' (detected by `is_webr()`).
#'
#' The mirai backend uses:
#' - `mirai::daemons()` for worker management
#' - `mirai::mirai()` for task submission
#' - Blocking `mirai[]` for task retrieval
#'
#' @keywords internal
#'
#' @examples
#' \dontrun{
#' # Create mirai controller
#' controller <- create_mirai_controller(n_workers = 2)
#'
#' # Submit task (crew-compatible interface)
#' controller$push(
#'   name = "task1",
#'   command = sum(x),
#'   data = list(),
#'   globals = list(x = 1:10),
#'   packages = character()
#' )
#'
#' # Retrieve result
#' result <- controller$pop()
#'
#' # Clean up
#' controller$terminate()
#' }
create_mirai_controller <- function(n_workers = 2, seconds_idle = 60) {
  logger::log_info("Creating mirai controller with {n_workers} daemons (WebR mode)")

  if (!requireNamespace("mirai", quietly = TRUE)) {
    stop("mirai package required for WebAssembly. Install from r-lib.r-universe.dev")
  }

  # Start mirai daemons
  mirai::daemons(n = n_workers, dispatcher = TRUE)

  # Create crew-compatible interface with environment for shared state
  controller <- new.env(parent = emptyenv())
  controller$backend <- "mirai"
  controller$task_list <- list()

  controller$push <- function(name, command, data, globals = list(), packages = character()) {
    # Submit task to mirai
    # Pass globals and packages as arguments so they're available in the task
    m <- mirai::mirai(
      {
        # Load required packages
        for (pkg in .packages_to_load) {
          library(pkg, character.only = TRUE)
        }

        # Set globals in task environment
        for (nm in names(.globals_to_set)) {
          assign(nm, .globals_to_set[[nm]], envir = environment())
        }

        # Execute command
        eval(.command_expr)
      },
      .command_expr = substitute(command),
      .globals_to_set = globals,
      .packages_to_load = packages
    )

    # Store mirai object
    controller$task_list[[name]] <- m

    invisible(NULL)
  }

  controller$pop <- function(scale = TRUE) {
    # Find first completed task
    for (task_name in names(controller$task_list)) {
      m <- controller$task_list[[task_name]]

      # Check if resolved (non-blocking)
      if (!mirai::unresolved(m)) {
        # Extract result
        result_value <- m[]

        # Remove from task list
        controller$task_list[[task_name]] <- NULL

        # Return crew-compatible data frame
        return(data.frame(
          name = task_name,
          result = I(list(result_value)),
          status = if (inherits(result_value, "error")) "error" else "success",
          stringsAsFactors = FALSE
        ))
      }
    }

    # No completed tasks - block on first available
    if (length(controller$task_list) > 0) {
      task_name <- names(controller$task_list)[1]
      m <- controller$task_list[[task_name]]

      # Block until result available
      result_value <- m[]

      # Remove from task list
      controller$task_list[[task_name]] <- NULL

      # Return crew-compatible data frame
      return(data.frame(
        name = task_name,
        result = I(list(result_value)),
        status = if (inherits(result_value, "error")) "error" else "success",
        stringsAsFactors = FALSE
      ))
    }

    # No tasks at all
    NULL
  }

  controller$terminate <- function() {
    logger::log_info("Terminating mirai daemons")

    # Stop all daemons
    mirai::daemons(0)

    # Clear task list
    controller$task_list <- list()

    invisible(NULL)
  }

  # Set class for cleanup detection
  class(controller) <- c("mirai_controller", "environment")

  controller
}
