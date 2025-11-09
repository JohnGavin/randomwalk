# Plot Walker Paths

Visualizes the paths taken by all walkers during the simulation, showing
their starting positions, trajectories, and termination points.

## Usage

``` r
plot_walker_paths(
  result,
  main = "Walker Paths and Final Positions",
  colors = NULL,
  add_grid = TRUE,
  grid_col = "lightgray",
  lwd = 1.5,
  cex_start = 1.5,
  cex_end = 2,
  legend = TRUE,
  legend_pos = "topright"
)
```

## Arguments

- result:

  A simulation result object returned by
  [`run_simulation`](https://johngavin.github.io/randomwalk/reference/run_simulation.md)

- main:

  Character string for the plot title. Default is "Walker Paths and
  Final Positions"

- colors:

  Optional vector of colors for walker paths. If NULL (default), uses
  rainbow colors

- add_grid:

  Logical indicating whether to add grid lines. Default is TRUE

- grid_col:

  Color for grid lines. Default is "lightgray"

- lwd:

  Line width for paths. Default is 1.5

- cex_start:

  Size of starting position markers. Default is 1.5

- cex_end:

  Size of ending position markers. Default is 2

- legend:

  Logical indicating whether to add a legend. Default is TRUE

- legend_pos:

  Position of legend. Default is "topright"

## Value

Invisibly returns NULL. Called for side effect of creating a plot.

## Details

Walker paths are shown in different colors. Starting positions are
marked with circles. Ending positions are marked with squares (if
terminated due to black neighbor) or triangles (if hit boundary).

## Examples

``` r
if (FALSE) { # \dontrun{
result <- run_simulation(grid_size = 20, n_walkers = 8)
plot_walker_paths(result)
} # }
```
