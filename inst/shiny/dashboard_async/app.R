# Async Random Walk Simulation Dashboard
# This dashboard demonstrates parallel processing capabilities using crew workers

# Mount WebAssembly file system from same-origin (avoids CORS issues)
# The pkgdown workflow downloads library.data from releases to docs/wasm/
# This allows the dashboard to load it from the same domain (johngavin.github.io)
webr::mount(
  mountpoint = "/randomwalk-lib",
  source = "/randomwalk/wasm/library.data"
)

# Add mounted library to library paths
.libPaths(c("/randomwalk-lib", .libPaths()))

# Install ggplot2 dependencies explicitly from webR repository
# Use /tmp for installation since it's writable
# Installing dependencies first ensures they're available when ggplot2 loads
webr::install(c("munsell", "colorspace", "farver", "labeling", "viridisLite",
                 "RColorBrewer", "scales", "tibble", "ggplot2"),
               lib = "/tmp/webr-libs")

# Add the tmp library to the path
.libPaths(c("/tmp/webr-libs", .libPaths()))

# Load required packages
library(shiny)

# Load randomwalk from mounted library
library(randomwalk)

# Define UI
ui <- fluidPage(
  titlePanel("Async Random Walk Simulation Dashboard"),

  sidebarLayout(
    # Sidebar with input controls
    sidebarPanel(
      width = 3,

      h4("Simulation Parameters"),
      p("Configure the random walk simulation parameters below."),

      hr(),

      # ASYNC PARAMETER - Number of workers (EXPANDED RANGE per issue #33)
      sliderInput(
        "workers",
        "Number of Workers:",
        min = 0,
        max = 12,
        value = 2,
        step = 1,
        ticks = FALSE
      ),
      helpText(
        HTML("<b>0 = Sync mode</b> (sequential)<br>",
             "<b>1+ = Async mode</b> (parallel)<br>",
             "More workers may improve performance (0-12)")
      ),

      sliderInput(
        "grid_size",
        "Grid Size:",
        min = 20,
        max = 400,
        value = 100,
        step = 20,
        ticks = FALSE
      ),
      helpText("Size of the square grid (20-400 in steps of 20)"),

      sliderInput(
        "n_walkers",
        "Number of Walkers:",
        min = 1,
        max = 100,  # Will be constrained dynamically to 70% of grid pixels
        value = 6,
        step = 1,
        ticks = FALSE
      ),
      helpText(HTML("Number of simultaneous random walkers<br><em>Max: 70% of grid pixels</em>")),

      selectInput(
        "neighborhood",
        "Neighborhood Type:",
        choices = c(
          "4-neighborhood (N, S, E, W)" = "4-hood",
          "8-neighborhood (incl. diagonals)" = "8-hood"
        ),
        selected = "4-hood"
      ),

      selectInput(
        "boundary",
        "Boundary Behavior:",
        choices = c(
          "Terminate at edge" = "terminate",
          "Wrap around (torus)" = "wrap"
        ),
        selected = "terminate"
      ),

      sliderInput(
        "max_steps",
        "Max Steps per Walker:",
        min = 1000,
        max = 20000,
        value = 10000,
        step = 1000,
        ticks = FALSE
      ),
      helpText("Maximum steps before walker stops (1k-20k)"),

      hr(),

      actionButton(
        "run_sim",
        "Run Simulation",
        class = "btn-primary btn-lg",
        width = "100%",
        icon = icon("play")
      ),

      br(), br(),

      actionButton(
        "reset",
        "Reset to Defaults",
        class = "btn-secondary",
        width = "100%",
        icon = icon("rotate-left")
      ),

      hr(),

      # Status display
      div(
        id = "status_box",
        style = "padding: 10px; border-radius: 5px; background-color: #f8f9fa;",
        h5("Status", style = "margin-top: 0;"),
        p("✅ APP LOADED - UI IS WORKING", style = "color: green; font-weight: bold;"),
        textOutput("status_text")
      )
    ),

    # Main panel with tabbed output
    mainPanel(
      width = 9,

      tabsetPanel(
        id = "output_tabs",
        type = "pills",

        # Performance Tab (NEW for async)
        tabPanel(
          "Performance",
          icon = icon("gauge-high"),
          br(),
          h4("Async Performance Metrics"),
          p("Compare execution time between sync and async modes."),
          tableOutput("perf_table"),
          hr(),
          h5("Execution Mode"),
          p(textOutput("mode_info")),
          hr(),
          h5("Performance Analysis"),
          p(textOutput("perf_analysis"))
        ),

        # Grid State Tab
        tabPanel(
          "Grid State",
          icon = icon("table-cells"),
          br(),
          h4("Final Grid Visualization"),
          p("Black squares represent pixels visited by random walkers."),
          plotOutput("grid_plot", height = "600px"),
          hr(),
          p(class = "text-muted", "Generated using plot_grid() from the randomwalk package")
        ),

        # Walker Paths Tab
        tabPanel(
          "Walker Paths",
          icon = icon("route"),
          br(),
          h4("Individual Walker Trajectories"),
          p("Green squares mark starting positions, red squares show where walkers terminated."),
          plotOutput("paths_plot", height = "600px"),
          hr(),
          p(class = "text-muted", "Generated using plot_walker_paths() from the randomwalk package")
        ),

        # Statistics Tab
        tabPanel(
          "Statistics",
          icon = icon("chart-line"),
          br(),
          h4("Simulation Metrics"),
          tableOutput("stats_table"),
          hr(),
          h5("Coverage Analysis"),
          p(textOutput("coverage_analysis")),
          hr(),
          h5("Walker Summary"),
          tableOutput("walker_summary")
        ),

        # Raw Data Tab
        tabPanel(
          "Raw Data",
          icon = icon("database"),
          br(),
          h4("Detailed Walker Information"),
          p("Complete data for each walker in the simulation."),
          dataTableOutput("walker_data"),
          hr(),
          h4("Grid Information"),
          tableOutput("grid_info")
        ),

        # Debug/Logs Tab
        tabPanel(
          "Debug Logs",
          icon = icon("bug"),
          br(),
          h4("Debug Information"),
          p("Real-time logs to help diagnose issues with the dashboard."),
          hr(),
          h5("Event Log"),
          verbatimTextOutput("debug_log"),
          hr(),
          h5("Current State"),
          verbatimTextOutput("debug_state"),
          hr(),
          actionButton("clear_log", "Clear Log", class = "btn-secondary")
        ),

        # About Tab
        tabPanel(
          "About",
          icon = icon("info-circle"),
          br(),
          h4("About This Async Dashboard"),
          p("This interactive dashboard demonstrates the randomwalk package's async/parallel capabilities using crew workers and WebAssembly."),

          h5("How Async Mode Works"),
          tags$ul(
            tags$li(strong("Sync Mode (workers=0):"), " Walkers processed sequentially"),
            tags$li(strong("Async Mode (workers>0):"), " Walkers processed in parallel by crew workers"),
            tags$li(strong("Static Snapshots:"), " Workers use frozen grid state (no real-time sync)"),
            tags$li(strong("Independent Execution:"), " Each worker processes walkers independently")
          ),

          h5("Expected Performance"),
          tags$ul(
            tags$li("1 worker: Similar to sync mode"),
            tags$li("2 workers: ~1.5x speedup (target)"),
            tags$li("4 workers: ~2-3x speedup (depends on workload)"),
            tags$li("Speedup limited by walker termination times and overhead")
          ),

          h5("Trade-offs"),
          tags$ul(
            tags$li(tags$b("Pro:"), " Faster execution with multiple workers"),
            tags$li(tags$b("Pro:"), " Simple, reliable architecture"),
            tags$li(tags$b("Con:"), " Results may differ from sync mode (acceptable)"),
            tags$li(tags$b("Con:"), " Workers don't see real-time updates from other workers")
          ),

          h5("References"),
          tags$ul(
            tags$li(tags$a(href = "https://github.com/JohnGavin/randomwalk", "randomwalk GitHub Repository")),
            tags$li(tags$a(href = "https://wlandau.github.io/crew/", "crew: A Distributed Worker Launcher")),
            tags$li(tags$a(href = "https://posit-dev.github.io/r-shinylive/", "Shinylive Documentation"))
          )
        )
      )
    )
  )
)

