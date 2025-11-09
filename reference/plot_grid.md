# Plot Final Grid State

Visualizes the final state of the simulation grid, showing black pixels
that formed during the random walk simulation.

## Usage

``` r
plot_grid(
  result,
  main = "Random Walk Simulation - Final Grid State",
  col_palette = c("white", "black"),
  add_grid = TRUE,
  grid_col = "gray"
)
```

## Arguments

- result:

  A simulation result object returned by
  [`run_simulation`](https://johngavin.github.io/randomwalk/reference/run_simulation.md)

- main:

  Character string for the plot title. Default is "Random Walk
  Simulation - Final Grid State"

- col_palette:

  A vector of two colors for white (0) and black (1) pixels. Default is
  c("white", "black")

- add_grid:

  Logical indicating whether to add grid lines. Default is TRUE

- grid_col:

  Color for grid lines. Default is "gray"

## Value

Invisibly returns NULL. Called for side effect of creating a plot.

## Examples

``` r
if (FALSE) { # \dontrun{
result <- run_simulation(grid_size = 20, n_walkers = 8)
plot_grid(result)
} # }
```
