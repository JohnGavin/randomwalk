# Debug Script: Investigate crew result structure
# Date: 2025-11-19
# Purpose: Understand what crew$pop() returns for walker tasks
# Related to: Issue #21, async-v2-phase1 branch

library(crew)
library(logger)

# Load package from source (not installed version)
devtools::load_all(quiet = TRUE)

log_threshold(TRACE)

# Set up minimal test case
grid_size <- 10
neighborhood <- "4-hood"
boundary <- "terminate"
max_steps <- 100L

# Create a single test walker
walker <- create_walker(
  id = 1,
  pos = c(5, 5),
  grid_size = grid_size
)

# Create grid state
grid <- initialize_grid(grid_size)
grid_state <- list(
  grid = grid,
  black_pixels = list("5,5" = c(5, 5)),
  grid_size = grid_size,
  version = 1L
)

# Create controller
controller <- crew_controller_local(
  name = "debug_test",
  workers = 1,
  seconds_idle = 10
)

controller$start()

# Create pub socket (even though we won't use it for this test)
pub_socket <- create_pub_socket(5555)
pub_address <- "tcp://127.0.0.1:5555"

# Push task to worker with functions as globals
log_info("Pushing walker task to crew worker...")
controller$push(
  command = worker_run_walker(
    walker, grid_state, pub_address, neighborhood, boundary, max_steps
  ),
  data = list(
    walker = walker,
    grid_state = grid_state,
    pub_address = pub_address,
    neighborhood = neighborhood,
    boundary = boundary,
    max_steps = max_steps
  ),
  globals = list(
    worker_run_walker = worker_run_walker,
    worker_init = worker_init,
    worker_step_walker = worker_step_walker,
    check_termination_cached = check_termination_cached,
    get_neighbors = get_neighbors,
    is_within_bounds = is_within_bounds,
    wrap_position = wrap_position,
    step_walker = step_walker
  ),
  packages = c("nanonext", "logger")
)

# Wait for result - poll until task completes
log_info("Waiting for task to complete...")
max_wait <- 30  # Maximum 30 seconds
start_time <- Sys.time()
result <- NULL

while (is.null(result) && as.numeric(difftime(Sys.time(), start_time, units = "secs")) < max_wait) {
  result <- controller$pop(scale = TRUE)
  if (is.null(result)) {
    Sys.sleep(0.5)  # Wait 500ms between polls
  }
}

if (is.null(result)) {
  log_error("Task did not complete within {max_wait} seconds")
  log_info("Controller status:")
  print(controller$summary())
} else {
  log_info("Task completed in {round(as.numeric(difftime(Sys.time(), start_time, units = 'secs')), 2)} seconds")
}

# Debug output
log_info("=== CREW RESULT STRUCTURE ===")
log_info("class(result): {paste(class(result), collapse = ', ')}")
log_info("typeof(result): {typeof(result)}")
log_info("names(result): {paste(names(result), collapse = ', ')}")
log_info("nrow(result): {nrow(result)}")
log_info("\n=== TASK STATUS ===")
log_info("status: {result$status}")
log_info("error: {result$error}")
log_info("code: {result$code}")
log_info("warnings: {result$warnings}")
if (!is.na(result$trace) && nchar(result$trace) > 0) {
  log_info("\n=== TRACEBACK ===")
  log_info(result$trace)
}

if (!is.null(result) && nrow(result) > 0) {
  log_info("\n=== RESULT COLUMNS ===")
  for (col in names(result)) {
    log_info("{col}: class = {paste(class(result[[col]]), collapse = ', ')}, length = {length(result[[col]])}")
  }

  log_info("\n=== RESULT$RESULT ===")
  log_info("class(result$result): {paste(class(result$result), collapse = ', ')}")
  log_info("typeof(result$result): {typeof(result$result)}")
  log_info("length(result$result): {length(result$result)}")

  if (length(result$result) > 0) {
    log_info("\n=== RESULT$RESULT[[1]] ===")
    r1 <- result$result[[1]]
    log_info("class(result$result[[1]]): {paste(class(r1), collapse = ', ')}")
    log_info("typeof(result$result[[1]]): {typeof(r1)}")
    log_info("is.list(result$result[[1]]): {is.list(r1)}")
    log_info("names(result$result[[1]]): {paste(names(r1), collapse = ', ')}")

    # Try to access walker fields
    tryCatch({
      log_info("\nAttempting to access walker$id...")
      walker_id <- r1$id
      log_info("SUCCESS: walker$id = {walker_id}")
    }, error = function(e) {
      log_error("ERROR accessing walker$id: {e$message}")
    })

    # Print full structure
    log_info("\n=== FULL STRUCTURE ===")
    log_info(paste(capture.output(str(r1)), collapse = "\n"))
  }
}

# Cleanup
cleanup_async(controller, pub_socket)

log_info("Debug complete!")
