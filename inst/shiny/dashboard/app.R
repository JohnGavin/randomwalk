# Mount WebAssembly file system from same-origin (avoids CORS issues)
# The pkgdown workflow downloads library.data from releases to docs/wasm/
# This allows the dashboard to load it from the same domain (johngavin.github.io)
webr::mount(
  mountpoint = "/randomwalk-lib",
  source = "/randomwalk/wasm/library.data"
)

# Add mounted library to library paths
.libPaths(c("/randomwalk-lib", .libPaths()))

# Install munsell from webR repository (needed by ggplot2 for plots)
webr::install("munsell")

# Load required packages
library(shiny)

# Load randomwalk from mounted library
library(randomwalk)

# UI
ui <- fluidPage(
  titlePanel("Random Walk Simulation Dashboard"),

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

      actionButton("run_sim", "Run Simulation",
                   class = "btn-primary", width = "100%"),

      actionButton("reset", "Reset Parameters",
                   class = "btn-secondary", width = "100%",
                   style = "margin-top: 10px;")
    ),

    mainPanel(
      width = 9,

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
                 verbatimTextOutput("grid_info"))
      )
    )
  )
)

# Server
server <- function(input, output, session) {

  # Update max walkers based on grid size
  observe({
    max_walkers <- floor(input$grid_size * input$grid_size * 0.3)
    updateSliderInput(session, "n_walkers",
                     max = max_walkers,
                     value = min(input$n_walkers, max_walkers))
  })

  # Reset button
  observeEvent(input$reset, {
    updateSliderInput(session, "grid_size", value = 20)
    updateSliderInput(session, "n_walkers", value = 5)
    updateSelectInput(session, "neighborhood", selected = "4-hood")
    updateSelectInput(session, "boundary", selected = "terminate")
    updateSliderInput(session, "max_steps", value = 10000)
  })

  # Run simulation using package function
  sim_result <- eventReactive(input$run_sim, {
    withProgress(message = 'Running simulation...', {
      result <- randomwalk::run_simulation(
        grid_size = input$grid_size,
        n_walkers = input$n_walkers,
        neighborhood = input$neighborhood,
        boundary = input$boundary,
        max_steps = input$max_steps
      )
      result
    })
  })

  # Grid plot using package function
  output$grid_plot <- renderPlot({
    req(sim_result())
    randomwalk::plot_grid(sim_result())
  })

  # Paths plot using package function
  output$paths_plot <- renderPlot({
    req(sim_result())
    randomwalk::plot_walker_paths(sim_result())
  })

  # Statistics
  output$stats_text <- renderText({
    req(sim_result())
    stats <- sim_result()$statistics
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
    req(sim_result())
    result <- sim_result()
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
    req(sim_result())
    result <- sim_result()

    walker_data <- data.frame(
      Walker = seq_along(result$walker_paths),
      Steps = sapply(result$walker_paths, function(p) nrow(p)),
      Final_X = sapply(result$walker_paths, function(p) p[nrow(p), 1]),
      Final_Y = sapply(result$walker_paths, function(p) p[nrow(p), 2])
    )
    walker_data
  })

  # Grid info
  output$grid_info <- renderText({
    req(sim_result())
    result <- sim_result()
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
}

shinyApp(ui = ui, server = server)
