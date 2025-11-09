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

  # 2. Extract simulation statistics
  tar_target(
    name = stats_small,
    command = sim_small$statistics
  ),

  tar_target(
    name = stats_medium,
    command = sim_medium$statistics
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

  # 4. Targets pipeline telemetry (Section 10.2 - Required Statistics)
  tar_target(
    name = pipeline_meta,
    command = targets::tar_meta(),
    cue = tar_cue(mode = "always")
  ),

  tar_target(
    name = telemetry_summary,
    command = {
      meta <- pipeline_meta
      meta %>%
        dplyr::filter(!is.na(seconds)) %>%
        dplyr::select(name, seconds, bytes, warnings, error) %>%
        dplyr::mutate(
          time_formatted = sprintf("%.2f sec", seconds),
          memory_mb = round(bytes / (1024^2), 2),
          status = dplyr::case_when(
            !is.na(error) ~ "error",
            warnings > 0 ~ "warning",
            TRUE ~ "success"
          )
        ) %>%
        dplyr::arrange(dplyr::desc(seconds))
    }
  ),

  # 5. Create telemetry visualization
  tar_target(
    name = plot_pipeline_timing,
    command = {
      telemetry_summary %>%
        dplyr::filter(status == "success") %>%
        ggplot2::ggplot(ggplot2::aes(x = reorder(name, seconds), y = seconds)) +
        ggplot2::geom_col(fill = "steelblue") +
        ggplot2::coord_flip() +
        ggplot2::labs(
          title = "Target Pipeline: Computation Time by Target",
          x = "Target Name",
          y = "Time (seconds)"
        ) +
        ggplot2::theme_minimal() +
        ggplot2::theme(
          plot.title = ggplot2::element_text(face = "bold", hjust = 0.5)
        )
    }
  ),

  tar_target(
    name = plot_pipeline_memory,
    command = {
      telemetry_summary %>%
        dplyr::filter(status == "success", memory_mb > 0) %>%
        ggplot2::ggplot(ggplot2::aes(x = reorder(name, memory_mb), y = memory_mb)) +
        ggplot2::geom_col(fill = "coral") +
        ggplot2::coord_flip() +
        ggplot2::labs(
          title = "Target Pipeline: Memory Usage by Target",
          x = "Target Name",
          y = "Memory (MB)"
        ) +
        ggplot2::theme_minimal() +
        ggplot2::theme(
          plot.title = ggplot2::element_text(face = "bold", hjust = 0.5)
        )
    }
  ),

  # 6. Session info (Section 10.3 - Additional Statistics)
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
