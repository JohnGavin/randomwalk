#' Grid State Broadcasting Functions
#'
#' Functions for managing real-time grid state synchronization between workers
#' using nanonext publish-subscribe pattern.
#'
#' @name broadcasting
#' @keywords internal
NULL

#' Initialize Publisher Socket
#'
#' Creates a nanonext publisher socket for broadcasting black pixel updates
#'
#' @param port Port number for socket (default 5555)
#' @return Publisher socket object
#' @export
init_publisher_socket <- function(port = 5555) {
  if (!requireNamespace("nanonext", quietly = TRUE)) {
    stop("Package 'nanonext' is required for dynamic broadcasting mode")
  }

  pub_socket <- nanonext::socket("pub")
  nanonext::listen(pub_socket, sprintf("tcp://*:%d", port))

  message(sprintf("Publisher socket listening on port %d", port))

  return(pub_socket)
}

#' Initialize Subscriber Socket
#'
#' Creates a nanonext subscriber socket for receiving black pixel updates
#'
#' @param host Host address (default "localhost")
#' @param port Port number (default 5555)
#' @return Subscriber socket object
#' @export
init_subscriber_socket <- function(host = "localhost", port = 5555) {
  if (!requireNamespace("nanonext", quietly = TRUE)) {
    stop("Package 'nanonext' is required for dynamic broadcasting mode")
  }

  sub_socket <- nanonext::socket("sub")
  nanonext::dial(sub_socket, sprintf("tcp://%s:%d", host, port))
  nanonext::subscribe(sub_socket, "")  # Subscribe to all messages

  return(sub_socket)
}

#' Broadcast Black Pixel Update
#'
#' Serializes and broadcasts a black pixel update to all subscribers
#'
#' @param pub_socket Publisher socket
#' @param position Vector c(x, y) of black pixel position
#' @param walker_id ID of walker that created the black pixel
#' @export
broadcast_black_pixel <- function(pub_socket, position, walker_id) {
  message_data <- list(
    type = "black_pixel",
    position = position,
    walker_id = walker_id,
    timestamp = Sys.time()
  )

  nanonext::send(pub_socket, serialize(message_data, NULL))
}

#' Update Local Grid from Broadcasts
#'
#' Non-blocking check for pending black pixel updates and applies them to local grid
#'
#' @param sub_socket Subscriber socket
#' @param local_grid Current local grid state
#' @return Updated local grid
#' @export
update_grid_from_broadcasts <- function(sub_socket, local_grid) {
  # Pop all pending messages from queue
  messages_processed <- 0

  repeat {
    # Non-blocking receive (returns NULL if no message)
    msg <- nanonext::recv(sub_socket, mode = "raw", block = FALSE)

    if (is.null(msg)) {
      break  # No more messages
    }

    update <- unserialize(msg)

    if (update$type == "black_pixel") {
      pos <- update$position
      local_grid[pos[1], pos[2]] <- "black"
      messages_processed <- messages_processed + 1
    }
  }

  if (messages_processed > 0) {
    message(sprintf("Processed %d black pixel updates", messages_processed))
  }

  return(local_grid)
}

#' Close Sockets
#'
#' Properly closes nanonext sockets
#'
#' @param ... Socket objects to close
#' @export
close_sockets <- function(...) {
  sockets <- list(...)

  for (socket in sockets) {
    if (!is.null(socket)) {
      nanonext::close(socket)
    }
  }
}
