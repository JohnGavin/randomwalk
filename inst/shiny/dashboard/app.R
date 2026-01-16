# Install randomwalk from GitHub Pages webR repository
# This approach is more reliable than webr::mount() which gets stripped during pkgdown deployment
# See: https://docs.r-wasm.org/webr/latest/packages.html
webr::install(
  "randomwalk",
  repos = "https://johngavin.github.io/randomwalk/"
)

# Load required packages
library(shiny)
library(randomwalk)

# UI
ui <- fluidPage(
  titlePanel("Random Walk Simulation Dashboard"),

  # Custom CSS for timer and progress display
  tags$head(
    tags$style(HTML("
      .progress-timer {
        font-size: 24px;
        font-weight: bold;
        color: #337ab7;
        text-align: center;
        padding: 20px;
        background: #f5f5f5;
        border-radius: 8px;
        margin-bottom: 15px;
      }
      .snapshot-info {
        font-size: 14px;
        color: #666;
        text-align: center;
        margin-bottom: 10px;
      }
      .btn-primary { margin-bottom: 10px; }
    "))
  ),

  sidebarLayout(
    sidebarPanel(
      width = 3,
      h4("Simulation Parameters"),

      sliderInput("grid_size", "Grid Size:",
                  min = 5, max = 50, value = 20, step = 1),

      sliderInput("n_walkers", "Number of Walkers:",
                  min = 1, max = 20, value = 5, step = 1),

      selectInput("neighborhood", "Neighborhood Type:",
                  choices = c("4-hood" = "4-hood", "8-hood" = "8-hood"),
                  selected = "4-hood"),

      selectInput("boundary", "Boundary Behavior:",
                  choices = c("Terminate" = "terminate", "Wrap" = "wrap"),
                  selected = "terminate"),

      sliderInput("max_steps", "Max Steps:",
                  min = 1000, max = 20000, value = 10000, step = 1000),

      hr(),

      # Snapshot interval control
      sliderInput("snapshot_pct", "Snapshot every X% of walkers:",
                  min = 10, max = 50, value = 25, step = 5),

      hr(),

      actionButton("run_sim", "Run Simulation",
                   class = "btn-primary", width = "100%"),

      actionButton("reset", "Reset Parameters",
                   class = "btn-secondary", width = "100%",
                   style = "margin-top: 10px;")
    ),

    mainPanel(
      width = 9,

      # Progress timer display (shown during simulation)
      conditionalPanel(
        condition = "output.is_running",
        div(class = "progress-timer",
          textOutput("timer_display", inline = TRUE)
        )
      ),

      # Snapshot slider (shown after simulation with multiple snapshots)
      conditionalPanel(
        condition = "output.has_snapshots",
        wellPanel(
          div(class = "snapshot-info",
            textOutput("snapshot_info", inline = TRUE)
          ),
          sliderInput("snapshot_slider", "View Historical Snapshot:",
                      min = 1, max = 1, value = 1, step = 1, width = "100%"),
          div(style = "text-align: center;",
            actionButton("play_snapshots", "Play", class = "btn-sm"),
            actionButton("stop_snapshots", "Stop", class = "btn-sm")
          )
        )
      ),

      tabsetPanel(
        id = "output_tabs",

        tabPanel("Grid State",
                 br(),
                 plotOutput("grid_plot", height = "600px")),

        tabPanel("Walker Paths",
                 br(),
                 plotOutput("paths_plot", height = "600px")),

        tabPanel("Statistics",
                 br(),
                 h4("Simulation Statistics"),
                 verbatimTextOutput("stats_text"),
                 hr(),
                 h4("Parameters Used"),
                 tableOutput("params_table")),

        tabPanel("Raw Data",
                 br(),
                 h4("Walker Data"),
                 tableOutput("walker_table"),
                 hr(),
                 h4("Grid Information"),
                 verbatimTextOutput("grid_info")),

        tabPanel("Progress History",
                 br(),
                 h4("Coverage Over Time"),
                 plotOutput("progress_plot", height = "400px"),
                 hr(),
                 tableOutput("snapshots_table"))
      )
    )
  )
)

# Server
server <- function(input, output, session) {

  # Reactive values for state management
  rv <- reactiveValues(
    is_running = FALSE,
    start_time = NULL,
    elapsed_time = 0,
    snapshots = list(),
    current_snapshot = 1,
    final_result = NULL,
    playing = FALSE
  )

  # Update max walkers based on grid size
  observe({
    max_walkers <- floor(input$grid_size * input$grid_size * 0.3)
    updateSliderInput(session, "n_walkers",
                     max = max_walkers,
                     value = min(input$n_walkers, max_walkers))
  })

  # Timer update (every second when running)
  observe({
    invalidateLater(1000, session)
    if (rv$is_running && !is.null(rv$start_time)) {
      rv$elapsed_time <- as.numeric(difftime(Sys.time(), rv$start_time, units = "secs"))
    }
  })

  # Reset button
  observeEvent(input$reset, {
    updateSliderInput(session, "grid_size", value = 20)
    updateSliderInput(session, "n_walkers", value = 5)
    updateSelectInput(session, "neighborhood", selected = "4-hood")
    updateSelectInput(session, "boundary", selected = "terminate")
    updateSliderInput(session, "max_steps", value = 10000)
    updateSliderInput(session, "snapshot_pct", value = 25)
    rv$snapshots <- list()
    rv$final_result <- NULL
    rv$current_snapshot <- 1
  })

  # Run simulation with progressive snapshots
  observeEvent(input$run_sim, {
    # Start timer
    rv$is_running <- TRUE
    rv$start_time <- Sys.time()
    rv$elapsed_time <- 0
    rv$snapshots <- list()

    # Calculate snapshot intervals
    n_walkers <- input$n_walkers
    snapshot_interval <- max(1, floor(n_walkers * input$snapshot_pct / 100))
    snapshot_points <- seq(snapshot_interval, n_walkers, by = snapshot_interval)
    if (!(n_walkers %in% snapshot_points)) {
      snapshot_points <- c(snapshot_points, n_walkers)
    }

    # Initialize grid
    grid_size <- input$grid_size
    grid <- matrix(FALSE, nrow = grid_size, ncol = grid_size)
    all_walker_paths <- list()

    withProgress(message = 'Running simulation...', value = 0, {
      for (i in 1:n_walkers) {
        # Run single walker
        walker_result <- randomwalk::simulate_single_walker(
          grid = grid,
          grid_size = grid_size,
          neighborhood = input$neighborhood,
          boundary = input$boundary,
          max_steps = input$max_steps
        )

        # Update grid with walker path
        for (j in 1:nrow(walker_result$path)) {
          pos <- walker_result$path[j, ]
          if (pos[1] >= 1 && pos[1] <= grid_size &&
              pos[2] >= 1 && pos[2] <= grid_size) {
            grid[pos[1], pos[2]] <- TRUE
          }
        }

        all_walker_paths[[i]] <- walker_result

        # Capture snapshot at interval
        if (i %in% snapshot_points) {
          snapshot <- list(
            walker_count = i,
            percentage = round(100 * i / n_walkers),
            grid = grid,
            black_pixels = sum(grid),
            black_percentage = 100 * sum(grid) / (grid_size * grid_size),
            timestamp = Sys.time(),
            walker_paths = all_walker_paths
          )
          rv$snapshots <- c(rv$snapshots, list(snapshot))

          # Update slider max
          updateSliderInput(session, "snapshot_slider",
                           max = length(rv$snapshots),
                           value = length(rv$snapshots))
        }

        # Update progress
        incProgress(1/n_walkers, detail = sprintf("Walker %d/%d", i, n_walkers))
      }
    })

    # Create final result object
    rv$final_result <- list(
      grid = grid,
      walker_paths = all_walker_paths,
      parameters = list(
        grid_size = grid_size,
        n_walkers = n_walkers,
        neighborhood = input$neighborhood,
        boundary = input$boundary,
        max_steps = input$max_steps
      ),
      statistics = list(
        grid_size = grid_size,
        black_pixels = sum(grid),
        black_percentage = 100 * sum(grid) / (grid_size * grid_size),
        total_walkers = n_walkers,
        completed_walkers = length(all_walker_paths),
        total_steps = sum(sapply(all_walker_paths, function(w) nrow(w$path)))
      )
    )

    # Stop timer
    rv$is_running <- FALSE
    rv$current_snapshot <- length(rv$snapshots)
  })

  # Snapshot slider change
  observeEvent(input$snapshot_slider, {
    rv$current_snapshot <- input$snapshot_slider
  })

  # Play button - animate through snapshots
  observeEvent(input$play_snapshots, {
    rv$playing <- TRUE
    rv$current_snapshot <- 1
  })

  # Stop button
  observeEvent(input$stop_snapshots, {
    rv$playing <- FALSE
  })

  # Auto-advance when playing
  observe({
    if (rv$playing && length(rv$snapshots) > 0) {
      invalidateLater(500, session)  # 500ms between frames
      isolate({
        if (rv$current_snapshot < length(rv$snapshots)) {
          rv$current_snapshot <- rv$current_snapshot + 1
          updateSliderInput(session, "snapshot_slider", value = rv$current_snapshot)
        } else {
          rv$playing <- FALSE
        }
      })
    }
  })

  # Output: is_running (for conditional panel)
  output$is_running <- reactive({
    rv$is_running
  })
  outputOptions(output, "is_running", suspendWhenHidden = FALSE)

  # Output: has_snapshots (for conditional panel)
  output$has_snapshots <- reactive({
    length(rv$snapshots) > 1
  })
  outputOptions(output, "has_snapshots", suspendWhenHidden = FALSE)

  # Timer display
  output$timer_display <- renderText({
    if (rv$is_running) {
      sprintf("Running... %.1f seconds", rv$elapsed_time)
    } else {
      ""
    }
  })

  # Snapshot info
  output$snapshot_info <- renderText({
    if (length(rv$snapshots) > 0 && rv$current_snapshot <= length(rv$snapshots)) {
      snap <- rv$snapshots[[rv$current_snapshot]]
      sprintf("Snapshot %d/%d: %d walkers (%d%%) - Coverage: %.1f%%",
              rv$current_snapshot, length(rv$snapshots),
              snap$walker_count, snap$percentage, snap$black_percentage)
    } else {
      ""
    }
  })

  # Get current display result (either snapshot or final)
  current_result <- reactive({
    if (length(rv$snapshots) > 0 && rv$current_snapshot <= length(rv$snapshots)) {
      snap <- rv$snapshots[[rv$current_snapshot]]
      # Create result object from snapshot
      list(
        grid = snap$grid,
        walker_paths = snap$walker_paths,
        parameters = rv$final_result$parameters,
        statistics = list(
          grid_size = nrow(snap$grid),
          black_pixels = snap$black_pixels,
          black_percentage = snap$black_percentage,
          total_walkers = snap$walker_count,
          completed_walkers = snap$walker_count,
          total_steps = sum(sapply(snap$walker_paths, function(w) nrow(w$path)))
        )
      )
    } else {
      rv$final_result
    }
  })

  # Grid plot using current snapshot/result
  output$grid_plot <- renderPlot({
    result <- current_result()
    req(result)
    randomwalk::plot_grid(result)
  })

  # Paths plot using current snapshot/result
  output$paths_plot <- renderPlot({
    result <- current_result()
    req(result)
    randomwalk::plot_walker_paths(result)
  })

  # Statistics
  output$stats_text <- renderText({
    result <- current_result()
    req(result)
    stats <- result$statistics
    paste(
      sprintf("Black Pixels: %d (%.2f%%)",
              stats$black_pixels, stats$black_percentage),
      sprintf("Total Walkers: %d", stats$total_walkers),
      sprintf("Completed Walkers: %d", stats$completed_walkers),
      sprintf("Total Steps: %d", stats$total_steps),
      sep = "\n"
    )
  })

  # Parameters table
  output$params_table <- renderTable({
    result <- current_result()
    req(result)
    params <- result$parameters
    data.frame(
      Parameter = c("Grid Size", "Walkers", "Neighborhood", "Boundary", "Max Steps"),
      Value = c(
        params$grid_size,
        params$n_walkers,
        params$neighborhood,
        params$boundary,
        params$max_steps
      )
    )
  })

  # Walker table
  output$walker_table <- renderTable({
    result <- current_result()
    req(result)

    walker_data <- data.frame(
      Walker = seq_along(result$walker_paths),
      Steps = sapply(result$walker_paths, function(p) nrow(p$path)),
      Final_X = sapply(result$walker_paths, function(p) p$path[nrow(p$path), 1]),
      Final_Y = sapply(result$walker_paths, function(p) p$path[nrow(p$path), 2])
    )
    walker_data
  })

  # Grid info
  output$grid_info <- renderText({
    result <- current_result()
    req(result)
    stats <- result$statistics
    grid_size <- stats$grid_size

    paste(
      sprintf("Grid dimensions: %d x %d", grid_size, grid_size),
      sprintf("Total pixels: %d", grid_size * grid_size),
      sprintf("Black pixels: %d (%.2f%%)",
              stats$black_pixels, stats$black_percentage),
      sprintf("White pixels: %d",
              grid_size * grid_size - stats$black_pixels),
      sep = "\n"
    )
  })

  # Progress plot - coverage over time
  output$progress_plot <- renderPlot({
    req(length(rv$snapshots) > 0)

    progress_data <- data.frame(
      walker_pct = sapply(rv$snapshots, function(s) s$percentage),
      coverage_pct = sapply(rv$snapshots, function(s) s$black_percentage)
    )

    plot(progress_data$walker_pct, progress_data$coverage_pct,
         type = "b", pch = 19, col = "steelblue",
         xlab = "Walkers Completed (%)",
         ylab = "Grid Coverage (%)",
         main = "Coverage Progress During Simulation",
         xlim = c(0, 100),
         ylim = c(0, max(progress_data$coverage_pct) * 1.1))

    # Highlight current snapshot
    if (rv$current_snapshot <= nrow(progress_data)) {
      points(progress_data$walker_pct[rv$current_snapshot],
             progress_data$coverage_pct[rv$current_snapshot],
             pch = 19, col = "red", cex = 2)
    }

    grid()
  })

  # Snapshots summary table
  output$snapshots_table <- renderTable({
    req(length(rv$snapshots) > 0)

    data.frame(
      Snapshot = seq_along(rv$snapshots),
      Walkers = sapply(rv$snapshots, function(s) s$walker_count),
      `Walkers %` = sapply(rv$snapshots, function(s) s$percentage),
      `Black Pixels` = sapply(rv$snapshots, function(s) s$black_pixels),
      `Coverage %` = sapply(rv$snapshots, function(s) round(s$black_percentage, 2))
    )
  })
}

shinyApp(ui = ui, server = server)
