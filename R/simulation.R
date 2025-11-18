#' Run a Random Walk Simulation
#'
#' Executes a complete random walk simulation with the specified parameters.
#' This is the main entry point for running simulations programmatically.
#'
#' @param grid_size Integer. Size of the grid (n x n). Default 10.
#' @param n_walkers Integer. Number of simultaneous walkers. Default 5.
#'   Must be between 1 and 60% of grid size.
#' @param neighborhood Character. Either "4-hood" or "8-hood". Default "4-hood".
#' @param boundary Character. Either "terminate" or "wrap". Default "terminate".
#' @param workers Integer. Number of parallel workers (0 = synchronous). Default 0.
#'   For async mode, use 2-4 workers for medium grids, 4-8 for large grids.
#'   Requires crew and nanonext packages.
#' @param max_steps Integer. Maximum steps per walker before forced termination.
#'   Default 10000.
#' @param verbose Logical. If TRUE, enables detailed logging. Default FALSE.
#'
#' @return A list with components:
#'   \describe{
#'     \item{grid}{Final grid state}
#'     \item{walkers}{List of final walker states}
#'     \item{statistics}{Simulation statistics}
#'     \item{parameters}{Input parameters}
#'   }
#'
#' @examples
#' \dontrun{
#' result <- run_simulation(grid_size = 20, n_walkers = 8)
#' plot_grid(result$grid)
#' print(result$statistics)
#' }
#'
#' @export
run_simulation <- function(grid_size = 10,
                            n_walkers = 5,
                            neighborhood = "4-hood",
                            boundary = "terminate",
                            workers = 0,
                            max_steps = 10000L,
                            verbose = FALSE) {

  # Input validation
  if (grid_size < 3) {
    stop("grid_size must be >= 3")
  }

  max_walkers <- floor(grid_size * grid_size * 0.6)
  if (n_walkers < 1 || n_walkers > max_walkers) {
    stop(sprintf("n_walkers must be between 1 and %d (60%% of grid)", max_walkers))
  }

  if (!neighborhood %in% c("4-hood", "8-hood")) {
    stop("neighborhood must be '4-hood' or '8-hood'")
  }

  if (!boundary %in% c("terminate", "wrap")) {
    stop("boundary must be 'terminate' or 'wrap'")
  }

  # Set logging level
  if (verbose) {
    logger::log_threshold(logger::TRACE)
  }

  logger::log_info("=== STARTING SIMULATION ===")
  logger::log_info("Grid: {grid_size}x{grid_size}")
  logger::log_info("Walkers: {n_walkers}")
  logger::log_info("Neighborhood: {neighborhood}")
  logger::log_info("Boundary: {boundary}")
  mode_str <- if (workers > 0) sprintf("Asynchronous (%d workers)", workers) else "Synchronous"
  logger::log_info("Mode: {mode_str}")

  start_time <- Sys.time()

  # Initialize grid
  grid <- initialize_grid(grid_size)

  # Create walkers
  walker_positions <- generate_walker_positions(n_walkers, grid)
  walkers <- lapply(seq_along(walker_positions), function(i) {
    create_walker(i, walker_positions[[i]], grid_size)
  })

  logger::log_info("Created {n_walkers} walkers")

  # Choose async or sync mode
  if (workers > 0) {
    # === ASYNC MODE ===
    result <- run_simulation_async(
      grid = grid,
      walkers = walkers,
      n_workers = workers,
      neighborhood = neighborhood,
      boundary = boundary,
      max_steps = max_steps,
      start_time = start_time
    )

    # Unpack results
    grid <- result$grid
    walkers <- result$walkers
    statistics <- result$statistics

  } else {
    # === SYNC MODE (original implementation) ===

    # Run simulation loop
    total_steps <- 0
    step_count <- 0

    while (any(sapply(walkers, function(w) w$active))) {
    step_count <- step_count + 1

    for (i in seq_along(walkers)) {
      walker <- walkers[[i]]

      if (!walker$active) {
        next
      }

      # Move walker
      walker <- step_walker(walker, neighborhood, boundary)

      # Check termination conditions
      walker <- check_termination(walker, grid, neighborhood, boundary, max_steps)

      # If terminated, make pixel black
      if (!walker$active && walker$termination_reason != "hit_boundary") {
        grid <- set_pixel_black(grid, walker$pos, boundary)
        logger::log_debug("Walker {walker$id} terminated: {walker$termination_reason} at ({walker$pos[1]}, {walker$pos[2]}) after {walker$steps} steps")
      }

      walkers[[i]] <- walker
    }

    total_steps <- total_steps + sum(sapply(walkers, function(w) w$active))

    # Log progress periodically
    if (step_count %% 100 == 0) {
      active_count <- sum(sapply(walkers, function(w) w$active))
      black_count <- count_black_pixels(grid)
      logger::log_info("Step {step_count}: Active={active_count}, Black={black_count}")
    }
  }

    end_time <- Sys.time()
    elapsed_time <- as.numeric(difftime(end_time, start_time, units = "secs"))

    logger::log_info("=== SIMULATION COMPLETE ===")
    logger::log_info("Total steps: {total_steps}")
    logger::log_info("Elapsed time: {round(elapsed_time, 2)} seconds")

    # Collect statistics
    walker_steps <- sapply(walkers, function(w) w$steps)

    statistics <- list(
      black_pixels = count_black_pixels(grid),
      black_percentage = get_black_percentage(grid),
      grid_size = grid_size,
      total_walkers = n_walkers,
      completed_walkers = sum(!sapply(walkers, function(w) w$active)),
      total_steps = sum(walker_steps),
      min_steps = min(walker_steps),
      max_steps = max(walker_steps),
      mean_steps = mean(walker_steps),
      median_steps = median(walker_steps),
      percentile_25 = quantile(walker_steps, 0.25),
      percentile_75 = quantile(walker_steps, 0.75),
      elapsed_time_secs = elapsed_time,
      termination_reasons = table(sapply(walkers, function(w) w$termination_reason))
    )
  }  # End of if/else (async vs sync)

  list(
    grid = grid,
    walkers = walkers,
    statistics = statistics,
    parameters = list(
      grid_size = grid_size,
      n_walkers = n_walkers,
      neighborhood = neighborhood,
      boundary = boundary,
      workers = workers,
      max_steps = max_steps
    )
  )
}


