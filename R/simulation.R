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
#'   Note: Async implementation not yet available in this version.
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
  logger::log_info("Mode: Synchronous")

  start_time <- Sys.time()

  # Initialize grid
  grid <- initialize_grid(grid_size)

  # Create walkers
  walker_positions <- generate_walker_positions(n_walkers, grid)
  walkers <- lapply(seq_along(walker_positions), function(i) {
    create_walker(i, walker_positions[[i]], grid_size)
  })

  logger::log_info("Created {n_walkers} walkers")

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
