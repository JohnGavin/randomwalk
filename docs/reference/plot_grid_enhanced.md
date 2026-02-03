# Enhanced Grid Plot with Arrival Time Coloring

Visualizes the final state of the simulation grid with pixels colored by
their arrival time (termination order). Earlier arrivals are shown in
darker colors, later arrivals in lighter colors.

## Usage

``` r
plot_grid_enhanced(
  result,
  main = NULL,
  quantiles = 5,
  color_scheme = "viridis"
)
```

## Arguments

- result:

  A simulation result object from run_simulation()

- main:

  Custom title. If NULL, auto-generates with pixel statistics

- quantiles:

  Number of quantiles for color grouping (default 5)

- color_scheme:

  Color palette name: "viridis", "plasma", "blues", "heat"

## Value

A ggplot2 object
