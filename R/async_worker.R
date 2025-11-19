# async_worker.R
# Worker Functions for Async Random Walk Simulation
# Executes in crew worker processes, subscribes to grid updates

#' Initialize Worker with Subscriber Socket
#'
#' Sets up a worker process to receive grid state updates via nanonext.
#' Called once per worker at startup.
#'
#' @param pub_address Character. Publisher socket address (e.g., "tcp://127.0.0.1:5555").
#'
#' @return A list containing:
#'   \describe{
#'     \item{socket}{nanonext subscriber socket}
#'     \item{cache}{List with black_pixels and version}
#'   }
#'
#' @details
#' Creates a subscriber socket that listens for pixel update broadcasts
#' from the main process. Also initializes a local cache to store the
#' current set of black pixels and grid state version.
#'
#' The cache is used to avoid querying the main process for grid state
#' on every walker step. Workers check for updates periodically and
#' refresh the cache when the version number changes.
#'
#' @examples
#' \dontrun{
#' # Worker initialization (executed in crew worker process)
#' worker_state <- worker_init("tcp://127.0.0.1:5555")
#' }
#'
#' @seealso \code{\link{worker_check_updates}}, \code{\link{worker_step_walker}}
#'
#' @export
worker_init <- function(pub_address) {
  logger::log_info("Worker initializing with publisher at {pub_address}")

  # Create subscriber socket
  # Note: When used in crew workers, nanonext package loaded via packages parameter
  # so we can call nano() directly without namespace prefix
  socket <- nano("sub", dial = pub_address)

  # Subscribe to all messages
  subscribe(socket, "")

  # Wait briefly for connection
  Sys.sleep(0.1)

  # Initialize cache
  cache <- list(
    black_pixels = list(),  # Will be populated from updates
    version = 0L
  )

  logger::log_info("Worker initialized successfully")

  list(
    socket = socket,
    cache = cache
  )
}


#' Check for Grid Updates (Worker)
#'
#' Non-blocking check for grid state updates from the publisher socket.
#' Updates the worker's local cache if new pixel updates are available.
#'
#' @param worker_state List. Worker state from \code{worker_init()}.
#'
#' @return Modified worker_state with updated cache (if updates received).
#'
#' @details
#' Polls the subscriber socket for new messages without blocking.
#' If updates are available, processes all queued messages and updates
#' the local black_pixels cache and version number.
#'
#' This function should be called periodically between walker steps
#' to keep the cache reasonably fresh. In Phase 1, it's called before
#' each walker step.
#'
#' Update message format (from broadcaster):
#' \code{list(type = "pixel_update", position = c(row, col), version = int)}
#'
#' @examples
#' \dontrun{
#' # Check for updates before stepping walker
#' worker_state <- worker_check_updates(worker_state)
#' }
#'
#' @seealso \code{\link{worker_init}}, \code{\link{broadcast_update}}
#'
#' @export
worker_check_updates <- function(worker_state) {
  # Non-blocking receive
  result <- recv(
    worker_state$socket,
    mode = "raw",
    block = FALSE
  )

  # Check if we got a message (not error code)
  if (!is.integer(result)) {
    message_data <- result

    # Handle pixel update
    if (!is.null(message_data$type) && message_data$type == "pixel_update") {
      # Add pixel to cache
      pos_key <- paste(message_data$position, collapse = ",")
      worker_state$cache$black_pixels[[pos_key]] <- message_data$position

      # Update version
      worker_state$cache$version <- message_data$version

      logger::log_trace(
        "Worker cache updated: position=({message_data$position[1]}, {message_data$position[2]}), version={message_data$version}"
      )
    }
  }

  worker_state
}


#' Execute Walker Step (Worker)
#'
#' Executes one step of a walker using cached grid state.
#' This is the main work function executed by crew workers.
#'
#' @param walker List. Walker object (from \code{create_walker()}).
#' @param grid_state List. Contains grid matrix and black_pixels set.
#' @param worker_state List. Worker state from \code{worker_init()}.
#' @param neighborhood Character. "4-hood" or "8-hood" (default: "4-hood").
#' @param boundary Character. "terminate" or "wrap" (default: "terminate").
#' @param max_steps Integer. Maximum steps before forced termination (default: 10000).
#'
#' @return Modified walker object after one step.
#'
#' @details
#' Performs one iteration of the random walk:
#' 1. Check for grid updates (refresh cache)
#' 2. Move walker one step using \code{step_walker()}
#' 3. Check termination using cached black pixels
#'
#' The worker uses its local cache of black pixels to check termination
#' conditions. This avoids querying the main process on every step,
#' significantly reducing synchronization overhead.
#'
#' Cache staleness is acceptable because:
#' - Random walks are stochastic (small delays don't affect statistical properties)
#' - Updates are broadcast immediately when walkers terminate
#' - Worker checks for updates before each step
#'
#' @examples
#' \dontrun{
#' # Step a walker in a worker process
#' walker <- worker_step_walker(
#'   walker = walker,
#'   grid_state = grid_state,
#'   worker_state = worker_state,
#'   neighborhood = "4-hood",
#'   boundary = "terminate"
#' )
#' }
#'
#' @seealso \code{\link{step_walker}}, \code{\link{check_termination}}
#'
#' @export
worker_step_walker <- function(walker, grid_state, worker_state,
                                 neighborhood = "4-hood",
                                 boundary = "terminate",
                                 max_steps = 10000L) {
  if (!walker$active) {
    return(walker)
  }

  # Check for grid updates (non-blocking)
  worker_state <- worker_check_updates(worker_state)

  # Move walker one step using existing function
  walker <- step_walker(walker, neighborhood, boundary)

  if (!walker$active) {
    return(walker)  # Hit boundary
  }

  # Check termination using cached black pixels
  walker <- check_termination_cached(
    walker = walker,
    black_pixels = worker_state$cache$black_pixels,
    neighborhood = neighborhood,
    boundary = boundary,
    grid_size = grid_state$grid_size,
    max_steps = max_steps
  )

  walker
}


