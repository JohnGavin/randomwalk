# Run Shiny Dashboard App

Launches the interactive Shiny dashboard for random walk simulations.
This is a convenience wrapper that combines the input and output modules
into a complete application.

## Usage

``` r
run_dashboard(...)
```

## Arguments

- ...:

  Additional arguments passed to
  [`shiny::shinyApp()`](https://rdrr.io/pkg/shiny/man/shinyApp.html).

## Value

A Shiny app object.

## Examples

``` r
if (FALSE) { # \dontrun{
# Launch the dashboard
run_dashboard()
} # }
```