#' Run Async Simulation (Internal)
#'
#' Internal function that executes the async simulation using crew workers.
#' Called by run_simulation() when workers > 0.
#'
#' @param grid Numeric matrix. Initialized grid.
#' @param walkers List. Created walker objects.
#' @param n_workers Integer. Number of crew workers.
#' @param neighborhood Character. "4-hood" or "8-hood".
#' @param boundary Character. "terminate" or "wrap".
#' @param max_steps Integer. Maximum steps limit.
#' @param start_time POSIXct. Simulation start time.
#'
#' @return List with grid, walkers, and statistics.
#'
#' @keywords internal
run_simulation_async <- function(grid, walkers, n_workers, neighborhood,
                                   boundary, max_steps, start_time) {
  logger::log_info("Starting async simulation with {n_workers} workers")

  # Initialize async resources
  controller <- NULL
  pub_socket <- NULL

  tryCatch({
    # Create controller and publisher socket
    controller <- create_controller(n_workers)
    pub_socket <- create_pub_socket(port = 5555)

    # Prepare grid state for workers
    grid_state <- list(
      grid = grid,
      black_pixels = get_black_pixels_list(grid),
      version = 0L,
      grid_size = nrow(grid)
    )

    # Publisher address for workers
    pub_address <- "tcp://127.0.0.1:5555"

    # Push all walker tasks to crew
    logger::log_info("Pushing {length(walkers)} walker tasks to crew")

    for (i in seq_along(walkers)) {
      walker <- walkers[[i]]

      # Push task to crew (async, non-blocking)
      controller$push(
        command = worker_run_walker(
          walker = walker,
          grid_state = grid_state,
          pub_address = pub_address,
          neighborhood = neighborhood,
          boundary = boundary,
          max_steps = max_steps
        ),
        data = list(
          walker = walker,
          grid_state = grid_state,
          pub_address = pub_address,
          neighborhood = neighborhood,
          boundary = boundary,
          max_steps = max_steps
        )
      )
    }

    logger::log_info("All tasks pushed to crew, waiting for completion")

    # Poll for completed tasks
    completed_walkers <- list()
    n_total <- length(walkers)
    n_completed <- 0

    while (n_completed < n_total) {
      # Pop completed tasks (blocking wait)
      result <- controller$pop(scale = TRUE)

      if (!is.null(result) && !is.null(result$result)) {
        walker <- result$result  # crew returns the walker directly
        completed_walkers[[walker$id]] <- walker

        # Update grid with terminated walker
        if (!walker$active && walker$termination_reason != "hit_boundary") {
          grid <- set_pixel_black(grid, walker$pos, boundary)

          # Broadcast update to workers
          grid_state$version <- grid_state$version + 1L
          pos_key <- paste(walker$pos, collapse = ",")
          grid_state$black_pixels[[pos_key]] <- walker$pos

          broadcast_update(pub_socket, walker$pos, grid_state$version)

          logger::log_debug(
            "Walker {walker$id} terminated: {walker$termination_reason} at ({walker$pos[1]}, {walker$pos[2]}) after {walker$steps} steps"
          )
        }

        n_completed <- n_completed + 1

        # Log progress
        if (n_completed %% 5 == 0 || n_completed == n_total) {
          black_count <- count_black_pixels(grid)
          logger::log_info("Completed: {n_completed}/{n_total}, Black pixels: {black_count}")
        }
      }

      # Brief sleep to avoid tight loop
      Sys.sleep(0.01)
    }

    # Calculate statistics
    end_time <- Sys.time()
    elapsed_time <- as.numeric(difftime(end_time, start_time, units = "secs"))

    logger::log_info("=== ASYNC SIMULATION COMPLETE ===")
    logger::log_info("Elapsed time: {round(elapsed_time, 2)} seconds")

    # Collect statistics
    walker_steps <- sapply(completed_walkers, function(w) w$steps)

    statistics <- list(
      black_pixels = count_black_pixels(grid),
      black_percentage = get_black_percentage(grid),
      grid_size = nrow(grid),
      total_walkers = n_total,
      completed_walkers = n_completed,
      total_steps = sum(walker_steps),
      min_steps = min(walker_steps),
      max_steps = max(walker_steps),
      mean_steps = mean(walker_steps),
      median_steps = median(walker_steps),
      percentile_25 = quantile(walker_steps, 0.25),
      percentile_75 = quantile(walker_steps, 0.75),
      elapsed_time_secs = elapsed_time,
      termination_reasons = table(sapply(completed_walkers, function(w) w$termination_reason))
    )

    list(
      grid = grid,
      walkers = completed_walkers,
      statistics = statistics
    )

  }, finally = {
    # Always clean up resources
    cleanup_async(controller, pub_socket)
  })
}


