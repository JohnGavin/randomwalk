# _targets.R for randomwalk package telemetry
# This file defines the targets pipeline for pre-computing all vignette objects
# Following context.md Section 4: Targets Package

library(targets)
library(tarchetypes)

# Set target options
tar_option_set(
  packages = c(
    "devtools",  # For load_all() in Nix environment
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
      devtools::load_all()  # Load package in Nix environment
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
      devtools::load_all()  # Load package in Nix environment
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
  # With 30x30 = 900 pixels, need ~225 black pixels for 25% coverage
  # Each walker typically creates 1 black pixel before terminating (touches black neighbor)
  # Therefore need 250-300 walkers to ensure >225 black pixels
  tar_target(
    name = sim_large,
    command = {
      devtools::load_all()  # Load package in Nix environment
      logger::log_info("Running large simulation for high coverage (target: 25%+ black pixels)")
      randomwalk::run_simulation(
        grid_size = 30,
        n_walkers = 300,  # Need many walkers since each creates ~1 black pixel
        neighborhood = "8-hood",
        boundary = "wrap",
        workers = 0,
        max_steps = 10000  # Per-walker step limit (safety)
      )
    }
  ),

  # Performance comparison: synchronous
  tar_target(
    name = perf_sync,
    command = {
      devtools::load_all()  # Load package in Nix environment
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
      devtools::load_all()  # Load package in Nix environment
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
  # plot_grid() now returns ggplot2 objects that can be properly stored and displayed
  tar_target(
    name = plot_small_grid,
    command = {
      devtools::load_all()  # Load package in Nix environment
      randomwalk::plot_grid(
        sim_small,
        main = "Small Simulation (10×10)"
      )
    }
  ),

  tar_target(
    name = plot_medium_grid,
    command = {
      devtools::load_all()  # Load package in Nix environment
      randomwalk::plot_grid(
        sim_medium,
        main = "Medium Simulation (20×20)"
      )
    }
  ),

  tar_target(
    name = plot_large_grid,
    command = {
      devtools::load_all()  # Load package in Nix environment
      randomwalk::plot_grid(
        sim_large,
        main = "Large Simulation (30×30)"
      )
    }
  ),

  # 4. Session info (Section 10.3 - Additional Statistics)
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
