# Implementation Plan: Issue #57 - Real-time Statistics Display
# Date: 2025-11-28
# Issue: https://github.com/JohnGavin/randomwalk/issues/57
#
# =============================================================================
# REQUIREMENTS
# =============================================================================
#
# 1. Display statistics as soon as computed (non-blocking)
# 2. Show timer until first intermediate results available
# 3. Add slider to review historical states during simulation
# 4. Plot fractal pattern after every X% of walkers complete
# 5. Slider to navigate through historical X% plots
#
# =============================================================================
# CURRENT STATE ANALYSIS
# =============================================================================
#
# File: inst/shiny/dashboard_async/app.R
#
# Current behavior:
# - Simulation runs in blocking mode (observeEvent)
# - Statistics displayed only after completion
# - No intermediate updates
# - No historical state tracking
#
# =============================================================================
# IMPLEMENTATION STRATEGY
# =============================================================================
#
# Phase 1: Non-blocking Execution
# --------------------------------
# Use Shiny's async capabilities to avoid blocking UI
#
# Options:
# A. ExtendedTask (Shiny 1.8+) - Recommended
# B. promises + future packages
# C. poll() for incremental updates
#
# Recommendation: ExtendedTask for clean async handling
#
# Phase 2: Intermediate Statistics
# ---------------------------------
# Modify run_simulation() to emit progress events
#
# Options:
# A. Use existing logger::log_info() at 5-walker intervals
# B. Add callback parameter to run_simulation()
# C. Create reactive values updated from simulation
#
# Recommendation: Add progress callback parameter
#
# Phase 3: Historical State Storage
# ----------------------------------
# Store grid states at regular intervals
#
# Data structure:
# list(
#   snapshots = list(
#     list(pct = 5, walkers_complete = 5, grid = matrix(...), stats = list(...)),
#     list(pct = 10, walkers_complete = 10, grid = matrix(...), stats = list(...)),
#     ...
#   )
# )
#
# Phase 4: Time Slider UI
# -----------------------
# Add slider to navigate historical states
#
# =============================================================================
# DETAILED IMPLEMENTATION
# =============================================================================

## Phase 1: Non-blocking Execution with ExtendedTask
## --------------------------------------------------

# In server function:
server <- function(input, output, session) {

  # Create ExtendedTask for simulation
  sim_task <- ExtendedTask$new(
    function(params) {
      # Run simulation with progress callback
      run_simulation_with_progress(
        grid_size = params$grid_size,
        n_walkers = params$n_walkers,
        workers = params$workers,
        neighborhood = params$neighborhood,
        boundary = params$boundary,
        max_steps = params$max_steps,
        progress_callback = function(progress_data) {
          # Update reactive values with progress
          sim_progress$snapshots <- c(sim_progress$snapshots, list(progress_data))
          sim_progress$current_pct <- progress_data$pct
        }
      )
    }
  )

  # Reactive values for progress tracking
  sim_progress <- reactiveValues(
    snapshots = list(),
    current_pct = 0,
    is_running = FALSE
  )

  # Start simulation (non-blocking)
  observeEvent(input$run_sim, {
    sim_progress$snapshots <- list()
    sim_progress$is_running <- TRUE

    params <- list(
      grid_size = input$grid_size,
      n_walkers = input$n_walkers,
      workers = input$workers,
      neighborhood = input$neighborhood,
      boundary = input$boundary,
      max_steps = input$max_steps
    )

    sim_task$invoke(params)
  })

  # Handle task completion
  observeEvent(sim_task$result(), {
    sim_progress$is_running <- FALSE
    output$status_text <- renderText("Simulation complete!")
  })
}


## Phase 2: Modify run_simulation() for Progress Callbacks
## --------------------------------------------------------

# Add to R/simulation.R:

#' Run Simulation with Progress Callback
#'
#' Enhanced version of run_simulation() that calls a progress callback
#' at regular intervals during async execution.
#'
#' @param progress_callback Function(list) called with progress data.
#'   Progress data includes: pct, walkers_complete, grid, stats
#' @param progress_percent Numeric. Call callback every X%. Default 5.
#'
#' @export
run_simulation_with_progress <- function(grid_size = 10,
                                          n_walkers = 5,
                                          neighborhood = "4-hood",
                                          boundary = "terminate",
                                          workers = 0,
                                          max_steps = 10000L,
                                          progress_callback = NULL,
                                          progress_percent = 5) {

  # ... existing setup code ...

  if (workers > 0) {
    # ASYNC MODE with progress callbacks
    validate_interval <- max(1, round(n_total * progress_percent / 100))

    while (n_completed < n_total) {
      # ... existing polling code ...

      # After each walker completes, check if we hit a milestone
      if (!is.null(progress_callback) &&
          n_completed %% validate_interval == 0) {

        # Create progress snapshot
        progress_data <- list(
          pct = round(n_completed / n_total * 100, 1),
          walkers_complete = n_completed,
          grid = grid,  # Current grid state
          stats = list(
            black_pixels = count_black_pixels(grid),
            black_percentage = get_black_percentage(grid),
            elapsed_secs = as.numeric(difftime(Sys.time(), start_time, units = "secs"))
          )
        )

        # Call callback (non-blocking)
        progress_callback(progress_data)
      }
    }
  }

  # ... rest of function ...
}


