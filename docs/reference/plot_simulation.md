# Plot Simulation Results

Creates a combined visualization showing both the final grid state and
walker paths in a side-by-side layout.

## Usage

``` r
plot_simulation(result, ...)
```

## Arguments

- result:

  A simulation result object returned by
  [`run_simulation`](https://johngavin.github.io/randomwalk/reference/run_simulation.md)

- ...:

  Additional arguments passed to
  [`plot_grid`](https://johngavin.github.io/randomwalk/reference/plot_grid.md)
  and
  [`plot_walker_paths`](https://johngavin.github.io/randomwalk/reference/plot_walker_paths.md)

## Value

Invisibly returns the previous graphical parameters (from
[`par()`](https://rdrr.io/r/graphics/par.html)).

## Examples

``` r
if (FALSE) { # \dontrun{
result <- run_simulation(grid_size = 20, n_walkers = 8)
plot_simulation(result)
} # }
```
