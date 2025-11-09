# Run a Random Walk Simulation

Executes a complete random walk simulation with the specified
parameters. This is the main entry point for running simulations
programmatically.

## Usage

``` r
run_simulation(
  grid_size = 10,
  n_walkers = 5,
  neighborhood = "4-hood",
  boundary = "terminate",
  workers = 0,
  max_steps = 10000L,
  verbose = FALSE
)
```

## Arguments

- grid_size:

  Integer. Size of the grid (n x n). Default 10.

- n_walkers:

  Integer. Number of simultaneous walkers. Default 5. Must be between 1
  and 60% of grid size.

- neighborhood:

  Character. Either "4-hood" or "8-hood". Default "4-hood".

- boundary:

  Character. Either "terminate" or "wrap". Default "terminate".

- workers:

  Integer. Number of parallel workers (0 = synchronous). Default 0.
  Note: Async implementation not yet available in this version.

- max_steps:

  Integer. Maximum steps per walker before forced termination. Default
  10000.

- verbose:

  Logical. If TRUE, enables detailed logging. Default FALSE.

## Value

A list with components:

- grid:

  Final grid state

- walkers:

  List of final walker states

- statistics:

  Simulation statistics

- parameters:

  Input parameters

## Examples

``` r
if (FALSE) { # \dontrun{
result <- run_simulation(grid_size = 20, n_walkers = 8)
plot_grid(result$grid)
print(result$statistics)
} # }
```
