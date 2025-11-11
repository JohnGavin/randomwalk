# R-Universe Setup for randomwalk Package

## Overview

To enable the Shinylive dashboard to load the `randomwalk` package in the browser, the package needs to be compiled to WebAssembly and made available through R-Universe.

## Setup Steps

### 1. Create Universe Repository

1. Create a new repository named `universe` on your GitHub account (JohnGavin)
2. In this repository, create a file named `packages.json` with the following content:

```json
[
  {
    "package": "randomwalk",
    "url": "https://github.com/JohnGavin/randomwalk"
  }
]
```

### 2. Install R-Universe GitHub App

1. Visit https://github.com/apps/r-universe/installations/new
2. Install the app on your GitHub account
3. Grant it access to the `universe` repository

### 3. Wait for Build

Once the app is installed:
- R-Universe will automatically create a monorepo at `https://github.com/r-universe/JohnGavin`
- The system will build WebAssembly binaries for your packages
- This process may take 30-60 minutes for the first build
- Check build status at: https://johngavin.r-universe.dev/

### 4. Update Dashboard Vignette

Once WebAssembly binaries are available, update `vignettes/dashboard.qmd` to use the package:

```r
```{shinylive-r}
#| standalone: true
#| viewerHeight: 800

# Install from R-Universe
options(repos = c(
  johngavin = 'https://johngavin.r-universe.dev',
  CRAN = 'https://cloud.r-project.org'
))

library(shiny)
library(randomwalk)  # Load the actual package

# UI
ui <- fluidPage(
  titlePanel("Random Walk Simulation Dashboard"),

  sidebarLayout(
    sidebarPanel(
      # ... input controls ...
    ),

    mainPanel(
      # ... output tabs ...
    )
  )
)

# Server
server <- function(input, output, session) {
  # Use actual package functions
  sim_result <- eventReactive(input$run_sim, {
    run_simulation(
      grid_size = input$grid_size,
      n_walkers = input$n_walkers,
      neighborhood = input$neighborhood,
      boundary = input$boundary
    )
  })

  output$grid_plot <- renderPlot({
    req(sim_result())
    plot_grid(sim_result())
  })

  output$paths_plot <- renderPlot({
    req(sim_result())
    plot_walker_paths(sim_result())
  })

  # ... other outputs ...
}

shinyApp(ui = ui, server = server)
```
```

## Benefits

- **No code duplication**: Dashboard uses actual package functions
- **Automatic updates**: Dashboard automatically uses latest package version
- **Better maintenance**: Single source of truth for simulation logic
- **Proper dependency management**: R-Universe handles all dependencies

## References

- R-Universe Documentation: https://docs.r-universe.dev/
- Setup Guide: https://ropensci.org/blog/2021/06/22/setup-runiverse/
- Shinylive Documentation: https://posit-dev.github.io/r-shinylive/