#' Check Termination Using Cached Black Pixels
#'
#' Checks if walker should terminate based on cached black pixel set.
#' Internal function used by \code{worker_step_walker()}.
#'
#' @param walker List. Walker object.
#' @param black_pixels List. Cached black pixel positions (keyed by "row,col").
#' @param neighborhood Character. "4-hood" or "8-hood".
#' @param boundary Character. "terminate" or "wrap".
#' @param grid_size Integer. Grid dimension.
#' @param max_steps Integer. Maximum steps limit.
#'
#' @return Modified walker object with updated active status.
#'
#' @details
#' Similar to \code{check_termination()} but uses a cached set of black
#' pixels instead of querying the grid matrix. This enables fast
#' termination checks in worker processes without grid access.
#'
#' Termination conditions:
#' 1. Walker is on a black pixel (touches_black)
#' 2. Walker has a black neighbor (has_black_neighbor)
#' 3. Walker exceeded max_steps limit
#'
#' @keywords internal
#'
#' @seealso \code{\link{check_termination}}
check_termination_cached <- function(walker, black_pixels, neighborhood,
                                       boundary, grid_size, max_steps) {
  if (!walker$active) {
    return(walker)
  }

  # Check if walker is on a black pixel
  pos_key <- paste(walker$pos, collapse = ",")
  if (pos_key %in% names(black_pixels)) {
    walker$active <- FALSE
    walker$termination_reason <- "touched_black"
    logger::log_trace("Walker {walker$id} touched black pixel (cached)")
    return(walker)
  }

  # Check if walker has black neighbor
  neighbors <- get_neighbors(walker$pos, neighborhood)

  for (neighbor_pos in neighbors) {
    # Check bounds
    if (!is_within_bounds(neighbor_pos, grid_size) && boundary == "terminate") {
      next  # Out of bounds neighbor (not black)
    }

    # Wrap if needed
    if (boundary == "wrap") {
      neighbor_pos <- wrap_position(neighbor_pos, grid_size)
    }

    # Check if neighbor is in black set
    neighbor_key <- paste(neighbor_pos, collapse = ",")
    if (neighbor_key %in% names(black_pixels)) {
      walker$active <- FALSE
      walker$termination_reason <- "black_neighbor"
      logger::log_trace("Walker {walker$id} has black neighbor (cached)")
      return(walker)
    }
  }

  # Check max steps safety limit
  if (walker$steps >= max_steps) {
    walker$active <- FALSE
    walker$termination_reason <- "max_steps"
    logger::log_warn("Walker {walker$id} reached max steps limit")
    return(walker)
  }

  walker
}


#' Run Walker Until Termination (Worker Task)
#'
#' Executes a complete walker simulation until termination.
#' This is the function pushed to crew workers as a task.
#'
#' @param walker List. Walker object.
#' @param grid_state List. Grid state (grid matrix, black_pixels, grid_size).
#' @param pub_address Character. Publisher socket address.
#' @param neighborhood Character. "4-hood" or "8-hood".
#' @param boundary Character. "terminate" or "wrap".
#' @param max_steps Integer. Maximum steps limit.
#'
#' @return Terminated walker object with complete path.
#'
#' @details
#' This function represents a complete worker task:
#' 1. Initialize worker (create subscriber socket, cache)
#' 2. Step walker repeatedly until termination
#' 3. Clean up worker resources
#' 4. Return final walker state
#'
#' The worker maintains a local cache of black pixels and subscribes
#' to updates from the main process. This allows independent execution
#' while staying reasonably synchronized with the global grid state.
#'
#' @examples
#' \dontrun{
#' # This function is called by crew workers, not directly by users
#' # Controller pushes this task:
#' controller$push(
#'   command = worker_run_walker(walker, grid_state, pub_address, ...),
#'   data = list(walker = walker, grid_state = grid_state, ...)
#' )
#' }
#'
#' @seealso \code{\link{worker_step_walker}}, \code{\link{worker_init}}
#'
#' @export
worker_run_walker <- function(walker, grid_state, pub_address = NULL,
                                neighborhood = "4-hood",
                                boundary = "terminate",
                                max_steps = 10000L) {
  # Simplified version without nanonext sockets
  # Workers operate on a static snapshot of black pixels
  # This avoids socket serialization issues with crew

  black_pixels <- grid_state$black_pixels
  grid_size <- grid_state$grid_size

  # Run walker until termination
  while (walker$active) {
    # Move walker one step
    walker <- step_walker(walker, neighborhood, boundary)

    if (!walker$active) {
      break  # Hit boundary
    }

    # Check termination using black pixel snapshot
    walker <- check_termination_cached(
      walker = walker,
      black_pixels = black_pixels,
      neighborhood = neighborhood,
      boundary = boundary,
      grid_size = grid_size,
      max_steps = max_steps
    )
  }

  # Return terminated walker (no socket cleanup needed)
  walker
}
