# Run Async Simulation (Internal)

Internal function that executes the async simulation using crew workers.
Called by run_simulation() when workers \> 0.

## Usage

``` r
run_simulation_async(
  grid,
  walkers,
  n_workers,
  neighborhood,
  boundary,
  max_steps,
  start_time,
  validate_strict,
  validate_percent,
  log_interval
)
```

## Arguments

- grid:

  Numeric matrix. Initialized grid.

- walkers:

  List. Created walker objects.

- n_workers:

  Integer. Number of crew workers.

- neighborhood:

  Character. "4-hood" or "8-hood".

- boundary:

  Character. "terminate" or "wrap".

- max_steps:

  Integer. Maximum steps limit.

- start_time:

  POSIXct. Simulation start time.

## Value

List with grid, walkers, and statistics.
