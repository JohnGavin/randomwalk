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
    "DT",        # For interactive sortable tables in vignettes
    "ggplot2",
    "logger",
    "purrr",     # For functional programming in vignettes
    # fs loaded explicitly inside targets that need it (not in default-ci.nix)
    "pkgdown",   # For building website
    "quarto",    # For rendering vignettes
    "tidyr"      # For data reshaping in vignettes
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
  ),

  # 9. Code coverage analysis (Issue #160)
  # DISABLED: Causes "error reading from connection" in both local and CI environments
  # TODO: Debug covr package_coverage() connection error
  # tar_target(
  #   name = code_coverage,
  #   command = {
  #     library(covr)
  #     devtools::load_all()  # Load package in Nix environment
  #     logger::log_info("Generating code coverage report")
  #
  #     # Generate coverage
  #     coverage <- package_coverage()
  #
  #     # Calculate overall percentage
  #     overall_pct <- percent_coverage(coverage)
  #
  #     # Create file summary
  #     file_coverage <- tidy(coverage)
  #
  #     file_summary <- file_coverage %>%
  #       group_by(filename) %>%
  #       summarise(
  #         lines_total = n(),
  #         lines_covered = sum(value > 0),
  #         coverage_pct = (lines_covered / lines_total) * 100,
  #         .groups = "drop"
  #       ) %>%
  #       arrange(desc(coverage_pct))
  #
  #     # Return structured coverage data
  #     list(
  #       overall_pct = overall_pct,
  #       file_summary = file_summary,
  #       coverage_obj = coverage
  #     )
  #   }
  # ),

  # ============================================================================
  # Dynamic Broadcasting Simulations (Issue #51)
  # ============================================================================

  # Small dynamic simulation (500 steps) - Quick demonstration
  tar_target(
    name = sim_dynamic_small,
    command = {
      devtools::load_all()
      logger::log_info("Running small dynamic broadcasting simulation (fallback to static due to #51)")
      randomwalk::run_simulation(
        grid_size = 50,
        n_walkers = 10,
        workers = 2,
        sync_mode = "static", # FIXME: Revert to "dynamic" once #51 is resolved
        max_steps = 500,
        neighborhood = "4-hood",
        boundary = "terminate"
      )
    }
  ),

  # Medium dynamic simulation (3000 steps) - Balanced performance (optimized for #124)
  tar_target(
    name = sim_dynamic_medium,
    command = {
      devtools::load_all()
      logger::log_info("Running medium dynamic broadcasting simulation (fallback to static due to #51)")
      randomwalk::run_simulation(
        grid_size = 75,  # Reduced from 100 for faster testing (#124)
        n_walkers = 15,  # Reduced from 20 for faster testing (#124)
        workers = 4,
        sync_mode = "static", # FIXME: Revert to "dynamic" once #51 is resolved
        max_steps = 3000,  # Reduced from 4000 for faster testing (#124)
        neighborhood = "4-hood",
        boundary = "terminate"
      )
    }
  ),

  # Large dynamic simulation (8000 steps) - Stress test (optimized for #124)
  tar_target(
    name = sim_dynamic_large,
    command = {
      devtools::load_all()
      logger::log_info("Running large dynamic broadcasting simulation (fallback to static due to #51)")
      randomwalk::run_simulation(
        grid_size = 150,  # Reduced from 200 for faster testing (#124)
        n_walkers = 35,   # Reduced from 50 for faster testing (#124)
        workers = 8,
        sync_mode = "static", # FIXME: Revert to "dynamic" once #51 is resolved
        max_steps = 8000,  # Reduced from 12000 for faster testing (#124)
        neighborhood = "4-hood",
        boundary = "terminate"
      )
    }
  ),

  # Static mode comparisons (for vignette analysis)
  tar_target(
    name = sim_static_small,
    command = {
      devtools::load_all()
      logger::log_info("Running small static simulation (comparison)")
      randomwalk::run_simulation(
        grid_size = 50,
        n_walkers = 10,
        workers = 2,
        sync_mode = "static",
        max_steps = 500,
        neighborhood = "4-hood",
        boundary = "terminate"
      )
    }
  ),

  tar_target(
    name = sim_static_medium,
    command = {
      devtools::load_all()
      logger::log_info("Running medium static simulation (comparison)")
      randomwalk::run_simulation(
        grid_size = 75,  # Reduced from 100 for faster testing (#124)
        n_walkers = 15,  # Reduced from 20 for faster testing (#124)
        workers = 4,
        sync_mode = "static",
        max_steps = 3000,  # Reduced from 4000 for faster testing (#124)
        neighborhood = "4-hood",
        boundary = "terminate"
      )
    }
  ),

  tar_target(
    name = sim_static_large,
    command = {
      devtools::load_all()
      logger::log_info("Running large static simulation (comparison)")
      randomwalk::run_simulation(
        grid_size = 150,  # Reduced from 200 for faster testing (#124)
        n_walkers = 35,   # Reduced from 50 for faster testing (#124)
        workers = 8,
        sync_mode = "static",
        max_steps = 8000,  # Reduced from 12000 for faster testing (#124)
        neighborhood = "4-hood",
        boundary = "terminate"
      )
    }
  ),

  # Comparison plots
  tar_target(
    name = plot_dynamic_small,
    command = {
      devtools::load_all()
      randomwalk::plot_grid(
        sim_dynamic_small,
        main = "Dynamic Broadcasting - Small (50×50, 500 steps)"
      )
    }
  ),

  tar_target(
    name = plot_static_small,
    command = {
      devtools::load_all()
      randomwalk::plot_grid(
        sim_static_small,
        main = "Static Snapshot - Small (50×50, 500 steps)"
      )
    }
  ),

  tar_target(
    name = plot_dynamic_medium,
    command = {
      devtools::load_all()
      randomwalk::plot_grid(
        sim_dynamic_medium,
        main = "Dynamic Broadcasting - Medium (75×75, 3000 steps)"
      )
    }
  ),

  tar_target(
    name = plot_static_medium,
    command = {
      devtools::load_all()
      randomwalk::plot_grid(
        sim_static_medium,
        main = "Static Snapshot - Medium (75×75, 3000 steps)"
      )
    }
  ),

  # ============================================================================
  # End Dynamic Broadcasting Simulations
  # ============================================================================

  # ============================================================================
  # Step Distribution Analysis Targets (Issue #169)
  # ============================================================================

  # Grid sizes for step distribution analysis
  tar_target(
    name = step_dist_grid_sizes,
    command = c(20, 40, 60)
  ),

  # Run simulations for each grid size (dynamic branching)
  tar_target(
    name = step_dist_sims,
    command = {
      devtools::load_all()
      logger::log_info(sprintf("Running step_dist simulation for grid_size=%d", step_dist_grid_sizes))
      set.seed(123)  # For reproducibility
      run_simulation(
        grid_size = step_dist_grid_sizes,
        n_walkers = 100,
        neighborhood = "4-hood",
        boundary = "terminate",
        max_steps = 5000,
        workers = 0,
        verbose = FALSE
      )
    },
    pattern = map(step_dist_grid_sizes),
    iteration = "list"
  ),

  # ============================================================================
  # End Step Distribution Analysis Targets
  # ============================================================================

  # ============================================================================
  # Vignette Rendering
  # ============================================================================

  # Render dashboard vignettes using tar_quarto for reproducibility
  # This ensures dependencies are tracked and rebuilds happen only when needed
  
  # NOTE: Disabled broken vignettes (Issue #132)
  # - dashboard: Service Worker errors, old Shinylive/webR 4.4.1
  # - dashboard_async: Same Service Worker issues
  # - telemetry: Missing target definitions (plot_pipeline_timing, etc.)
  # tarchetypes::tar_quarto(
  #   name = dashboard,
  #   path = "vignettes/dashboard.qmd"
  # ),
  #
  # tarchetypes::tar_quarto(
  #   name = dashboard_async,
  #   path = "vignettes/dashboard_async.qmd"
  # ),

  # DISABLED: Telemetry vignette depends on telemetry_summary target (which uses tar_meta())
  # tarchetypes::tar_quarto(
  #   name = telemetry,
  #   path = "vignettes/articles/telemetry.qmd"
  # ),

  tarchetypes::tar_quarto(
    name = dynamic_broadcasting,
    path = "vignettes/articles/dynamic_broadcasting.qmd"
  ),

  tarchetypes::tar_quarto(
    name = step_distribution_analysis,
    path = "vignettes/articles/step_distribution_analysis.qmd",
    quiet = FALSE  # Show quarto errors for debugging
  ),

  # ============================================================================
  # pkgdown Site Building
  # ============================================================================
  # Build pkgdown website WITHOUT re-rendering vignettes
  # Vignettes are pre-rendered by tar_quarto() targets above
  # pkgdown just copies the pre-built HTML files
  # This avoids Quarto/bslib/Nix incompatibility issues
  tar_target(
    name = pkgdown_site,
    command = {
      # Build ONLY reference docs and home page (NOT articles)
      pkgdown::build_reference()
      pkgdown::build_home()

      # Manually copy pre-built vignettes to docs/articles/
      if (!dir.exists("docs/articles")) {
        dir.create("docs/articles", recursive = TRUE)
      }

      # Copy all pre-rendered HTML files from vignettes/articles/
      html_files <- list.files("vignettes/articles", pattern = "\\.html$", full.names = TRUE)
      if (length(html_files) > 0) {
        file.copy(html_files, "docs/articles/", overwrite = TRUE)
        message(sprintf("Copied %d pre-rendered vignette HTML files", length(html_files)))
      }

      # Copy all *_files directories from vignettes/articles/ (Shinylive assets, etc.)
      asset_dirs <- list.dirs("vignettes/articles", full.names = TRUE, recursive = FALSE)
      asset_dirs <- asset_dirs[grep("_files$", asset_dirs)]

      if (length(asset_dirs) > 0) {
        for (dir in asset_dirs) {
          dirname <- basename(dir)
          target <- file.path("docs/articles", dirname)

          # Remove target if exists for clean copy
          if (dir.exists(target)) {
            unlink(target, recursive = TRUE)
          }

          file.copy(dir, "docs/articles/", recursive = TRUE)
          message(sprintf("Copied asset directory %s", dirname))
        }
      }

      # NOTE: build_articles_index() fails with manually copied vignettes
      # because pkgdown doesn't recognize tar_quarto-rendered articles.
      # Articles are accessible via navbar menu instead (see _pkgdown.yml).
      # pkgdown::build_articles_index()

      # Return docs/ as tracked output
      "docs/"
    },
    format = "file"
  ),

  # Target to copy rendered vignettes to inst/doc
  tar_target(
    name = copy_vignettes_to_inst_doc,
    command = {
      # Ensure fs is loaded
      library(fs)
      
      # The values of the upstream tar_quarto targets (which are the paths to the rendered HTML)
      # are implicitly available here by their names
      dynamic_broadcasting_html_path <- dynamic_broadcasting

      # Ensure inst/doc directory exists
      fs::dir_create("inst/doc")

      # Define source and destination base directory for _files
      vignettes_dir <- "vignettes"
      inst_doc_dir <- "inst/doc"

      # Function to copy HTML and its associated _files directory
      copy_vignette_output <- function(html_path, vignette_name) {
        base_html_name <- basename(html_path)
        source_files_dir <- file.path(vignettes_dir, paste0(vignette_name, "_files"))
        dest_html_path <- file.path(inst_doc_dir, base_html_name)
        dest_files_dir <- file.path(inst_doc_dir, paste0(vignette_name, "_files"))

        # Copy HTML file
        file.copy(html_path, dest_html_path, overwrite = TRUE)

        # Copy _files directory if it exists
        if (fs::dir_exists(source_files_dir)) {
          fs::dir_copy(source_files_dir, dest_files_dir, overwrite = TRUE)
        }

        # Return paths of copied files for targets to track
        c(dest_html_path, dest_files_dir)
      }

      # Copy only dynamic_broadcasting (Issue #132: other vignettes disabled)
      copied_files <- copy_vignette_output(dynamic_broadcasting_html_path, "dynamic_broadcasting")

      copied_files
    }
  )

  # 10. Telemetry summary for vignette
  # DISABLED: tar_meta() cannot be called during pipeline execution
  # TODO: Move telemetry collection to a separate script run AFTER tar_make()
  # tar_target(
  #   name = telemetry_summary,
  #   command = {
  #     library(targets)
  #     library(dplyr)
  #
  #     # Get metadata from targets
  #     meta <- tar_meta() %>%
  #       filter(!is.na(seconds)) %>%
  #       mutate(
  #         time_seconds = as.numeric(seconds),
  #         time_formatted = sprintf("%.2f", time_seconds),
  #         memory_mb = as.numeric(bytes) / (1024^2),
  #         status = "completed"
  #       ) %>%
  #       select(name, time_formatted, time_seconds, memory_mb, status)
  #
  #     meta
  #   }
  # ),

  # 11. Pipeline timing visualization
  # DISABLED: Depends on telemetry_summary which uses tar_meta()
  # tar_target(
  #   name = plot_pipeline_timing,
  #   command = {
  #     library(ggplot2)
  #     library(dplyr)
  #
  #     telemetry_summary %>%
  #       arrange(desc(time_seconds)) %>%
  #       head(20) %>%
  #       mutate(name = reorder(name, time_seconds)) %>%
  #       ggplot(aes(x = name, y = time_seconds)) +
  #       geom_col(fill = "steelblue", alpha = 0.8) +
  #       coord_flip() +
  #       labs(
  #         title = "Top 20 Longest Running Targets",
  #         subtitle = "Computation time distribution",
  #         x = "Target Name",
  #         y = "Computation Time (seconds)"
  #       ) +
  #       theme_minimal()
  #   }
  # ),

  # 12. Pipeline memory visualization
  # DISABLED: Depends on telemetry_summary which uses tar_meta()
  # tar_target(
  #   name = plot_pipeline_memory,
  #   command = {
  #     library(ggplot2)
  #     library(dplyr)
  #
  #     telemetry_summary %>%
  #       arrange(desc(memory_mb)) %>%
  #       head(20) %>%
  #       mutate(name = reorder(name, memory_mb)) %>%
  #       ggplot(aes(x = name, y = memory_mb)) +
  #       geom_col(fill = "coral", alpha = 0.8) +
  #       coord_flip() +
  #       labs(
  #         title = "Top 20 Memory-Intensive Targets",
  #         subtitle = "Memory usage distribution",
  #         x = "Target Name",
  #         y = "Memory (MB)"
  #       ) +
  #       theme_minimal()
  #   }
  # )
)
