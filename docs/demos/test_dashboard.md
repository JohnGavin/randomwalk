# Test Shinylive Dashboard

# Test Shinylive Dashboard

# Test Dashboard

``` shinylive-r
#| '!! shinylive warning !!': |
#|   shinylive does not work in self-contained HTML documents.
#|   Please set `embed-resources: false` in your metadata.
#| standalone: true
#| viewerHeight: 600

library(shiny)

ui <- fluidPage(
  h1("Hello Shinylive!"),
  sliderInput("n", "N:", 1, 100, 50),
  plotOutput("plot")
)

server <- function(input, output) {
  output$plot <- renderPlot({
    hist(rnorm(input$n))
  })
}

shinyApp(ui, server)
```
