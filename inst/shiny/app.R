## app.R for shinylive dashboard

library(shiny)
library(ggplot2)
library(randomwalk)

# Define UI
ui <- fluidPage(
  titlePanel("Random Walk Simulation"),
  sidebarLayout(
    sidebarPanel(
      h4("Simulation Controls"),
      sliderInput("grid_size", "Grid Size", min = 10, max = 100, value = 20, step = 10),
      sliderInput("n_walkers", "Number of Walkers", min = 1, max = 50, value = 10),
      selectInput("neighborhood", "Neighborhood", choices = c("4-hood", "8-hood"), selected = "4-hood"),
      selectInput("boundary", "Boundary", choices = c("terminate", "wrap"), selected = "terminate"),
      sliderInput("workers", "Number of Workers", min = 0, max = 16, value = 2),
      actionButton("start_sim", "Start Simulation"),
      actionButton("stop_sim", "Stop Simulation")
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Grid", plotOutput("grid_plot", height = "600px")),
        tabPanel("Statistics", verbatimTextOutput("stats_output")),
        tabPanel("About", includeMarkdown("about.md"))
      )
    )
  )
)

# Define server logic
server <- function(input, output, session) {

  # Reactive values to store simulation state
  sim_data <- reactiveValues(
    grid = NULL,
    stats = NULL,
    running = FALSE
  )

  # Start simulation
  observeEvent(input$start_sim, {
    sim_data$running <- TRUE
    # In a real shinylive app, we would run the simulation here.
    # For this placeholder, we'll just generate a static grid.
    sim_data$grid <- randomwalk::initialize_grid(input$grid_size)
    sim_data$stats <- "Simulation started..."
  })

  # Stop simulation
  observeEvent(input$stop_sim, {
    sim_data$running <- FALSE
    sim_data$stats <- "Simulation stopped."
  })

  # Render the grid plot
  output$grid_plot <- renderPlot({
    if (!is.null(sim_data$grid)) {
      plot_grid(list(grid = sim_data$grid))
    }
  })

  # Render the statistics
  output$stats_output <- renderText({
    sim_data$stats
  })

}

# Create Shiny app object
shinyApp(ui = ui, server = server)
