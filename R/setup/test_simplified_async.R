# Test: Simplified Async Architecture (No nanonext pub/sub)
# Date: 2025-11-19
# Goal: Test async execution using only crew's data passing

library(crew)
library(logger)

# Source functions
source("R/walker.R")
source("R/grid.R")

log_threshold(INFO)

# Set up simulation
grid_size <- 10
n_walkers <- 3
max_steps <- 100

# Initialize grid
grid <- initialize_grid(grid_size)
black_pixels <- list("5,5" = c(5, 5))  # Center pixel

# Create walkers
walkers <- lapply(seq_len(n_walkers), function(i) {
  create_walker(i, c(ceiling(grid_size/2), ceiling(grid_size/2)), grid_size)
})

# Create crew controller
controller <- crew_controller_local(name = "simple_async", workers = 2, seconds_idle = 30)
controller$start()

log_info("Starting simplified async simulation with {n_walkers} walkers, {2} workers")

# Simple worker function (passed as global)
run_walker_simple <- function(walker, black_pixels_list, neighborhood, boundary, grid_size, max_steps) {
  # Run walker until termination
  while (walker$active && walker$steps < max_steps) {
    # Move walker
    walker <- step_walker(walker, neighborhood, boundary)

    # Check if touched black pixel
    pos_key <- paste(walker$pos, collapse = ",")
    if (pos_key %in% names(black_pixels_list)) {
      walker$active <- FALSE
      walker$termination_reason <- "touched_black"
      break
    }

    # Check if has black neighbor
    neighbors <- get_neighbors(walker$pos, neighborhood)
    has_black_neighbor <- FALSE

    for (neighbor_pos in neighbors) {
      if (!is_within_bounds(neighbor_pos, grid_size) && boundary == "terminate") {
        next
      }

      if (boundary == "wrap") {
        neighbor_pos <- wrap_position(neighbor_pos, grid_size)
      }

      neighbor_key <- paste(neighbor_pos, collapse = ",")
      if (neighbor_key %in% names(black_pixels_list)) {
        has_black_neighbor <- TRUE
        break
      }
    }

    if (has_black_neighbor) {
      walker$active <- FALSE
      walker$termination_reason <- "black_neighbor"
      break
    }
  }

  if (walker$steps >= max_steps) {
    walker$active <- FALSE
    walker$termination_reason <- "max_steps"
  }

  walker
}

# Push all walker tasks
for (i in seq_along(walkers)) {
  controller$push(
    name = paste0("walker_", i),
    command = run_walker_simple(walker, black_pixels, neighborhood, boundary, grid_size, max_steps),
    data = list(
      walker = walkers[[i]],
      black_pixels = black_pixels,
      neighborhood = "4-hood",
      boundary = "terminate",
      grid_size = grid_size,
      max_steps = max_steps
    ),
    globals = list(
      run_walker_simple = run_walker_simple,
      step_walker = step_walker,
      get_neighbors = get_neighbors,
      is_within_bounds = is_within_bounds,
      wrap_position = wrap_position
    )
  )
}

log_info("All tasks pushed, waiting for results...")

# Collect results
completed <- list()
start_time <- Sys.time()

while (length(completed) < n_walkers && difftime(Sys.time(), start_time, units = "secs") < 30) {
  result <- controller$pop()

  if (!is.null(result) && nrow(result) > 0) {
    walker <- result$result[[1]]

    if (!is.null(walker) && !is.null(walker$id)) {
      completed[[as.character(walker$id)]] <- walker
      log_info("Walker {walker$id} completed: {walker$termination_reason}, steps: {walker$steps}")

      # Update grid with terminated walker position
      if (walker$termination_reason != "hit_boundary" && walker$termination_reason != "max_steps") {
        pos_key <- paste(walker$pos, collapse = ",")
        black_pixels[[pos_key]] <- walker$pos
      }
    }
  } else {
    Sys.sleep(0.1)
  }
}

log_info("\nResults:")
log_info("Completed walkers: {length(completed)}/{n_walkers}")
log_info("Black pixels: {length(black_pixels)}")

# Cleanup
controller$terminate()
log_info("\nSimplified async test complete!")
