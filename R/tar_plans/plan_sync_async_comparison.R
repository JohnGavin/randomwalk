# Targets plan for sync vs async comparison vignette
#
# This plan runs identical simulations with different worker configurations
# to demonstrate the "fractal similarity" between sync and async modes.
#
# Usage:
#   targets::tar_make()
#   targets::tar_read(comparison_results)

library(targets)
library(tarchetypes)
library(randomwalk)
library(dplyr)
library(ggplot2)
library(logger)

# Simulation parameters (kept identical across all modes)
GRID_SIZE <- 50
N_WALKERS <- 20
NEIGHBORHOOD <- "4-hood"
MAX_STEPS <- 500
SEED <- 42

list(
  # Configuration 1: workers=0 (true synchronous)
  tar_target(
    sim_sync,
    {
      set.seed(SEED)
      randomwalk::run_simulation(
        grid_size = GRID_SIZE,
        n_walkers = N_WALKERS,
        workers = 0,  # No crew controller
        neighborhood = NEIGHBORHOOD,
        max_steps = MAX_STEPS,
        validate_percent = 0  # Disable validation for clean timing
      )
    }
  ),

  # Configuration 2: workers=1 (async architecture, sequential execution)
  tar_target(
    sim_async_1,
    {
      set.seed(SEED)
      randomwalk::run_simulation(
        grid_size = GRID_SIZE,
        n_walkers = N_WALKERS,
        workers = 1,  # Crew controller with 1 worker
        neighborhood = NEIGHBORHOOD,
        max_steps = MAX_STEPS,
        validate_percent = 0
      )
    }
  ),

  # Configuration 3: workers=2 (true parallel)
  tar_target(
    sim_async_2,
    {
      set.seed(SEED)
      randomwalk::run_simulation(
        grid_size = GRID_SIZE,
        n_walkers = N_WALKERS,
        workers = 2,  # Parallel execution
        neighborhood = NEIGHBORHOOD,
        max_steps = MAX_STEPS,
        validate_percent = 0
      )
    }
  ),

  # Configuration 4: workers=4 (more parallelism)
  tar_target(
    sim_async_4,
    {
      set.seed(SEED)
      randomwalk::run_simulation(
        grid_size = GRID_SIZE,
        n_walkers = N_WALKERS,
        workers = 4,  # Maximum parallelism for this example
        neighborhood = NEIGHBORHOOD,
        max_steps = MAX_STEPS,
        validate_percent = 0
      )
    }
  ),

  # Extract timing information
  tar_target(
    timing_comparison,
    {
      tibble::tibble(
        workers = c(0, 1, 2, 4),
        simulation = c("Sync (workers=0)", "Async 1 worker", "Async 2 workers", "Async 4 workers"),
        elapsed_time = c(
          sim_sync$elapsed_time,
          sim_async_1$elapsed_time,
          sim_async_2$elapsed_time,
          sim_async_4$elapsed_time
        ),
        architecture = c("Direct calls", "Task queue + 1 worker", "Task queue + 2 workers", "Task queue + 4 workers")
      ) |>
        dplyr::mutate(
          speedup = elapsed_time[1] / elapsed_time,
          efficiency = speedup / pmax(workers, 1)
        )
    }
  ),

  # Extract grid statistics
  tar_target(
    grid_comparison,
    {
      tibble::tibble(
        workers = c(0, 1, 2, 4),
        simulation = c("Sync", "Async-1", "Async-2", "Async-4"),
        black_pixels = c(
          sum(sim_sync$grid == 1),
          sum(sim_async_1$grid == 1),
          sum(sim_async_2$grid == 1),
          sum(sim_async_4$grid == 1)
        ),
        coverage_pct = black_pixels / (GRID_SIZE^2) * 100
      )
    }
  ),

  # Create timing comparison plot
  tar_target(
    plot_timing,
    {
      ggplot(timing_comparison, aes(x = factor(workers), y = elapsed_time)) +
        geom_col(fill = "steelblue") +
        geom_text(aes(label = sprintf("%.2fs", elapsed_time)),
                  vjust = -0.5, size = 3.5) +
        labs(
          title = "Execution Time by Worker Configuration",
          subtitle = sprintf("Grid: %dx%d, Walkers: %d, Seed: %d",
                           GRID_SIZE, GRID_SIZE, N_WALKERS, SEED),
          x = "Number of Workers",
          y = "Elapsed Time (seconds)"
        ) +
        theme_minimal() +
        theme(
          plot.title = element_text(face = "bold"),
          axis.text = element_text(size = 10)
        )
    }
  ),

  # Create speedup comparison plot
  tar_target(
    plot_speedup,
    {
      timing_comparison |>
        filter(workers > 0) |>  # Exclude workers=0 baseline
        ggplot(aes(x = factor(workers), y = speedup)) +
        geom_col(fill = "darkgreen") +
        geom_hline(yintercept = 1, linetype = "dashed", color = "red") +
        geom_text(aes(label = sprintf("%.2fx", speedup)),
                  vjust = -0.5, size = 3.5) +
        labs(
          title = "Speedup Relative to Synchronous Mode (workers=0)",
          x = "Number of Workers",
          y = "Speedup (times faster)"
        ) +
        theme_minimal() +
        theme(
          plot.title = element_text(face = "bold")
        )
    }
  ),

  # Create grid visualization for each mode
  tar_target(
    plot_grids,
    {
      # Helper function to convert grid to data frame
      grid_to_df <- function(grid, mode_label) {
        data.frame(
          x = rep(1:nrow(grid), each = ncol(grid)),
          y = rep(1:ncol(grid), nrow(grid)),
          value = as.vector(t(grid)),
          mode = mode_label
        )
      }

      # Combine all grids
      grid_data <- bind_rows(
        grid_to_df(sim_sync$grid, "workers=0 (Sync)"),
        grid_to_df(sim_async_1$grid, "workers=1 (Async)"),
        grid_to_df(sim_async_2$grid, "workers=2"),
        grid_to_df(sim_async_4$grid, "workers=4")
      )

      # Create faceted plot
      ggplot(grid_data, aes(x = x, y = y, fill = factor(value))) +
        geom_tile() +
        scale_fill_manual(
          values = c("0" = "white", "1" = "black"),
          labels = c("Unvisited", "Visited"),
          name = "State"
        ) +
        facet_wrap(~ mode, ncol = 2) +
        coord_equal() +
        labs(
          title = "Fractal Patterns: Sync vs Async Modes",
          subtitle = "Notice similar patterns despite different execution architectures"
        ) +
        theme_minimal() +
        theme(
          axis.text = element_blank(),
          axis.title = element_blank(),
          panel.grid = element_blank(),
          plot.title = element_text(face = "bold"),
          strip.text = element_text(face = "bold")
        )
    }
  ),

  # Summary statistics table
  tar_target(
    comparison_results,
    {
      timing_comparison |>
        select(workers, simulation, elapsed_time, speedup, efficiency) |>
        mutate(
          efficiency_pct = sprintf("%.1f%%", efficiency * 100),
          across(c(elapsed_time, speedup), ~sprintf("%.3f", .x))
        )
    }
  ),

  # Log completion
  tar_target(
    log_completion,
    {
      logger::log_info("Sync vs Async comparison targets completed successfully")
      logger::log_info("Results available in: comparison_results")
      logger::log_info("Plots available in: plot_timing, plot_speedup, plot_grids")
      TRUE
    }
  )
)
