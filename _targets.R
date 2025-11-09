# _targets.R for randomwalk package telemetry
# This file defines the targets pipeline for pre-computing all vignette objects
# Following context.md Section 4: Targets Package

library(targets)
library(tarchetypes)

# Set target options
tar_option_set(
  packages = c(
    "randomwalk",
    "dplyr",
    "ggplot2",
    "logger"
  ),
  format = "rds",
  workspace_on_error = TRUE
)

# Define the pipeline
list(
  # 1. Run example simulations for demonstration
  tar_target(
    name = sim_small,
    command = {
      logger::log_info("Running small simulation for telemetry")
      randomwalk::run_simulation(
        grid_size = 10,
        n_walkers = 3,
        neighborhood = "4-hood",
        boundary = "terminate",
        workers = 0  # synchronous for reproducibility
      )
    }
  ),

  tar_target(
    name = sim_medium,
    command = {
      logger::log_info("Running medium simulation for telemetry")
      randomwalk::run_simulation(
        grid_size = 20,
        n_walkers = 5,
        neighborhood = "8-hood",
        boundary = "wrap",
        workers = 0
      )
    }
  ),

  # Large simulation for high coverage (25%+)
  tar_target(
    name = sim_large,
    command = {
      logger::log_info("Running large simulation for high coverage")
      randomwalk::run_simulation(
        grid_size = 30,
        n_walkers = 12,
        neighborhood = "8-hood",
        boundary = "wrap",
        workers = 0,
        max_steps = 10000
      )
    }
  ),

  # Performance comparison: synchronous
  tar_target(
    name = perf_sync,
    command = {
      logger::log_info("Running sync performance test")
      start_time <- Sys.time()
      result <- randomwalk::run_simulation(
        grid_size = 25,
        n_walkers = 8,
        neighborhood = "8-hood",
        boundary = "wrap",
        workers = 0,
        max_steps = 5000
      )
      end_time <- Sys.time()
      list(
        result = result,
        elapsed = as.numeric(difftime(end_time, start_time, units = "secs"))
      )
    }
  ),

  # Performance comparison: asynchronous
  tar_target(
    name = perf_async,
    command = {
      logger::log_info("Running async performance test")
      start_time <- Sys.time()
      result <- randomwalk::run_simulation(
        grid_size = 25,
        n_walkers = 8,
        neighborhood = "8-hood",
        boundary = "wrap",
        workers = 4,
        max_steps = 5000
      )
      end_time <- Sys.time()
      list(
        result = result,
        elapsed = as.numeric(difftime(end_time, start_time, units = "secs"))
      )
    }
  ),

  # 2. Extract simulation statistics
  tar_target(
    name = stats_small,
    command = sim_small$statistics
  ),

  tar_target(
    name = stats_medium,
    command = sim_medium$statistics
  ),

  tar_target(
    name = stats_large,
    command = sim_large$statistics
  ),

  # 3. Create visualization plots
  tar_target(
    name = plot_small_grid,
    command = {
      if (requireNamespace("randomwalk", quietly = TRUE) &&
          exists("plot_grid", where = "package:randomwalk")) {
        randomwalk::plot_grid(sim_small)
      } else {
        # Fallback plot if function not available
        ggplot2::ggplot() +
          ggplot2::annotate("text", x = 0.5, y = 0.5,
                           label = "Grid visualization not available") +
          ggplot2::theme_void()
      }
    }
  ),

  tar_target(
    name = plot_medium_grid,
    command = {
      if (requireNamespace("randomwalk", quietly = TRUE) &&
          exists("plot_grid", where = "package:randomwalk")) {
        randomwalk::plot_grid(sim_medium)
      } else {
        ggplot2::ggplot() +
          ggplot2::annotate("text", x = 0.5, y = 0.5,
                           label = "Grid visualization not available") +
          ggplot2::theme_void()
      }
    }
  ),

  tar_target(
    name = plot_large_grid,
    command = {
      if (requireNamespace("randomwalk", quietly = TRUE) &&
          exists("plot_grid", where = "package:randomwalk")) {
        randomwalk::plot_grid(sim_large)
      } else {
        ggplot2::ggplot() +
          ggplot2::annotate("text", x = 0.5, y = 0.5,
                           label = "Grid visualization not available") +
          ggplot2::theme_void()
      }
    }
  ),

  # 4. Pipeline visualization
  tar_target(
    name = pipeline_network,
    command = {
      # Save as static HTML widget that can be embedded
      vis <- targets::tar_visnetwork(
        targets_only = TRUE,
        label = c("time", "size", "branches")
      )
      # Return the visNetwork object
      vis
    }
  ),

  # 5. Session info (Section 10.3 - Additional Statistics)
  tar_target(
    name = session_info,
    command = sessionInfo()
  ),

  # 7. Package metadata
  tar_target(
    name = package_info,
    command = {
      desc <- read.dcf("DESCRIPTION")
      list(
        package = desc[, "Package"],
        version = desc[, "Version"],
        title = desc[, "Title"],
        description = desc[, "Description"],
        date = Sys.Date()
      )
    }
  ),

  # 8. Git/GitHub summary
  tar_target(
    name = git_summary,
    command = {
      tryCatch({
        list(
          branch = system("git branch --show-current", intern = TRUE),
          commit = system("git rev-parse --short HEAD", intern = TRUE),
          remote = system("git config --get remote.origin.url", intern = TRUE),
          status = system("git status --short", intern = TRUE)
        )
      }, error = function(e) {
        list(branch = "unknown", commit = "unknown",
             remote = "unknown", status = "Git not available")
      })
    }
  )
)
