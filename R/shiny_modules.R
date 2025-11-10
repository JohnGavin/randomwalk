#' Simulation Input Module UI
#'
#' Creates the UI for simulation input parameters.
#'
#' @param id Character string. Module namespace ID.
#'
#' @return A shiny tagList containing the input UI elements.
#'
#' @export
sim_input_ui <- function(id) {
  ns <- shiny::NS(id)

  shiny::tagList(
    shiny::wellPanel(
      shiny::h4("Simulation Parameters"),

      shiny::sliderInput(
        ns("grid_size"),
        "Grid Size:",
        min = 3,
        max = 100,
        value = 20,
        step = 1
      ),

      shiny::sliderInput(
        ns("n_walkers"),
        "Number of Walkers:",
        min = 1,
        max = 10,
        value = 5,
        step = 1
      ),

      shiny::radioButtons(
        ns("neighborhood"),
        "Neighborhood Type:",
        choices = c("4-hood" = "4-hood", "8-hood" = "8-hood"),
        selected = "4-hood"
      ),

      shiny::radioButtons(
        ns("boundary"),
        "Boundary Behavior:",
        choices = c("Terminate" = "terminate", "Wrap" = "wrap"),
        selected = "terminate"
      ),

      shiny::numericInput(
        ns("max_steps"),
        "Max Steps per Walker:",
        value = 10000,
        min = 100,
        max = 100000,
        step = 1000
      ),

      shiny::checkboxInput(
        ns("verbose"),
        "Verbose logging",
        value = FALSE
      ),

      shiny::hr(),

      shiny::actionButton(
        ns("run"),
        "Run Simulation",
        class = "btn-primary btn-lg btn-block"
      ),

      shiny::actionButton(
        ns("reset"),
        "Reset Parameters",
        class = "btn-secondary btn-block"
      )
    )
  )
}


#' Simulation Input Module Server
#'
#' Server logic for handling simulation input parameters and validation.
#'
#' @param id Character string. Module namespace ID.
#'
#' @return A reactive list containing:
#'   \describe{
#'     \item{params}{Reactive list of validated simulation parameters}
#'     \item{run_trigger}{Reactive trigger for simulation execution}
#'   }
#'
#' @export
sim_input_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {

    # Reactive to update max walkers based on grid size
    shiny::observe({
      max_walkers <- floor(input$grid_size * input$grid_size * 0.6)
      shiny::updateSliderInput(
        session,
        "n_walkers",
        max = max_walkers,
        value = min(input$n_walkers, max_walkers)
      )
    })

    # Reset button
    shiny::observeEvent(input$reset, {
      shiny::updateSliderInput(session, "grid_size", value = 20)
      shiny::updateSliderInput(session, "n_walkers", value = 5)
      shiny::updateRadioButtons(session, "neighborhood", selected = "4-hood")
      shiny::updateRadioButtons(session, "boundary", selected = "terminate")
      shiny::updateNumericInput(session, "max_steps", value = 10000)
      shiny::updateCheckboxInput(session, "verbose", value = FALSE)
    })

    # Return reactive values
    list(
      params = shiny::reactive({
        list(
          grid_size = input$grid_size,
          n_walkers = input$n_walkers,
          neighborhood = input$neighborhood,
          boundary = input$boundary,
          max_steps = input$max_steps,
          verbose = input$verbose
        )
      }),
      run_trigger = shiny::reactive(input$run)
    )
  })
}


#' Simulation Output Module UI
#'
#' Creates the UI for displaying simulation results across multiple tabs.
#'
#' @param id Character string. Module namespace ID.
#'
#' @return A shiny tagList containing the output UI elements.
#'
#' @export
sim_output_ui <- function(id) {
  ns <- shiny::NS(id)

  shiny::tabsetPanel(
    id = ns("tabs"),
    type = "tabs",

    shiny::tabPanel(
      "Grid State",
      shiny::plotOutput(ns("grid_plot"), height = "600px")
    ),

    shiny::tabPanel(
      "Walker Paths",
      shiny::plotOutput(ns("paths_plot"), height = "600px")
    ),

    shiny::tabPanel(
      "Statistics",
      shiny::h4("Simulation Statistics"),
      shiny::verbatimTextOutput(ns("stats_text")),
      shiny::hr(),
      shiny::h5("Parameters Used"),
      shiny::tableOutput(ns("params_table"))
    ),

    shiny::tabPanel(
      "Raw Data",
      shiny::h4("Walker Summary"),
      shiny::tableOutput(ns("walker_table")),
      shiny::hr(),
      shiny::h5("Grid Dimensions"),
      shiny::verbatimTextOutput(ns("grid_info"))
    )
  )
}


