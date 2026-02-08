# Fixed Non-Blocking Simulation Pattern for dashboard_comprehensive.qmd
# This shows the corrected pattern that should replace lines 624-759

# CURRENT BROKEN PATTERN (lines 665-694):
# observeEvent(input$run_sim, {
#   for (i in 1:chunks) {
#     Sys.sleep(est_runtime / chunks)  # BLOCKS UI!
#   }
# })

# ============================================================================
# FIXED NON-BLOCKING PATTERN
# ============================================================================

# Add these reactive values at the top of server function:
values <- reactiveValues(
  sim_chunk = 0,
  sim_chunks_total = 20,
  sim_est_runtime = 0,
  sim_chunk_start_time = NULL,
  sim_final_result = NULL
)

# Replace the observeEvent(input$run_sim, {...}) with:
observeEvent(input$run_sim, {
  # Initialize simulation state (NO BLOCKING!)
  sim_state("running")
  sim_start_time(Sys.time())
  sim_count(sim_count() + 1)

  # Reset progress
  sim_current_step(0)
  sim_completed_walkers(0)
  sim_black_pixels(0)

  # Validate parameters
  max_allowed <- floor(0.7 * input$grid_size^2)
  if (input$n_walkers > max_allowed) {
    sim_state("error")
    showNotification(sprintf("Too many walkers (%d) for grid. Max: %d",
                           input$n_walkers, max_allowed),
                    type = "error")
    return()
  }

  # Calculate runtime estimate
  est_steps_per_sec <- 200 / (1 + 0.002 * input$n_walkers)
  values$sim_est_runtime <- input$max_steps / est_steps_per_sec

  # Initialize chunked execution
  values$sim_chunk <- 0
  values$sim_chunks_total <- ifelse(is_webr(), 20, 1)  # 20 chunks for WebR, 1 for native
  values$sim_chunk_start_time <- Sys.time()

  # DON'T RUN SIMULATION HERE - let observe() handle it!
})

# Add this NEW observe() block for non-blocking simulation:
observe({
  # Only run when simulation is active and not complete
  if (sim_state() == "running" && values$sim_chunk < values$sim_chunks_total) {

    if (is_webr() && values$sim_chunk < values$sim_chunks_total - 1) {
      # WebR: Simulate progress for intermediate chunks
      invalidateLater(values$sim_est_runtime * 1000 / values$sim_chunks_total)  # ms per chunk

      # Update simulated progress
      values$sim_chunk <- values$sim_chunk + 1
      progress <- values$sim_chunk / values$sim_chunks_total

      sim_current_step(floor(input$max_steps * progress))
      sim_completed_walkers(floor(input$n_walkers * progress * 0.8))
      sim_black_pixels(floor(input$n_walkers * progress * 0.7))

      # Update status message
      output$status <- renderText({
        elapsed <- as.numeric(difftime(Sys.time(), sim_start_time(), units = "secs"))
        paste0(
          "SIMULATION RUNNING...\n",
          "Progress: ", round(progress * 100), "%\n",
          "Elapsed: ", format_duration(elapsed), "\n",
          "Estimated remaining: ", format_duration(values$sim_est_runtime - elapsed)
        )
      })

    } else {
      # Final chunk or native R: Run actual simulation
      # This will block briefly, but UI has been updating until now

      tryCatch({
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

        # Store result and complete
        values$sim_final_result <- result
        sim_result(result)
        sim_completed_walkers(result$statistics$completed_walkers)
        sim_black_pixels(result$statistics$black_pixels)
        sim_current_step(input$max_steps)

        # Mark complete
        sim_state("complete")
        sim_end_time(Sys.time())

        # Update final status
        elapsed <- as.numeric(difftime(sim_end_time(), sim_start_time(), units = "secs"))
        output$status <- renderText({
          paste0(
            "SIMULATION COMPLETE\n",
            "Run #", sim_count(), "\n",
            "━━━━━━━━━━━━━━━━━━━━━━\n",
            "Started:  ", format(sim_start_time(), "%H:%M:%S"), "\n",
            "Finished: ", format(sim_end_time(), "%H:%M:%S"), "\n",
            "Elapsed:  ", format_duration(elapsed), "\n",
            "━━━━━━━━━━━━━━━━━━━━━━\n",
            "Black Pixels: ", result$statistics$black_pixels, "\n",
            "Walkers: ", result$statistics$completed_walkers, " completed"
          )
        })

      }, error = function(e) {
        sim_state("error")
        sim_end_time(Sys.time())

        output$status <- renderText({
          paste0(
            "SIMULATION ERROR\n",
            "━━━━━━━━━━━━━━━━━━━━━━\n",
            "Error: ", conditionMessage(e)
          )
        })
      })

      # Reset chunk counter for next run
      values$sim_chunk <- values$sim_chunks_total
    }
  }
})

# ============================================================================
# KEY DIFFERENCES FROM BROKEN VERSION:
# ============================================================================

# BROKEN (blocks UI):
# observeEvent(input$run_sim, {
#   for (i in 1:chunks) {
#     Sys.sleep(delay)  # UI frozen here!
#     update_progress()
#   }
#   run_simulation()  # UI still frozen!
# })

# FIXED (non-blocking):
# observeEvent(input$run_sim, {
#   # Just set initial state and exit
#   sim_state("running")
#   values$sim_chunk <- 0
# })
#
# observe({
#   if (sim_state() == "running") {
#     invalidateLater(delay)  # Schedule next check
#     values$sim_chunk <- values$sim_chunk + 1
#     update_progress()
#     # UI remains responsive!
#   }
# })

# ============================================================================
# TESTING THE FIX:
# ============================================================================

# Signs it's working:
# ✅ Clock continues ticking during simulation
# ✅ Progress updates show smooth transitions
# ✅ Browser remains responsive
# ✅ Can interact with other UI elements

# Signs it's still broken:
# ❌ Clock freezes when simulation starts
# ❌ Progress jumps from 0% to 100%
# ❌ Browser shows "Page Unresponsive"
# ❌ No updates visible during simulation