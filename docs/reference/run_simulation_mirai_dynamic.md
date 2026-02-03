# Run Simulation with Mirai Direct (True Dynamic Broadcasting)

Uses mirai directly (not crew) with nanonext pub/sub for real-time grid
synchronization between workers. Sockets are initialized on daemons at
startup, enabling mid-task broadcasts.

## Usage

``` r
run_simulation_mirai_dynamic(
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

List with grid, walkers, and statistics