#' Simulation Output Module Server
#'
#' Server logic for displaying simulation results.
#'
#' @param id Character string. Module namespace ID.
#' @param sim_result Reactive expression containing simulation result from run_simulation().
#'
#' @return NULL (called for side effects).
#'
#' @export
sim_output_server <- function(id, sim_result) {
  shiny::moduleServer(id, function(input, output, session) {

    # Grid plot
    output$grid_plot <- shiny::renderPlot({
      shiny::req(sim_result())
      result <- sim_result()

      # Use the plot_grid function which returns a ggplot2 object
      plot_grid(result)
    })

    # Walker paths plot
    output$paths_plot <- shiny::renderPlot({
      shiny::req(sim_result())
      result <- sim_result()

      # Use base R plotting function
      plot_walker_paths(result)
    })

    # Statistics text
    output$stats_text <- shiny::renderPrint({
      shiny::req(sim_result())
      result <- sim_result()
      cat(format_statistics(result$statistics), sep = "\n")
    })

    # Parameters table
    output$params_table <- shiny::renderTable({
      shiny::req(sim_result())
      result <- sim_result()

      params_df <- data.frame(
        Parameter = c("Grid Size", "Number of Walkers", "Neighborhood",
                      "Boundary", "Max Steps"),
        Value = c(
          result$parameters$grid_size,
          result$parameters$n_walkers,
          result$parameters$neighborhood,
          result$parameters$boundary,
          result$parameters$max_steps
        )
      )

      params_df
    }, striped = TRUE, hover = TRUE, bordered = TRUE)

    # Walker summary table
    output$walker_table <- shiny::renderTable({
      shiny::req(sim_result())
      result <- sim_result()

      walker_df <- data.frame(
        Walker_ID = sapply(result$walkers, function(w) w$id),
        Steps = sapply(result$walkers, function(w) w$steps),
        Final_X = sapply(result$walkers, function(w) w$pos[1]),
        Final_Y = sapply(result$walkers, function(w) w$pos[2]),
        Termination_Reason = sapply(result$walkers, function(w) w$termination_reason),
        Active = sapply(result$walkers, function(w) w$active)
      )

      walker_df
    }, striped = TRUE, hover = TRUE, bordered = TRUE)

    # Grid info
    output$grid_info <- shiny::renderPrint({
      shiny::req(sim_result())
      result <- sim_result()

      cat("Grid Dimensions:", nrow(result$grid), "x", ncol(result$grid), "\n")
      cat("Black Pixels:", result$statistics$black_pixels, "\n")
      cat("Black Percentage:", sprintf("%.2f%%", result$statistics$black_percentage), "\n")
      cat("Total Grid Cells:", nrow(result$grid) * ncol(result$grid), "\n")
    })

  })
}


#' Run Shiny Dashboard App
#'
#' Launches the interactive Shiny dashboard for random walk simulations.
#' This is a convenience wrapper that combines the input and output modules
#' into a complete application.
#'
#' @param ... Additional arguments passed to \code{shiny::shinyApp()}.
#'
#' @return A Shiny app object.
#'
#' @examples
#' \dontrun{
#' # Launch the dashboard
#' run_dashboard()
#' }
#'
#' @export
run_dashboard <- function(...) {

  ui <- shiny::fluidPage(

    # Application title
    shiny::titlePanel("Random Walk Simulation Dashboard"),

    # Sidebar layout
    shiny::sidebarLayout(

      # Sidebar panel for inputs
      shiny::sidebarPanel(
        width = 3,
        sim_input_ui("inputs")
      ),

      # Main panel for outputs
      shiny::mainPanel(
        width = 9,

        # Status message
        shiny::uiOutput("status"),

        # Progress indicator
        shiny::conditionalPanel(
          condition = "($('html').hasClass('shiny-busy'))",
          shiny::div(
            shiny::h4("Running simulation..."),
            shiny::tags$div(class = "progress",
                           shiny::tags$div(class = "progress-bar progress-bar-striped active",
                                          role = "progressbar",
                                          style = "width: 100%"))
          )
        ),

        # Output display
        sim_output_ui("outputs")
      )
    )
  )

  server <- function(input, output, session) {

    # Call input module
    inputs <- sim_input_server("inputs")

    # Reactive to run simulation
    sim_result <- shiny::eventReactive(inputs$run_trigger(), {
      # Show notification
      shiny::showNotification(
        "Starting simulation...",
        duration = 2,
        type = "message"
      )

      # Get parameters
      params <- inputs$params()

      # Run simulation
      result <- tryCatch({
        do.call(run_simulation, params)
      }, error = function(e) {
        shiny::showNotification(
          paste("Error:", e$message),
          duration = 10,
          type = "error"
        )
        NULL
      })

      # Show completion notification
      if (!is.null(result)) {
        shiny::showNotification(
          "Simulation complete!",
          duration = 3,
          type = "message"
        )
      }

      result
    })

    # Status message
    output$status <- shiny::renderUI({
      if (is.null(sim_result())) {
        shiny::div(
          class = "alert alert-info",
          shiny::strong("Ready to start."),
          "Configure parameters and click 'Run Simulation'."
        )
      } else {
        shiny::div(
          class = "alert alert-success",
          shiny::strong("Simulation complete!"),
          sprintf(
            "Grid: %dx%d | Walkers: %d | Black pixels: %d (%.1f%%)",
            sim_result()$parameters$grid_size,
            sim_result()$parameters$grid_size,
            sim_result()$parameters$n_walkers,
            sim_result()$statistics$black_pixels,
            sim_result()$statistics$black_percentage
          )
        )
      }
    })

    # Call output module
    sim_output_server("outputs", sim_result)
  }

  shiny::shinyApp(ui = ui, server = server, ...)
}