#' Get Black Pixels as Named List
#'
#' Converts grid matrix to a named list of black pixel positions.
#' Used for initializing worker caches in async mode.
#'
#' @param grid Numeric matrix. The simulation grid.
#'
#' @return Named list where keys are "row,col" and values are c(row, col).
#'
#' @keywords internal
get_black_pixels_list <- function(grid) {
  black_list <- list()

  for (i in seq_len(nrow(grid))) {
    for (j in seq_len(ncol(grid))) {
      if (grid[i, j] == 1) {
        pos <- c(i, j)
        key <- paste(pos, collapse = ",")
        black_list[[key]] <- pos
      }
    }
  }

  black_list
}


#' Format Simulation Statistics for Display
#'
#' Formats simulation statistics into a readable character vector.
#'
#' @param stats List. Statistics from run_simulation().
#'
#' @return Character vector with formatted statistics.
#'
#' @export
format_statistics <- function(stats) {
  c(
    "=== SIMULATION STATISTICS ===",
    sprintf("Black Pixels: %d (%.2f%%)", stats$black_pixels, stats$black_percentage),
    sprintf("Walkers: %d completed", stats$completed_walkers),
    sprintf("Total Steps: %d", stats$total_steps),
    sprintf("Steps Per Walker: min=%d, median=%.0f, mean=%.1f, max=%d",
            stats$min_steps, stats$median_steps, stats$mean_steps, stats$max_steps),
    sprintf("Percentiles: 25th=%.0f, 75th=%.0f",
            stats$percentile_25, stats$percentile_75),
    sprintf("Elapsed Time: %.2f seconds", stats$elapsed_time_secs),
    "Termination Reasons:",
    paste(names(stats$termination_reasons), stats$termination_reasons, sep = ": ", collapse = "\n")
  )
}

#' Print Simulation Result
#'
#' @param result List. Result from run_simulation().
#'
#' @export
print_simulation_result <- function(result) {
  cat(format_statistics(result$statistics), sep = "\n")
}
