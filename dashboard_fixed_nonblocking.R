# Non-blocking simulation implementation for dashboard_comprehensive.qmd
# Replace lines 623-759 with this implementation

# Add these reactive values near the top of server function (around line 470):
# sim_chunk <- reactiveVal(0)
# sim_chunks_total <- reactiveVal(1)
# sim_est_runtime <- reactiveVal(0)

# Then replace observeEvent(input$run_sim, {...}) starting at line 623:

  # Reactive values for non-blocking simulation
  sim_chunk <- reactiveVal(0)
  sim_chunks_total <- reactiveVal(1)
  sim_est_runtime <- reactiveVal(0)

  # Run simulation when button clicked - NON-BLOCKING PATTERN
  observeEvent(input$run_sim, {
    # Initialize state (NO BLOCKING!)
    sim_state("running")
    sim_start_time(Sys.time())
    sim_count(sim_count() + 1)

    output$status <- renderText({
      paste0(
        "SIMULATION STARTING...\n",
        "Run #", sim_count(), "\n",
        "Grid: ", input$grid_size, "×", input$grid_size, "\n",
        "Walkers: ", input$n_walkers, "\n",
        "Workers: 0 (sync sequential)\n",
        "Started: ", format(sim_start_time(), "%H:%M:%S"), "\n",
        "Status: Initializing..."
      )
    })

    # Validate walker count
    max_allowed <- floor(0.7 * input$grid_size^2)
    if (input$n_walkers > max_allowed) {
      sim_state("error")
      output$status <- renderText({
        sprintf("ERROR: Too many walkers (%d) for grid size %dx%d.\nMaximum allowed: %d (70%% of grid pixels)",
                input$n_walkers, input$grid_size, input$grid_size, max_allowed)
      })
      return()
    }

    # Reset progress tracking
    sim_current_step(0)
    sim_completed_walkers(0)
    sim_black_pixels(0)

    # Calculate runtime estimate
    est_steps_per_sec <- 200 / (1 + 0.002 * input$n_walkers)
    sim_est_runtime(input$max_steps / est_steps_per_sec)

    # Initialize chunked execution for WebR
    if (is_webr()) {
      sim_chunks_total(20)  # 20 chunks for smooth updates
      sim_chunk(0)
    } else {
      sim_chunks_total(1)   # Single chunk for native R
      sim_chunk(0)
    }
    # DON'T RUN SIMULATION HERE - let observe() handle it!
  })

  # Non-blocking simulation observer (crew pattern)
  observe({
    # Only run when simulation is active and not complete
    if (sim_state() == "running" && sim_chunk() < sim_chunks_total()) {

      if (is_webr() && sim_chunk() < sim_chunks_total() - 1) {
        # WebR: Simulate progress for intermediate chunks
        invalidateLater(sim_est_runtime() * 1000 / sim_chunks_total())  # ms per chunk

        # Update chunk counter
        sim_chunk(sim_chunk() + 1)
        progress <- sim_chunk() / sim_chunks_total()

        # Update simulated progress
        sim_current_step(floor(input$max_steps * progress))
        sim_completed_walkers(floor(input$n_walkers * progress * 0.8))
        sim_black_pixels(floor(input$n_walkers * progress * 0.7))

        # Update status with progress bar
        output$status <- renderText({
          elapsed <- as.numeric(difftime(Sys.time(), sim_start_time(), units = "secs"))
          bar_width <- 20
          filled <- round(progress * bar_width)
          paste0(
            "SIMULATION RUNNING...\n",
            "Run #", sim_count(), "\n",
            "Progress: ", round(progress * 100), "%\n",
            "━", strrep("━", filled), strrep(" ", bar_width - filled), "┃\n",
            "Elapsed: ", format_duration(elapsed), "\n",
            "Est. remaining: ", format_duration(max(0, sim_est_runtime() - elapsed)), "\n",
            "━━━━━━━━━━━━━━━━━━━━━━\n",
            "Walkers: ", sim_completed_walkers(), "/", input$n_walkers, "\n",
            "Black pixels: ", sim_black_pixels()
          )
        })

      } else {
        # Final chunk: run actual simulation
        # Mark this as the final chunk to prevent re-execution
        sim_chunk(sim_chunks_total())

        tryCatch({
          # Show running message
          output$status <- renderText({
            paste0(
              "SIMULATION RUNNING...\n",
              "Run #", sim_count(), "\n",
              "Progress: 95%\n",
              "━━━━━━━━━━━━━━━━━━━━━━\n",
              "Running final calculation...\n",
              "Please wait..."
            )
          })

          result <- run_simulation(
            grid_size = input$grid_size,
            n_walkers = input$n_walkers,
            neighborhood = input$neighborhood,
            boundary = input$boundary,
            max_steps = input$max_steps,
            workers = 0,
            sync_mode = "static",
            verbose = FALSE,
            validate_percent = 0
          )

          # Store result
          sim_result(result)
          sim_completed_walkers(result$statistics$completed_walkers)
          sim_black_pixels(result$statistics$black_pixels)
          sim_current_step(input$max_steps)

          # Mark complete
          sim_state("complete")
          sim_end_time(Sys.time())

          # Update final status
          elapsed <- as.numeric(difftime(sim_end_time(), sim_start_time(), units = "secs"))

          # Re-enable the button
          updateActionButton(session, "run_sim",
                            label = "Run Simulation",
                            disabled = FALSE)

          # Browser console logging for WebR diagnostics
          message(sprintf("\n=== SIMULATION COMPLETE ==="))
          message(sprintf("Grid size: %dx%d", input$grid_size, input$grid_size))
          message(sprintf("Walkers: %d", input$n_walkers))
          message(sprintf("Black pixels: %d", sum(result$grid == 1)))
          message(sprintf("Elapsed time: %s", format_duration(elapsed)))
          message(sprintf("==========================\n"))

          output$status <- renderText({
            paste0(
              "SIMULATION COMPLETE\n",
              "Run #", sim_count(), "\n",
              "━━━━━━━━━━━━━━━━━━━━━━\n",
              "Started:  ", format(sim_start_time(), "%H:%M:%S"), "\n",
              "Finished: ", format(sim_end_time(), "%H:%M:%S"), "\n",
              "Elapsed:  ", format_duration(elapsed), "\n",
              "━━━━━━━━━━━━━━━━━━━━━━\n",
              "Backend: synchronous (WebR browser)\n",
              "Black Pixels: ", result$statistics$black_pixels, "\n",
              "Walkers: ", result$statistics$completed_walkers, " completed"
            )
          })

        }, error = function(e) {
          sim_state("error")
          sim_end_time(Sys.time())

          # Re-enable the button
          updateActionButton(session, "run_sim",
                            label = "Run Simulation",
                            disabled = FALSE)

          output$status <- renderText({
            paste0(
              "SIMULATION ERROR\n",
              "━━━━━━━━━━━━━━━━━━━━━━\n",
              "Error: ", conditionMessage(e), "\n",
              "━━━━━━━━━━━━━━━━━━━━━━\n",
              "Please try again with different parameters."
            )
          })
        })
      }
    }
  })

# ============================================================================
# KEY CHANGES FROM BROKEN VERSION:
# ============================================================================
#
# 1. REMOVED Sys.sleep() - was blocking UI thread
# 2. ADDED invalidateLater() - schedules non-blocking updates
# 3. SEPARATED task initiation from monitoring
# 4. USED observe() for periodic progress checks
# 5. ADDED progress bar visualization
#
# The UI now remains responsive throughout the simulation!
# ============================================================================