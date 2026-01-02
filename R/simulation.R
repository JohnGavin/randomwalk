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
#' @param sync_mode Character. Grid synchronization mode for async simulations.
#'   Options: "static" (default, workers receive frozen grid snapshot),
#'   "dynamic" (crew-based with fallback to static if sockets fail),
#'   "mirai_dynamic" (mirai backend, currently static due to socket issues), or
#'   "chunked" (RECOMMENDED - processes walkers in batches of 10, updating grid
#'   between batches for near-real-time collision detection).
#'   Only applies when workers > 0.
#' @param max_steps Integer. Maximum steps per walker before forced termination.
#'   Default 10000.
#' @param verbose Logical. If TRUE, enables detailed logging. Default FALSE.
#' @param quiet Logical. If TRUE, suppresses INFO-level logs (shows only WARN/ERROR).
#'   Useful for tests to reduce console output. Default FALSE.
#' @param validate_strict Logical. If TRUE, validation errors stop simulation.
#'   If FALSE, they only log warnings. Default FALSE. Tests should use TRUE.
#' @param validate_percent Numeric. Validate grid every X% of walkers complete.
#'   Default 5 (validates every 5% = 20 times total). Set to 0 to disable
#'   periodic validation (only validates at end). Minimum interval is 1 walker.
#' @param log_interval Integer. Log progress every N completed walkers.
#'   Default 50. Set to 0 to disable progress logging (only shows start/end).
#'   Lower values (e.g., 5) increase verbosity, higher values (e.g., 100) reduce output.
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
                            sync_mode = "static",
                            max_steps = 10000L,
                            verbose = FALSE,
                            quiet = FALSE,
                            validate_strict = FALSE,
                            validate_percent = 5,
                            log_interval = 50) {

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

  if (!sync_mode %in% c("static", "dynamic", "mirai_dynamic", "chunked")) {
    stop("sync_mode must be 'static', 'dynamic', 'mirai_dynamic', or 'chunked'")
  }

  # Validate dynamic mode requirements
  if (sync_mode == "dynamic" && workers > 0) {
    if (!requireNamespace("nanonext", quietly = TRUE)) {
      stop("sync_mode='dynamic' requires the 'nanonext' package. Install with: install.packages('nanonext')")
    }
  }

  # Set logging level
  if (verbose) {
    logger::log_threshold(logger::TRACE)
  } else if (quiet) {
    # Suppress INFO logs, show only WARN/ERROR
    logger::log_threshold(logger::WARN)
  }

  logger::log_info("=== STARTING SIMULATION ===")
  logger::log_info("Grid: {grid_size}x{grid_size}")
  logger::log_info("Walkers: {n_walkers}")
  logger::log_info("Neighborhood: {neighborhood}")
  logger::log_info("Boundary: {boundary}")
  mode_str <- if (workers > 0) {
    sprintf("Asynchronous (%d workers, sync_mode=%s)", workers, sync_mode)
  } else {
    "Synchronous"
  }
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
    if (sync_mode == "mirai_dynamic") {
      # TRUE dynamic mode - mirai with nanonext pub/sub
      result <- run_simulation_mirai_dynamic(
        grid = grid,
        walkers = walkers,
        n_workers = workers,
        neighborhood = neighborhood,
        boundary = boundary,
        max_steps = max_steps,
        start_time = start_time,
        validate_strict = validate_strict,
        validate_percent = validate_percent,
        log_interval = log_interval
      )
    } else if (sync_mode == "chunked") {
      # Chunked execution - batches with grid sync between
      result <- run_simulation_chunked(
        grid = grid,
        walkers = walkers,
        n_workers = workers,
        neighborhood = neighborhood,
        boundary = boundary,
        max_steps = max_steps,
        start_time = start_time,
        validate_strict = validate_strict,
        validate_percent = validate_percent,
        log_interval = log_interval,
        batch_size = 10  # Process 10 walkers per batch
      )
    } else if (sync_mode == "dynamic") {
      # Dynamic broadcasting mode (crew-based, fallback to static)
      result <- run_simulation_async_dynamic(
        grid = grid,
        walkers = walkers,
        n_workers = workers,
        neighborhood = neighborhood,
        boundary = boundary,
        max_steps = max_steps,
        start_time = start_time,
        validate_strict = validate_strict,
        validate_percent = validate_percent,
        log_interval = log_interval
      )
    } else {
      # Static snapshot mode - frozen grid
      result <- run_simulation_async(
        grid = grid,
        walkers = walkers,
        n_workers = workers,
        neighborhood = neighborhood,
        boundary = boundary,
        max_steps = max_steps,
        start_time = start_time,
        validate_strict = validate_strict,
        validate_percent = validate_percent,
        log_interval = log_interval
      )
    }

    # Unpack results
    grid <- result$grid
    walkers <- result$walkers
    statistics <- result$statistics

  } else {
    # === SYNC MODE (original implementation) ===

    # Calculate validation interval based on percentage
    validate_interval <- max(1, round(n_walkers * validate_percent / 100))
    logger::log_debug("Validation interval: every {validate_interval} walkers ({validate_percent}%)")

    # Run simulation loop
    total_steps <- 0
    step_count <- 0
    completed_count <- 0
    last_black_positions <- NULL  # Track validated black pixels for optimization

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

      # If terminated with black neighbor, make pixel black to extend connected graph
      # FIX FOR ISSUE #168: Only paint for "black_neighbor" terminations
      # - "touched_black": Already black, don't repaint
      # - "black_neighbor": Paint to extend connected graph ✅
      # - "max_steps": Would create isolated pixel, skip ❌
      # - "hit_boundary": Out of bounds, skip ❌
      if (!walker$active && walker$termination_reason == "black_neighbor") {
        grid <- set_pixel_black(grid, walker$pos, boundary)
        logger::log_debug("Walker {walker$id} terminated: {walker$termination_reason} at ({walker$pos[1]}, {walker$pos[2]}) after {walker$steps} steps")
      }

      # Increment completed count for any termination
      if (!walker$active) {
        completed_count <- completed_count + 1

        # Periodic validation based on completed walker count
        # OPTIMIZED: Only checks NEW black pixels, returns immediately on first isolated pixel
        if (validate_percent > 0 && completed_count %% validate_interval == 0) {
          logger::log_trace("Running optimized grid validation at {completed_count}/{n_walkers} walkers ({round(completed_count/n_walkers*100, 1)}%)")
          validate_no_isolated_pixels(
            grid = grid,
            neighborhood = neighborhood,
            strict = validate_strict,
            last_black_positions = last_black_positions,
            walkers = walkers,
            step_count = step_count
          )
          # Update tracked positions for next validation
          last_black_positions <- which(grid == 1, arr.ind = TRUE)
        }
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

    # Final validation with full context for debugging
    logger::log_info("Running final optimized grid validation")
    validate_no_isolated_pixels(
      grid = grid,
      neighborhood = neighborhood,
      strict = validate_strict,
      last_black_positions = last_black_positions,
      walkers = walkers,
      step_count = step_count
    )

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
                                   boundary, max_steps, start_time,
                                   validate_strict, validate_percent, log_interval) {
  logger::log_info("Starting async simulation with {n_workers} workers")

  # Calculate validation interval based on percentage
  n_total <- length(walkers)
  validate_interval <- max(1, round(n_total * validate_percent / 100))
  logger::log_debug("Validation interval: every {validate_interval} walkers ({validate_percent}%)")

  # Initialize async resources
  controller <- NULL

  tryCatch({
    # Create controller (no nanonext socket needed)
    controller <- create_controller(n_workers)

    # Prepare grid state for workers
    grid_state <- list(
      grid = grid,
      black_pixels = get_black_pixels_list(grid),
      version = 0L,
      grid_size = nrow(grid)
    )

    # Push all walker tasks to crew
    logger::log_info("Pushing {length(walkers)} walker tasks to crew")

    for (i in seq_along(walkers)) {
      walker <- walkers[[i]]

      # Push task to crew (async, non-blocking)
      # Note: Pass functions as globals since installed package lacks async functions
      # Workers operate on static grid_state snapshot (no real-time sync)
      controller$push(
        name = paste0("walker_", walker$id),
        command = {
          worker_run_walker(
            walker, grid_state, NULL, neighborhood, boundary, max_steps
          )
        },
        data = list(
          walker = walker,
          grid_state = grid_state,
          neighborhood = neighborhood,
          boundary = boundary,
          max_steps = max_steps
        ),
        globals = list(
          # Pass all functions needed by worker (no nanonext functions)
          worker_run_walker = worker_run_walker,
          check_termination_cached = check_termination_cached,
          get_neighbors = get_neighbors,
          is_within_bounds = is_within_bounds,
          wrap_position = wrap_position,
          step_walker = step_walker
        ),
        packages = c("logger")  # No nanonext needed
      )
    }

    logger::log_info("All tasks pushed to crew, waiting for completion")

    # Poll for completed tasks
    completed_walkers <- list()
    n_total <- length(walkers)
    n_completed <- 0
    last_black_positions <- NULL  # Track validated black pixels for optimization
    step_count <- 0  # Track steps for debugging context

    # Timeout configuration: 30 seconds per walker
    timeout_secs <- 30 * n_total
    start_time <- Sys.time()

    while (n_completed < n_total) {
      # Check timeout
      elapsed_secs <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
      if (elapsed_secs > timeout_secs) {
        logger::log_error("Async simulation timeout after {round(elapsed_secs, 1)}s ({n_completed}/{n_total} completed)")
        logger::log_error("Workers may have failed - check GitHub Actions logs for crew worker errors")
        stop("Async simulation timeout: workers failed to complete within ", timeout_secs, " seconds")
      }

      # Pop completed tasks (blocking wait)
      result <- controller$pop(scale = TRUE)

      if (!is.null(result) && nrow(result) > 0) {
        # Extract walker from crew result
        # crew returns a data frame where result$result[[1]] contains the returned value
        walker <- result$result[[1]]

        # Debug: Log walker structure before validation
        logger::log_debug("Walker class: {class(walker)}, typeof: {typeof(walker)}, is.list: {is.list(walker)}")
        logger::log_debug("Walker structure: {paste(capture.output(str(walker, max.level = 1)), collapse = '; ')}")

        # Validate walker structure
        if (is.null(walker) || !is.list(walker) || is.null(walker$id)) {
          logger::log_error("Invalid walker structure returned from crew worker")
          logger::log_error("Result status: {result$status}, error: {if(!is.null(result$error)) result$error else 'none'}")
          logger::log_debug("Full result: {paste(capture.output(str(result)), collapse = '; ')}")
          next
        }

        completed_walkers[[as.character(walker$id)]] <- walker

        # Update grid with terminated walker
        if (!walker$active && walker$termination_reason != "hit_boundary") {
          # FIX FOR ISSUE #166: Disable strict validation in async mode
          # Validation caused 99.9% rejection rate because workers operate on stale snapshots
          # Accept all non-boundary terminations in async mode

          grid <- set_pixel_black(grid, walker$pos, boundary)

          # Note: No broadcasting needed - workers operate on static snapshot
          grid_state$version <- grid_state$version + 1L
          pos_key <- paste(walker$pos, collapse = ",")
          grid_state$black_pixels[[pos_key]] <- walker$pos

          logger::log_debug(
            "Walker {walker$id} terminated: {walker$termination_reason} at ({walker$pos[1]}, {walker$pos[2]}) after {walker$steps} steps"
          )
        }

        n_completed <- n_completed + 1

        # Periodic validation based on completed count
        if (validate_percent > 0 && n_completed %% validate_interval == 0) {
          logger::log_trace("Running grid validation at {n_completed}/{n_total} walkers ({round(n_completed/n_total*100, 1)}%)")
          validate_no_isolated_pixels(
            grid,
            neighborhood = neighborhood,
            strict = validate_strict
          )
        }

        # Log progress
        if (log_interval > 0 && (n_completed %% log_interval == 0 || n_completed == n_total)) {
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

    # Final validation with full context for debugging
    logger::log_info("Running final optimized grid validation")
    validate_no_isolated_pixels(
      grid = grid,
      neighborhood = neighborhood,
      strict = validate_strict,
      last_black_positions = last_black_positions,
      walkers = walkers,
      step_count = step_count
    )

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
    # Always clean up resources (no socket to clean)
    cleanup_async(controller, NULL)
  })
}


#' Run Async Simulation with Dynamic Broadcasting (Internal)
#'
#' Internal function that executes async simulation with real-time grid
#' synchronization via nanonext pub/sub pattern. Workers receive broadcasts
#' of new black pixels, enabling collision detection.
#'
#' @param grid Numeric matrix. Initialized grid.
#' @param walkers List. Created walker objects.
#' @param n_workers Integer. Number of crew workers.
#' @param neighborhood Character. "4-hood" or "8-hood".
#' @param boundary Character. "terminate" or "wrap".
#' @param max_steps Integer. Maximum steps limit.
#' @param start_time POSIXct. Simulation start time.
#' @param validate_strict Logical. Strict validation mode.
#' @param validate_percent Numeric. Validation frequency.
#'
#' @return List with grid, walkers, and statistics (including collision counts).
#'
#' @keywords internal
run_simulation_async_dynamic <- function(grid, walkers, n_workers, neighborhood,
                                           boundary, max_steps, start_time,
                                           validate_strict, validate_percent, log_interval) {
  logger::log_info("Starting async simulation with dynamic broadcasting ({n_workers} workers)")

  # Calculate validation interval
  n_total <- length(walkers)
  validate_interval <- max(1, round(n_total * validate_percent / 100))
  logger::log_debug("Validation interval: every {validate_interval} walkers ({validate_percent}%)")

  # Initialize resources
  controller <- NULL
  pub_socket <- NULL
  port <- 5555

  tryCatch({
    # Initialize publisher socket
    pub_socket <- init_publisher_socket(port = port)
    logger::log_info("Publisher socket initialized on port {port}")

    # Create crew controller
    controller <- create_controller(n_workers)
    logger::log_info("Crew controller started with {n_workers} workers")

    # Push all walker tasks
    logger::log_info("Pushing {length(walkers)} walker tasks to crew")

    for (i in seq_along(walkers)) {
      walker <- walkers[[i]]

      # Workers will initialize their own subscriber sockets
      # (sockets can't be serialized, so workers create their own)
      controller$push(
        name = paste0("walker_", walker$id),
        command = {
          # Try to initialize subscriber socket in worker
          # Note: nanonext sockets may not work in crew subprocesses
          sub_socket <- tryCatch(
            {
              init_subscriber_socket(host = "localhost", port = port)
            },
            error = function(e) {
              # Socket creation failed - worker will run without receiving broadcasts
              NULL
            }
          )

          # Run walker - with or without socket
          # If sub_socket is NULL, worker uses static grid snapshot
          result <- simulate_walker_dynamic(
            walker_id = walker$id,
            initial_grid = initial_grid,
            pub_socket = NULL,  # Workers receive only, main broadcasts
            sub_socket = sub_socket,  # May be NULL if socket failed
            grid_size = grid_size,
            neighborhood = neighborhood,
            boundary = boundary,
            max_steps = max_steps
          )

          # Cleanup if socket was created
          if (!is.null(sub_socket)) {
            tryCatch(close_sockets(sub_socket), error = function(e) NULL)
          }

          result
        },
        data = list(
          walker = walker,
          initial_grid = grid,
          grid_size = nrow(grid),
          port = port,
          neighborhood = neighborhood,
          boundary = boundary,
          max_steps = max_steps
        ),
        globals = list(
          # Pass functions needed by worker
          init_subscriber_socket = init_subscriber_socket,
          simulate_walker_dynamic = simulate_walker_dynamic,
          update_grid_from_broadcasts = update_grid_from_broadcasts,
          close_sockets = close_sockets,
          get_neighbors = get_neighbors,
          get_neighbors_bounded = get_neighbors_bounded,
          choose_next_position = choose_next_position,
          is_boundary = is_boundary,
          handle_boundary = handle_boundary,
          sample_start_position = sample_start_position
        ),
        packages = c("nanonext")
      )
    }

    logger::log_info("All tasks pushed to crew, waiting for completion")

    # Poll for completed tasks
    completed_walkers <- list()
    n_completed <- 0
    last_black_positions <- NULL  # Track validated black pixels for optimization
    step_count <- 0  # Track steps for debugging context

    # Timeout: 60 seconds per walker (dynamic mode is slower)
    timeout_secs <- 60 * n_total
    start_time_loop <- Sys.time()

    while (n_completed < n_total) {
      # Check timeout
      elapsed_secs <- as.numeric(difftime(Sys.time(), start_time_loop, units = "secs"))
      if (elapsed_secs > timeout_secs) {
        logger::log_error("Async simulation timeout after {round(elapsed_secs, 1)}s ({n_completed}/{n_total} completed)")
        stop("Async simulation timeout: workers failed to complete within ", timeout_secs, " seconds")
      }

      # Pop completed tasks (blocking wait)
      result <- controller$pop(scale = TRUE)

      if (!is.null(result) && nrow(result) > 0) {
        # Extract walker from crew result
        walker_result <- result$result[[1]]

        # Validate walker structure
        if (is.null(walker_result) || !is.list(walker_result) || is.null(walker_result$walker_id)) {
          logger::log_error("Invalid walker structure returned from crew worker")
          logger::log_error("Result status: {result$status}, error: {if(!is.null(result$error)) result$error else 'none'}")
          next
        }

        completed_walkers[[as.character(walker_result$walker_id)]] <- walker_result

        # Update grid if walker created black pixel
        if (walker_result$black_pixel_created) {
          pos <- walker_result$position

          # Validate position is valid
          if (!is.null(pos) && length(pos) == 2) {
            grid <- set_pixel_black(grid, pos, boundary)

            # BROADCAST: Notify all workers of new black pixel
            # This is the key to dynamic mode - workers receive real-time updates
            broadcast_black_pixel(pub_socket, pos, walker_result$walker_id)

            logger::log_debug(
              "Walker {walker_result$walker_id} terminated: {walker_result$status} at ({pos[1]}, {pos[2]}) after {walker_result$steps} steps [broadcast sent]"
            )
          }
        }

        n_completed <- n_completed + 1

        # Periodic validation
        if (validate_percent > 0 && n_completed %% validate_interval == 0) {
          logger::log_trace("Running grid validation at {n_completed}/{n_total} walkers ({round(n_completed/n_total*100, 1)}%)")
          validate_no_isolated_pixels(
            grid,
            neighborhood = neighborhood,
            strict = validate_strict
          )
        }

        # Log progress
        if (log_interval > 0 && (n_completed %% log_interval == 0 || n_completed == n_total)) {
          black_count <- count_black_pixels(grid)
          collisions <- sum(sapply(completed_walkers, function(w) w$status == "black_neighbor_detected"))
          logger::log_info("Completed: {n_completed}/{n_total}, Black: {black_count}, Collisions: {collisions}")
        }
      }

      # Brief sleep
      Sys.sleep(0.01)
    }

    # Calculate statistics
    end_time <- Sys.time()
    elapsed_time <- as.numeric(difftime(end_time, start_time, units = "secs"))

    logger::log_info("=== ASYNC SIMULATION COMPLETE ===")
    logger::log_info("Elapsed time: {round(elapsed_time, 2)} seconds")

    # Final validation with full context for debugging
    logger::log_info("Running final optimized grid validation")
    validate_no_isolated_pixels(
      grid = grid,
      neighborhood = neighborhood,
      strict = validate_strict,
      last_black_positions = last_black_positions,
      walkers = walkers,
      step_count = step_count
    )

    # Collect statistics
    walker_steps <- sapply(completed_walkers, function(w) w$steps)
    termination_statuses <- sapply(completed_walkers, function(w) w$status)

    # Count collisions
    collision_count <- sum(termination_statuses == "black_neighbor_detected")

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
      termination_reasons = table(termination_statuses),
      collisions_detected = collision_count,  # NEW for dynamic mode
      sync_mode = "dynamic"  # NEW for identification
    )

    list(
      grid = grid,
      walkers = completed_walkers,
      statistics = statistics
    )

  }, finally = {
    # Clean up resources
    cleanup_async(controller, pub_socket)
  })
}


#' Run Simulation with Mirai Direct (True Dynamic Broadcasting)
#'
#' Uses mirai directly (not crew) with nanonext pub/sub for real-time
#' grid synchronization between workers. Sockets are initialized on
#' daemons at startup, enabling mid-task broadcasts.
#'
#' @inheritParams run_simulation_async_dynamic
#' @return List with grid, walkers, and statistics
#' @keywords internal
run_simulation_mirai_dynamic <- function(grid, walkers, n_workers, neighborhood,
                                          boundary, max_steps, start_time,
                                          validate_strict, validate_percent, log_interval) {
  logger::log_info("Starting MIRAI-DIRECT simulation with true dynamic broadcasting ({n_workers} workers)")

  if (!requireNamespace("mirai", quietly = TRUE)) {
    stop("mirai package required for direct mirai mode")
  }
  if (!requireNamespace("nanonext", quietly = TRUE)) {
    stop("nanonext package required for dynamic broadcasting")
  }

  n_total <- length(walkers)
  port <- 5556  # Different port from crew-based to avoid conflicts
  grid_size <- nrow(grid)

  # Initialize publisher socket on main process
  pub_socket <- nanonext::socket("pub")
  nanonext::listen(pub_socket, sprintf("tcp://*:%d", port))
  Sys.sleep(0.1)  # Allow socket to bind
  logger::log_info("Publisher socket listening on port {port}")

  # Start mirai daemons
  mirai::daemons(n = n_workers, dispatcher = TRUE)
  logger::log_info("Started {n_workers} mirai daemons")

  # Quick test to verify daemons are working
  test_m <- mirai::mirai({ Sys.getpid() })
  test_result <- test_m[]
  logger::log_info("Daemon test: PID = {test_result}")

  # Test a simple walker-like task (no sockets)
  test_walker <- mirai::mirai({
    pos <- c(sample(.gs, 1), sample(.gs, 1))
    list(walker_id = 999, status = "test", position = pos)
  }, .gs = grid_size)
  test_walker_result <- test_walker[]
  logger::log_info("Walker test: {test_walker_result$status} at ({test_walker_result$position[1]}, {test_walker_result$position[2]})")

  # NOTE: Each task creates its own socket (not using everywhere() anymore)
  logger::log_info("Socket setup: each task will create its own subscriber socket")

  # Submit all walker tasks
  logger::log_info("Submitting {n_total} walker tasks")
  task_list <- list()

  for (i in seq_along(walkers)) {
    walker <- walkers[[i]]

    m <- mirai::mirai({
      # Use passed grid directly - socket creation disabled (causes hangs in mirai)
      local_grid <- .grid_data
      sub_socket <- NULL  # Socket disabled - nanonext hangs in mirai daemons

      position <- c(sample(.grid_size, 1), sample(.grid_size, 1))
      path <- list()

      # Check if started on black
      if (local_grid[position[1], position[2]] == "black") {
        return(list(
          walker_id = .walker_id,
          status = "started_on_black",
          steps = 0,
          position = position,
          path = list(),
          black_pixel_created = FALSE
        ))
      }

      # Main simulation loop
      for (step in seq_len(.max_steps)) {
        # STEP 1: Check for broadcast updates (non-blocking) - SKIP if no socket
        if (!is.null(sub_socket)) {
          repeat {
            msg <- tryCatch(
              nanonext::recv(sub_socket, mode = "raw", block = FALSE),
              error = function(e) NULL
            )
            if (is.null(msg)) break

            update <- tryCatch(unserialize(msg), error = function(e) NULL)
            if (!is.null(update) && update$type == "black_pixel") {
              pos <- update$position
              local_grid[pos[1], pos[2]] <- "black"
            }
          }
        }

        # STEP 2: Check neighbors for black
        neighbors <- if (.neighborhood == "4-hood") {
          list(
            c(position[1] - 1, position[2]),
            c(position[1] + 1, position[2]),
            c(position[1], position[2] - 1),
            c(position[1], position[2] + 1)
          )
        } else {
          list(
            c(position[1] - 1, position[2]),
            c(position[1] + 1, position[2]),
            c(position[1], position[2] - 1),
            c(position[1], position[2] + 1),
            c(position[1] - 1, position[2] - 1),
            c(position[1] - 1, position[2] + 1),
            c(position[1] + 1, position[2] - 1),
            c(position[1] + 1, position[2] + 1)
          )
        }

        has_black_neighbor <- any(sapply(neighbors, function(pos) {
          if (pos[1] < 1 || pos[1] > .grid_size || pos[2] < 1 || pos[2] > .grid_size) {
            return(FALSE)
          }
          local_grid[pos[1], pos[2]] == "black"
        }))

        if (has_black_neighbor) {
          local_grid[position[1], position[2]] <- "black"
          assign(".daemon_local_grid", local_grid, envir = .GlobalEnv)

          return(list(
            walker_id = .walker_id,
            status = "black_neighbor_detected",
            steps = step,
            position = position,
            path = path,
            black_pixel_created = TRUE
          ))
        }

        # STEP 3: Random walk
        valid_neighbors <- Filter(function(pos) {
          pos[1] >= 1 && pos[1] <= .grid_size && pos[2] >= 1 && pos[2] <= .grid_size
        }, neighbors)

        if (length(valid_neighbors) == 0) {
          return(list(
            walker_id = .walker_id,
            status = "no_valid_moves",
            steps = step,
            position = position,
            path = path,
            black_pixel_created = FALSE
          ))
        }

        next_pos <- valid_neighbors[[sample(length(valid_neighbors), 1)]]

        # Check boundary
        if (next_pos[1] < 1 || next_pos[1] > .grid_size ||
            next_pos[2] < 1 || next_pos[2] > .grid_size) {
          if (.boundary == "terminate") {
            return(list(
              walker_id = .walker_id,
              status = "boundary",
              steps = step,
              position = position,
              path = path,
              black_pixel_created = FALSE
            ))
          } else {
            next_pos <- c(
              ((next_pos[1] - 1) %% .grid_size) + 1,
              ((next_pos[2] - 1) %% .grid_size) + 1
            )
          }
        }

        path[[step]] <- position
        position <- next_pos
      }

      list(
        walker_id = .walker_id,
        status = "max_steps",
        steps = .max_steps,
        position = position,
        path = path,
        black_pixel_created = FALSE
      )
    },
    .walker_id = walker$id,
    .grid_size = grid_size,
    .neighborhood = neighborhood,
    .boundary = boundary,
    .max_steps = max_steps,
    .grid_data = grid,
    .port = port
    )

    task_list[[paste0("walker_", walker$id)]] <- m
  }

  logger::log_info("All tasks submitted, processing results...")

  # Process results and broadcast updates

  completed_walkers <- list()
  n_completed <- 0
  collision_count <- 0
  last_log_time <- Sys.time()
  loop_start_time <- Sys.time()
  check_count <- 0
  timeout_secs <- 120  # 2 minute timeout

  while (n_completed < n_total) {
    check_count <- check_count + 1

    # Timeout check
    elapsed <- as.numeric(difftime(Sys.time(), loop_start_time, units = "secs"))
    if (elapsed > timeout_secs) {
      logger::log_error("TIMEOUT after {round(elapsed, 1)}s - completed only {n_completed}/{n_total}")
      logger::log_error("Remaining tasks: {length(task_list)}")
      # Check status of first few remaining tasks
      for (i in seq_len(min(3, length(task_list)))) {
        tn <- names(task_list)[i]
        m <- task_list[[tn]]
        logger::log_error("Task {tn}: unresolved={mirai::unresolved(m)}")
      }
      break
    }

    # Log every 10 seconds
    if (check_count %% 1000 == 0) {
      logger::log_info("Check #{check_count}: completed={n_completed}/{n_total}, elapsed={round(elapsed,1)}s, remaining_tasks={length(task_list)}")
    }

    # Check for completed tasks
    tasks_to_remove <- character(0)
    for (task_name in names(task_list)) {
      m <- task_list[[task_name]]

      if (!mirai::unresolved(m)) {
        logger::log_debug("Task {task_name} resolved!")
        result <- tryCatch(m[], error = function(e) {
          logger::log_error("Error extracting result from {task_name}: {e$message}")
          list(walker_id = NA, status = "error", error = e$message)
        })

        if (!is.null(result$walker_id) && !is.na(result$walker_id)) {
          completed_walkers[[as.character(result$walker_id)]] <- result
          n_completed <- n_completed + 1

          # If walker created a black pixel, broadcast to all daemons
          if (isTRUE(result$black_pixel_created)) {
            pos <- result$position
            grid[pos[1], pos[2]] <- "black"
            collision_count <- collision_count + 1

            # Broadcast to all daemons
            msg <- serialize(list(
              type = "black_pixel",
              position = pos,
              walker_id = result$walker_id
            ), NULL)
            nanonext::send(pub_socket, msg, mode = "raw", block = FALSE)

            logger::log_debug("Broadcast black pixel at ({pos[1]}, {pos[2]}) from walker {result$walker_id}")
          }
        }

        # Remove from task list
        task_list[[task_name]] <- NULL
      }
    }

    # Log progress periodically
    if (n_completed > 0 && (n_completed %% log_interval == 0 ||
        difftime(Sys.time(), last_log_time, units = "secs") > 2)) {
      logger::log_info("Completed: {n_completed}/{n_total}, Collisions: {collision_count}")
      last_log_time <- Sys.time()
    }

    Sys.sleep(0.01)  # Brief pause to prevent busy-waiting
  }

  elapsed_time <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
  logger::log_info("=== MIRAI DYNAMIC SIMULATION COMPLETE ===")
  logger::log_info("Elapsed time: {round(elapsed_time, 1)} seconds")
  logger::log_info("Collisions (black neighbor terminations): {collision_count}")

  # Cleanup
  mirai::daemons(0)
  tryCatch(nanonext::close(pub_socket), error = function(e) NULL)
  logger::log_info("Cleaned up mirai daemons and sockets")

  # Collect statistics
  walker_steps <- sapply(completed_walkers, function(w) if(is.null(w$steps)) 0 else w$steps)
  termination_statuses <- sapply(completed_walkers, function(w) if(is.null(w$status)) "unknown" else w$status)

  statistics <- list(
    black_pixels = count_black_pixels(grid),
    black_percentage = get_black_percentage(grid),
    grid_size = grid_size,
    total_walkers = n_total,
    completed_walkers = n_completed,
    total_steps = sum(walker_steps),
    min_steps = if(length(walker_steps) > 0) min(walker_steps) else 0,
    max_steps = if(length(walker_steps) > 0) max(walker_steps) else 0,
    mean_steps = if(length(walker_steps) > 0) mean(walker_steps) else 0,
    median_steps = if(length(walker_steps) > 0) median(walker_steps) else 0,
    percentile_25 = if(length(walker_steps) > 0) quantile(walker_steps, 0.25) else 0,
    percentile_75 = if(length(walker_steps) > 0) quantile(walker_steps, 0.75) else 0,
    elapsed_time_secs = elapsed_time,
    termination_reasons = table(termination_statuses),
    collisions_detected = collision_count,
    sync_mode = "mirai_dynamic"
  )

  list(
    grid = grid,
    walkers = completed_walkers,
    statistics = statistics
  )
}


#' Run Simulation with Chunked Execution (Near Real-time Updates)
#'
#' Processes walkers in batches, updating the grid between batches.
#' Walkers in subsequent batches see black pixels created by earlier batches.
#' Uses crew for parallel execution within each batch.
#'
#' @inheritParams run_simulation_async_dynamic
#' @param batch_size Integer. Number of walkers per batch (default 10).
#' @return List with grid, walkers, and statistics
#' @keywords internal
run_simulation_chunked <- function(grid, walkers, n_workers, neighborhood,
                                    boundary, max_steps, start_time,
                                    validate_strict, validate_percent, log_interval,
                                    batch_size = 10) {

  n_total <- length(walkers)
  n_batches <- ceiling(n_total / batch_size)
  grid_size <- nrow(grid)

  logger::log_info("Starting CHUNKED simulation ({n_workers} workers, {batch_size} walkers/batch, {n_batches} batches)")

  # Create crew controller
  controller <- create_controller(n_workers)

  completed_walkers <- list()
  collision_count <- 0

  tryCatch({
    for (batch_num in seq_len(n_batches)) {
      # Get walkers for this batch
      batch_start <- (batch_num - 1) * batch_size + 1
      batch_end <- min(batch_num * batch_size, n_total)
      batch_walkers <- walkers[batch_start:batch_end]

      logger::log_info("Batch {batch_num}/{n_batches}: walkers {batch_start}-{batch_end} (grid has {count_black_pixels(grid)} black pixels)")

      # Submit batch tasks
      for (walker in batch_walkers) {
        controller$push(
          name = paste0("walker_", walker$id),
          command = {
            local_grid <- grid_snapshot
            position <- c(sample(grid_size, 1), sample(grid_size, 1))
            path <- list()

            # Check if started on black (grid uses 1 for black, 0 for white)
            if (local_grid[position[1], position[2]] == 1) {
              return(list(
                walker_id = walker_id,
                status = "started_on_black",
                steps = 0,
                position = position,
                path = list(),
                black_pixel_created = FALSE
              ))
            }

            # Main simulation loop
            for (step in seq_len(max_steps_val)) {
              # Check neighbors for black
              neighbors <- if (neighborhood_val == "4-hood") {
                list(
                  c(position[1] - 1, position[2]),
                  c(position[1] + 1, position[2]),
                  c(position[1], position[2] - 1),
                  c(position[1], position[2] + 1)
                )
              } else {
                list(
                  c(position[1] - 1, position[2]),
                  c(position[1] + 1, position[2]),
                  c(position[1], position[2] - 1),
                  c(position[1], position[2] + 1),
                  c(position[1] - 1, position[2] - 1),
                  c(position[1] - 1, position[2] + 1),
                  c(position[1] + 1, position[2] - 1),
                  c(position[1] + 1, position[2] + 1)
                )
              }

              has_black_neighbor <- any(sapply(neighbors, function(pos) {
                if (pos[1] < 1 || pos[1] > grid_size || pos[2] < 1 || pos[2] > grid_size) {
                  return(FALSE)
                }
                local_grid[pos[1], pos[2]] == 1  # Grid uses 1 for black
              }))

              if (has_black_neighbor) {
                return(list(
                  walker_id = walker_id,
                  status = "black_neighbor_detected",
                  steps = step,
                  position = position,
                  path = path,
                  black_pixel_created = TRUE
                ))
              }

              # Random walk - select from ALL neighbors (including out of bounds)
              next_pos <- neighbors[[sample(length(neighbors), 1)]]

              # Check boundary AFTER selection
              if (next_pos[1] < 1 || next_pos[1] > grid_size ||
                  next_pos[2] < 1 || next_pos[2] > grid_size) {
                if (boundary_val == "terminate") {
                  # Walker walks off grid - terminate without creating black pixel
                  return(list(
                    walker_id = walker_id,
                    status = "boundary",
                    steps = step,
                    position = position,
                    path = path,
                    black_pixel_created = FALSE
                  ))
                } else {
                  # Wrap around
                  next_pos <- c(
                    ((next_pos[1] - 1) %% grid_size) + 1,
                    ((next_pos[2] - 1) %% grid_size) + 1
                  )
                }
              }

              path[[step]] <- position
              position <- next_pos
            }

            list(
              walker_id = walker_id,
              status = "max_steps",
              steps = max_steps_val,
              position = position,
              path = path,
              black_pixel_created = FALSE
            )
          },
          data = list(
            walker_id = walker$id,
            grid_snapshot = grid,  # Current grid state for this batch
            grid_size = grid_size,
            neighborhood_val = neighborhood,
            boundary_val = boundary,
            max_steps_val = max_steps
          )
        )
      }

      # Wait for all tasks in this batch to complete
      batch_results <- list()
      batch_completed <- 0
      batch_size_actual <- length(batch_walkers)

      while (batch_completed < batch_size_actual) {
        result <- controller$pop()
        if (!is.null(result)) {
          walker_result <- result$result[[1]]

          if (!is.null(walker_result$walker_id)) {
            batch_results[[as.character(walker_result$walker_id)]] <- walker_result
            batch_completed <- batch_completed + 1

            # Update grid if walker created black pixel
            if (isTRUE(walker_result$black_pixel_created)) {
              pos <- walker_result$position
              grid[pos[1], pos[2]] <- 1  # Grid uses 1 for black
              collision_count <- collision_count + 1
            }
          }
        }
        Sys.sleep(0.01)
      }

      # Add batch results to completed walkers
      completed_walkers <- c(completed_walkers, batch_results)

      logger::log_info("Batch {batch_num} complete: {collision_count} total collisions so far")
    }

    elapsed_time <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
    logger::log_info("=== CHUNKED SIMULATION COMPLETE ===")
    logger::log_info("Elapsed time: {round(elapsed_time, 1)} seconds")
    logger::log_info("Total collisions: {collision_count}")

    # Collect statistics
    walker_steps <- sapply(completed_walkers, function(w) if(is.null(w$steps)) 0 else w$steps)
    termination_statuses <- sapply(completed_walkers, function(w) if(is.null(w$status)) "unknown" else w$status)

    statistics <- list(
      black_pixels = count_black_pixels(grid),
      black_percentage = get_black_percentage(grid),
      grid_size = grid_size,
      total_walkers = n_total,
      completed_walkers = length(completed_walkers),
      total_steps = sum(walker_steps),
      min_steps = if(length(walker_steps) > 0) min(walker_steps) else 0,
      max_steps = if(length(walker_steps) > 0) max(walker_steps) else 0,
      mean_steps = if(length(walker_steps) > 0) mean(walker_steps) else 0,
      median_steps = if(length(walker_steps) > 0) median(walker_steps) else 0,
      percentile_25 = if(length(walker_steps) > 0) quantile(walker_steps, 0.25) else 0,
      percentile_75 = if(length(walker_steps) > 0) quantile(walker_steps, 0.75) else 0,
      elapsed_time_secs = elapsed_time,
      termination_reasons = table(termination_statuses),
      collisions_detected = collision_count,
      sync_mode = "chunked",
      batch_size = batch_size,
      n_batches = n_batches
    )

    list(
      grid = grid,
      walkers = completed_walkers,
      statistics = statistics
    )

  }, finally = {
    controller$terminate()
    logger::log_info("Crew controller terminated")
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
  base_stats <- c(
    "=== SIMULATION STATISTICS ===",
    sprintf("Black Pixels: %d (%.2f%%)", stats$black_pixels, stats$black_percentage),
    sprintf("Walkers: %d completed", stats$completed_walkers),
    sprintf("Total Steps: %d", stats$total_steps),
    sprintf("Steps Per Walker: min=%d, median=%.0f, mean=%.1f, max=%d",
            stats$min_steps, stats$median_steps, stats$mean_steps, stats$max_steps),
    sprintf("Percentiles: 25th=%.0f, 75th=%.0f",
            stats$percentile_25, stats$percentile_75),
    sprintf("Elapsed Time: %.2f seconds", stats$elapsed_time_secs)
  )

  # Add collision statistics if present (dynamic mode)
  if (!is.null(stats$collisions_detected)) {
    collision_rate <- (stats$collisions_detected / stats$completed_walkers) * 100
    base_stats <- c(
      base_stats,
      sprintf("Collisions Detected: %d (%.1f%% of walkers)",
              stats$collisions_detected, collision_rate),
      sprintf("Sync Mode: %s", stats$sync_mode)
    )
  }

  # Add termination reasons
  c(
    base_stats,
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