# Define server logic
server <- function(input, output, session) {

  cat("=== SERVER FUNCTION STARTED ===\n")

  # Reactive value to store simulation result
  sim_result <- reactiveVal(NULL)
  cat("✓ sim_result created\n")

  # Reactive value for status messages
  status_msg <- reactiveVal("Ready to run simulation")
  cat("✓ status_msg created\n")

  # Debug log reactive values
  debug_log_entries <- reactiveVal(character(0))
  cat("✓ debug_log_entries created\n")

  # Helper function to add log entry (SIMPLIFIED - no isolate initially)
  add_log <- function(msg) {
    tryCatch({
      timestamp <- format(Sys.time(), "%H:%M:%S")
      new_entry <- paste0("[", timestamp, "] ", msg)
      cat("LOG:", new_entry, "\n")  # Print to R console
      # Try to update reactive value
      current <- debug_log_entries()
      debug_log_entries(c(current, new_entry))
    }, error = function(e) {
      cat("ERROR in add_log:", e$message, "\n")
    })
  }
  cat("✓ add_log function created\n")

  # Log app startup (wrapped in observe to create reactive context)
  observe({
    cat(">> observe() for startup running\n")
    add_log("Dashboard initialized - server is running!")
  })
  cat("✓ Startup observe() registered\n")

  # Dynamic walker constraint (issue #33): Limit to 70% of grid pixels
  observe({
    max_walkers <- floor(0.7 * input$grid_size^2)
    updateSliderInput(
      session,
      "n_walkers",
      max = max_walkers,
      value = min(input$n_walkers, max_walkers)
    )
  })

  cat("✓ observeEvent(run_sim) registered\n")

  # Run simulation when button clicked
  observeEvent(input$run_sim, {
    cat("!!! RUN SIMULATION BUTTON CLICKED !!!\n")
    add_log("=== RUN SIMULATION CLICKED ===")
    add_log(sprintf("Parameters: grid=%d, walkers=%d, workers=%d",
                    input$grid_size, input$n_walkers, input$workers))

    mode_text <- if (input$workers == 0) "sync" else sprintf("async (%d workers)", input$workers)
    status_msg(sprintf("Running simulation in %s mode...", mode_text))
    add_log(sprintf("Mode: %s", mode_text))

    tryCatch({
      # Validate inputs
      if (input$n_walkers > (0.6 * input$grid_size^2)) {
        add_log("ERROR: Too many walkers for grid size")
        showNotification(
          "Too many walkers for grid size. Maximum is 60% of grid cells.",
          type = "warning",
          duration = 5
        )
        status_msg("Error: Too many walkers for grid size")
        return(NULL)
      }

      add_log("Validation passed, starting simulation...")

      # Run the simulation using randomwalk package with workers parameter
      add_log("Calling randomwalk::run_simulation()...")
      result <- randomwalk::run_simulation(
        grid_size = input$grid_size,
        n_walkers = input$n_walkers,
        workers = input$workers,        # ASYNC PARAMETER
        neighborhood = input$neighborhood,
        boundary = input$boundary,
        max_steps = input$max_steps,
        verbose = FALSE
      )

      add_log("Simulation completed successfully")
      add_log(sprintf("Total steps: %d, Black pixels: %d (%.1f%%)",
                      result$statistics$total_steps,
                      result$statistics$black_pixels,
                      result$statistics$black_percentage))

      # Store result
      sim_result(result)

      # Update status
      status_msg(sprintf(
        "Simulation complete (%s mode)! %d steps, %.1f%% coverage in %.2fs",
        mode_text,
        result$statistics$total_steps,
        result$statistics$black_percentage,
        result$statistics$elapsed_time_secs
      ))

      # Show success notification
      showNotification(
        sprintf("Simulation completed in %.2f seconds!", result$statistics$elapsed_time_secs),
        type = "message",
        duration = 3
      )

    }, error = function(e) {
      add_log(sprintf("ERROR in simulation: %s", e$message))
      add_log(sprintf("Error traceback: %s", paste(capture.output(traceback()), collapse = "\n")))
      status_msg(paste("Error:", e$message))
      showNotification(
        paste("Simulation failed:", e$message),
        type = "error",
        duration = 10
      )
    })
  })

  cat("✓ observeEvent(reset) registered\n")

  # Reset parameters (UPDATED defaults per issue #33)
  observeEvent(input$reset, {
    cat("!!! RESET BUTTON CLICKED !!!\n")
    add_log("=== RESET BUTTON CLICKED ===")
    add_log("Resetting parameters to defaults: workers=2, grid=100, walkers=6")

    updateSliderInput(session, "workers", value = 2)
    updateSliderInput(session, "grid_size", value = 100)  # Changed from 20
    updateSliderInput(session, "n_walkers", value = 6)
    updateSelectInput(session, "neighborhood", selected = "4-hood")
    updateSelectInput(session, "boundary", selected = "terminate")
    updateSliderInput(session, "max_steps", value = 10000)
    status_msg("Parameters reset to defaults")

    add_log("Parameters reset complete")

    showNotification(
      "Parameters reset to default values",
      type = "message",
      duration = 2
    )
  })

  # Render status text
  output$status_text <- renderText({
    status_msg()
  })

  # Debug log output
  output$debug_log <- renderText({
    log_entries <- debug_log_entries()
    if (length(log_entries) == 0) {
      return("No log entries yet. Click 'Run Simulation' or 'Reset to Defaults' to see logs.")
    }
    paste(log_entries, collapse = "\n")
  })

  # Debug state output
  output$debug_state <- renderText({
    paste(
      "=== CURRENT PARAMETERS ===",
      sprintf("Workers: %d", input$workers),
      sprintf("Grid Size: %d x %d", input$grid_size, input$grid_size),
      sprintf("Walkers: %d", input$n_walkers),
      sprintf("Neighborhood: %s", input$neighborhood),
      sprintf("Boundary: %s", input$boundary),
      sprintf("Max Steps: %d", input$max_steps),
      "",
      "=== SIMULATION STATUS ===",
      sprintf("Status: %s", status_msg()),
      sprintf("Result stored: %s", if (is.null(sim_result())) "No" else "Yes"),
      "",
      "=== ENVIRONMENT INFO ===",
      sprintf("R version: %s", R.version.string),
      sprintf("Running in WebR: %s", if (exists("webr")) "Yes" else "Unknown"),
      sprintf("randomwalk package loaded: %s", "randomwalk" %in% loadedNamespaces()),
      sprintf("Session start: %s", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
      sep = "\n"
    )
  })

  # Clear log button
  observeEvent(input$clear_log, {
    add_log("Log cleared by user")
    debug_log_entries(character(0))
  })

  # ASYNC PERFORMANCE TABLE
  output$perf_table <- renderTable({
    req(sim_result())
    stats <- sim_result()$statistics
    params <- sim_result()$parameters

    data.frame(
      Metric = c(
        "Execution Mode",
        "Number of Workers",
        "Elapsed Time",
        "Total Steps",
        "Steps per Second",
        "Black Pixels Created"
      ),
      Value = c(
        ifelse(params$workers == 0, "Sync (Sequential)", sprintf("Async (Parallel - %d workers)", params$workers)),
        params$workers,
        sprintf("%.3f seconds", stats$elapsed_time_secs),
        format(stats$total_steps, big.mark = ","),
        format(round(stats$total_steps / stats$elapsed_time_secs), big.mark = ","),
        stats$black_pixels
      )
    )
  }, striped = TRUE, hover = TRUE, bordered = TRUE)

  # Mode information
  output$mode_info <- renderText({
    req(sim_result())
    params <- sim_result()$parameters

    if (params$workers == 0) {
      "Running in SYNC mode: Walkers are processed sequentially in round-robin fashion. This produces deterministic, reproducible results."
    } else {
      sprintf(
        "Running in ASYNC mode with %d worker%s: Walkers are distributed across parallel workers. Workers use static grid snapshots, so results may differ from sync mode. This is expected behavior.",
        params$workers,
        ifelse(params$workers == 1, "", "s")
      )
    }
  })

  # Performance analysis
  output$perf_analysis <- renderText({
    req(sim_result())
    stats <- sim_result()$statistics
    params <- sim_result()$parameters

    if (params$workers == 0) {
      sprintf(
        "Sync mode completed %d walkers in %.3f seconds (%.1f walkers/second). To test async performance, increase the number of workers and re-run.",
        stats$total_walkers,
        stats$elapsed_time_secs,
        stats$total_walkers / stats$elapsed_time_secs
      )
    } else {
      # Estimate theoretical speedup (actual depends on walker termination patterns)
      theoretical_speedup <- min(params$workers, stats$total_walkers)

      sprintf(
        "Async mode with %d workers completed %d walkers in %.3f seconds. Theoretical maximum speedup is %.1fx (limited by %d workers and %d walkers). Actual speedup depends on walker termination patterns and parallelization overhead. Try comparing with sync mode (workers=0) to measure actual speedup.",
        params$workers,
        stats$total_walkers,
        stats$elapsed_time_secs,
        theoretical_speedup,
        params$workers,
        stats$total_walkers
      )
    }
  })

  # Render grid plot
  output$grid_plot <- renderPlot({
    req(sim_result())
    randomwalk::plot_grid(sim_result())
  })

  # Render walker paths plot
  output$paths_plot <- renderPlot({
    req(sim_result())
    randomwalk::plot_walker_paths(sim_result())
  })

  # Render statistics table
  output$stats_table <- renderTable({
    req(sim_result())
    stats <- sim_result()$statistics

    data.frame(
      Metric = c(
        "Total Steps",
        "Final Black Pixels",
        "Final Black Percentage",
        "Grid Size",
        "Number of Walkers",
        "Elapsed Time (sec)"
      ),
      Value = c(
        format(stats$total_steps, big.mark = ","),
        format(stats$black_pixels, big.mark = ","),
        sprintf("%.2f%%", stats$black_percentage),
        sprintf("%d × %d", stats$grid_size, stats$grid_size),
        stats$total_walkers,
        sprintf("%.3f", stats$elapsed_time_secs)
      )
    )
  }, striped = TRUE, hover = TRUE, bordered = TRUE)

  # Coverage analysis text
  output$coverage_analysis <- renderText({
    req(sim_result())
    stats <- sim_result()$statistics

    total_cells <- stats$grid_size^2
    black_cells <- stats$black_pixels
    coverage_pct <- stats$black_percentage

    sprintf(
      "The simulation covered %d out of %d grid cells (%.2f%%). On average, %.1f steps were taken per black pixel created.",
      black_cells,
      total_cells,
      coverage_pct,
      stats$total_steps / black_cells
    )
  })

  # Walker summary table
  output$walker_summary <- renderTable({
    req(sim_result())
    walkers <- sim_result()$walkers

    data.frame(
      Statistic = c(
        "Total Walkers",
        "Average Steps",
        "Min Steps",
        "Max Steps",
        "Completed Walkers"
      ),
      Value = c(
        length(walkers),
        sprintf("%.1f", mean(sapply(walkers, function(w) w$steps))),
        min(sapply(walkers, function(w) w$steps)),
        max(sapply(walkers, function(w) w$steps)),
        sum(sapply(walkers, function(w) !w$active))
      )
    )
  }, striped = TRUE, hover = TRUE, bordered = TRUE)

  # Walker data table (FIXED End_X/End_Y extraction per issue #33)
  output$walker_data <- renderDataTable({
    req(sim_result())
    walkers <- sim_result()$walkers

    # Format for display
    walkers_display <- data.frame(
      Walker = sapply(walkers, function(w) w$id),
      Steps = sapply(walkers, function(w) w$steps),
      Start_X = sapply(walkers, function(w) w$path[[1]][1]),
      Start_Y = sapply(walkers, function(w) w$path[[1]][2]),
      # FIX: Extract last position correctly from path matrix
      End_X = sapply(walkers, function(w) {
        path <- w$path[[1]]
        if (is.matrix(path)) path[nrow(path), 1] else path[length(path)]
      }),
      End_Y = sapply(walkers, function(w) {
        path <- w$path[[1]]
        if (is.matrix(path)) path[nrow(path), 2] else path[length(path)]
      }),
      Active = factor(sapply(walkers, function(w) ifelse(w$active, "Yes", "No")),
                     levels = c("Yes", "No")),
      Reason = factor(sapply(walkers, function(w) w$termination_reason))
    )

    walkers_display
  },
  filter = 'top',  # IMPROVED: Built-in filters at top per issue #33
  options = list(
    pageLength = 10,
    scrollX = TRUE,
    autoWidth = TRUE,
    columnDefs = list(
      list(className = 'dt-center', targets = c(0, 1, 2, 3, 4, 5, 6, 7))
    )
  ))

  # Grid info table
  output$grid_info <- renderTable({
    req(sim_result())
    stats <- sim_result()$statistics
    params <- sim_result()$parameters

    data.frame(
      Property = c(
        "Grid Dimensions",
        "Total Cells",
        "Black Cells",
        "White Cells",
        "Neighborhood Type",
        "Boundary Behavior",
        "Execution Mode"
      ),
      Value = c(
        sprintf("%d × %d", stats$grid_size, stats$grid_size),
        format(stats$grid_size^2, big.mark = ","),
        format(stats$black_pixels, big.mark = ","),
        format(stats$grid_size^2 - stats$black_pixels, big.mark = ","),
        input$neighborhood,
        input$boundary,
        ifelse(params$workers == 0, "Sync", sprintf("Async (%d workers)", params$workers))
      )
    )
  }, striped = TRUE, hover = TRUE, bordered = TRUE)
}

# Run the application
shinyApp(ui = ui, server = server)
