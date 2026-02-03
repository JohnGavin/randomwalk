# Run Async Simulation with Dynamic Broadcasting (Internal)

Internal function that executes async simulation with real-time grid
synchronization via nanonext pub/sub pattern. Workers receive broadcasts
of new black pixels, enabling collision detection.

## Usage

``` r
run_simulation_async_dynamic(
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

- validate_strict:

  Logical. Strict validation mode.

- validate_percent:

  Numeric. Validation frequency.

## Value

List with grid, walkers, and statistics (including collision counts).
