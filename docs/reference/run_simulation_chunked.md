# Run Simulation with Chunked Execution (Near Real-time Updates)

Processes walkers in batches, updating the grid between batches. Walkers
in subsequent batches see black pixels created by earlier batches. Uses
crew for parallel execution within each batch.

## Usage

``` r
run_simulation_chunked(
  grid,
  walkers,
  n_workers,
  neighborhood,
  boundary,
  max_steps,
  start_time,
  validate_strict,
  validate_percent,
  log_interval,
  batch_size = 10
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

- batch_size:

  Integer. Number of walkers per batch (default 10).

## Value

List with grid, walkers, and statistics
