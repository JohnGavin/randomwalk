# async_controller.R
# Async Controller for Parallel Random Walk Simulation
# Manages crew workers and nanonext communication

#' Create Crew Controller for Async Simulation
#'
#' Initializes a crew controller to manage parallel R worker processes
#' for asynchronous random walk simulation.
#'
#' @param n_workers Integer. Number of parallel workers to create (default: 2).
#'   Recommended: 2-4 for medium grids, 4-8 for large grids.
#' @param seconds_idle Numeric. Seconds of idle time before worker shutdown (default: 60).
#'
#' @return A crew controller object with initialized workers.
#'
#' @details
#' The controller manages a pool of R worker processes that execute
#' walker step functions in parallel. Each worker maintains its own
#' local cache of the grid state and subscribes to updates from the
#' main process.
#'
#' Workers are automatically started when the controller is created
#' and can be cleanly shut down using \code{cleanup_async()}.
#'
#' @examples
#' \dontrun{
#' # Create controller with 2 workers
#' controller <- create_controller(n_workers = 2)
#'
#' # Use controller for parallel tasks
#' # ... simulation code ...
#'
#' # Clean up when done
#' cleanup_async(controller, socket)
#' }
#'
#' @seealso \code{\link{create_pub_socket}}, \code{\link{cleanup_async}}
#'
#' @export
create_controller <- function(n_workers = 2, seconds_idle = 60) {
  logger::log_info("Creating crew controller with {n_workers} workers")

  # Validate inputs
  if (!is.numeric(n_workers) || n_workers < 1) {
    stop("n_workers must be a positive integer")
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

  controller
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
#'
#' @export
create_pub_socket <- function(port = 5555) {
  logger::log_info("Creating nanonext publisher socket on port {port}")

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

  # Terminate crew workers
  if (!is.null(controller) && inherits(controller, "R6")) {
    tryCatch({
      controller$terminate()
      logger::log_info("Crew workers terminated")
    }, error = function(e) {
      logger::log_warn("Error terminating crew workers: {e$message}")
    })
  }

  # Close nanonext socket
  if (!is.null(socket) && inherits(socket, "nanoSocket")) {
    tryCatch({
      nanonext::close(socket)
      logger::log_info("Publisher socket closed")
    }, error = function(e) {
      logger::log_warn("Error closing publisher socket: {e$message}")
    })
  }

  logger::log_info("Async cleanup complete")

  invisible(NULL)
}