## Phase 3: Historical State Storage in Dashboard
## -----------------------------------------------

# In UI:
ui <- fluidPage(
  # ... existing UI ...

  # Add history slider (initially hidden)
  conditionalPanel(
    condition = "output.show_history_slider",
    sliderInput(
      "history_pct",
      "Review Simulation Progress:",
      min = 0,
      max = 100,
      value = 100,
      step = 5,
      ticks = TRUE,
      animate = animationOptions(interval = 1000)  # Play button!
    ),
    helpText("Slide to review grid at different completion percentages")
  )
)

# In server:
output$show_history_slider <- reactive({
  length(sim_progress$snapshots) > 1
})
outputOptions(output, "show_history_slider", suspendWhenHidden = FALSE)


## Phase 4: Display Historical State
## ----------------------------------

# Reactive to get snapshot for current slider position
current_snapshot <- reactive({
  if (length(sim_progress$snapshots) == 0) {
    return(NULL)
  }

  target_pct <- input$history_pct

  # Find closest snapshot
  snapshot_pcts <- sapply(sim_progress$snapshots, function(s) s$pct)
  closest_idx <- which.min(abs(snapshot_pcts - target_pct))

  sim_progress$snapshots[[closest_idx]]
})

# Update grid plot to show current snapshot
output$grid_plot <- renderPlot({
  snapshot <- current_snapshot()

  if (is.null(snapshot)) {
    return(NULL)
  }

  plot_grid(snapshot$grid) +
    labs(
      title = sprintf(
        "Grid State at %d%% Complete (%d/%d walkers)",
        snapshot$pct,
        snapshot$walkers_complete,
        input$n_walkers
      )
    )
})

# Update statistics display
output$current_stats <- renderText({
  snapshot <- current_snapshot()

  if (is.null(snapshot)) {
    return("No data yet - click Run Simulation")
  }

  sprintf(
    "Black Pixels: %d (%.2f%%)\\nElapsed: %.1f seconds",
    snapshot$stats$black_pixels,
    snapshot$stats$black_percentage,
    snapshot$stats$elapsed_secs
  )
})


## Phase 5: Timer Display (Until First Results)
## ---------------------------------------------

# In UI:
uiOutput("status_display")

# In server:
output$status_display <- renderUI({
  if (sim_progress$is_running && length(sim_progress$snapshots) == 0) {
    # Show timer
    div(
      h4("Simulation Running..."),
      p("Waiting for first progress update..."),
      # Use invalidateLater() to update timer
      textOutput("elapsed_timer")
    )
  } else if (length(sim_progress$snapshots) > 0) {
    # Show latest progress
    snapshot <- sim_progress$snapshots[[length(sim_progress$snapshots)]]
    div(
      h4(sprintf("Progress: %d%%", snapshot$pct)),
      p(sprintf("Completed: %d/%d walkers", snapshot$walkers_complete, input$n_walkers))
    )
  } else {
    p("Ready to run simulation")
  }
})

output$elapsed_timer <- renderText({
  invalidateLater(1000)  # Update every second
  sprintf("Elapsed: %.0f seconds", difftime(Sys.time(), sim_start_time, units = "secs"))
})

# =============================================================================
# TESTING STRATEGY
# =============================================================================
#
# 1. Test with small grid (20x20, 10 walkers)
#    - Verify progress updates appear
#    - Check slider shows all milestones (0%, 5%, 10%, ...)
#
# 2. Test with medium grid (100x100, 50 walkers, 4 workers)
#    - Verify non-blocking (UI remains responsive)
#    - Check memory usage (snapshots stored)
#
# 3. Test slider animation
#    - Play button should animate through history
#    - Grid should update smoothly
#
# 4. Test timer display
#    - Shows during initial waiting period
#    - Updates every second
#    - Disappears after first progress update
#
# =============================================================================
# ESTIMATED EFFORT
# =============================================================================
#
# Phase 1 (ExtendedTask): 1 hour
# Phase 2 (Progress callback): 1 hour
# Phase 3 (Storage): 30 minutes
# Phase 4 (Slider UI): 1 hour
# Phase 5 (Timer): 30 minutes
# Testing: 1 hour
#
# Total: ~5 hours
#
# =============================================================================
# DEPENDENCIES
# =============================================================================
#
# - Shiny >= 1.8.0 (for ExtendedTask)
# - promises package
# - future package (if using future-based async)
#
# =============================================================================
# ALTERNATIVE: Simpler Polling Approach
# =============================================================================
#
# If ExtendedTask is not available, use polling:
#
# observe({
#   invalidateLater(1000)  # Poll every second
#
#   if (sim_progress$is_running) {
#     # Check if new snapshot available
#     # Update UI accordingly
#   }
# })
#
# This is simpler but less efficient than ExtendedTask.
#
# =============================================================================
# NEXT STEPS
# =============================================================================
#
# 1. Create development branch
# 2. Implement Phase 1 (ExtendedTask)
# 3. Test non-blocking execution
# 4. Implement Phase 2 (Progress callbacks)
# 5. Test with logging/validation
# 6. Implement Phases 3-5 (UI enhancements)
# 7. Full integration testing
# 8. Create PR and merge
