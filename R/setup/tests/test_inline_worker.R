# Test inline worker definition vs passing functions as globals
# Date: 2025-11-19

library(crew)
library(logger)
library(nanonext)

source("R/walker.R")
source("R/grid.R")
source("R/async_controller.R")

log_threshold(INFO)

# Set up test data
grid_size <- 10
walker <- create_walker(1, c(5, 5), grid_size)
grid <- initialize_grid(grid_size)
grid_state <- list(
  grid = grid,
  black_pixels = list("5,5" = c(5, 5)),
  grid_size = grid_size,
  version = 1L
)

# Create pub socket
pub_socket <- create_pub_socket(5555)
pub_address <- "tcp://127.0.0.1:5555"

# Create controller
controller <- create_controller(1)

# Test: Define worker logic inline instead of passing function
log_info("Testing inline worker logic...")
controller$push(
  command = {
    # Load required packages first
    library(nanonext)
    library(logger)

    # Now define worker_init inline
    worker_init_inline <- function(pub_addr) {
      socket <- nano("sub", dial = pub_addr)
      subscribe(socket, "")
      Sys.sleep(0.1)
      list(
        socket = socket,
        cache = list(black_pixels = list(), version = 0L)
      )
    }

    # Initialize worker
    worker_state <- worker_init_inline(pub_address)

    # Return success
    list(success = TRUE, socket_class = class(worker_state$socket))
  },
  data = list(
    pub_address = pub_address
  )
)

# Wait for result - poll until complete
log_info("Waiting for task...")
max_wait <- 30
start_time <- Sys.time()
result <- NULL

while (is.null(result) && as.numeric(difftime(Sys.time(), start_time, units = "secs")) < max_wait) {
  result <- controller$pop(scale = TRUE)
  if (is.null(result)) {
    Sys.sleep(0.5)
  }
}

if (is.null(result)) {
  log_error("Task did not complete within {max_wait} seconds")
  log_info("Controller summary:")
  print(controller$summary())
}

if (!is.null(result) && nrow(result) > 0) {
  log_info("Status: {result$status}")
  if (result$status == "success") {
    log_info("Result: {paste(names(result$result[[1]]), result$result[[1]], collapse = ', ')}")
  } else {
    log_error("Error: {result$error}")
  }
} else {
  log_error("No result")
}

# Cleanup
cleanup_async(controller, pub_socket)
log_info("Test complete")
