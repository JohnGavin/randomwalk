# Log Detailed Isolated Pixel Debugging Information

When an isolated pixel is detected, logs comprehensive context to help
identify the root cause of the bug. This is critical for debugging since
isolated pixels indicate a logic error in the simulation.

## Usage

``` r
log_isolated_pixel_details(
  pos,
  grid,
  neighborhood,
  walkers = NULL,
  step_count = NULL,
  black_positions = NULL
)
```

## Arguments

- pos:

  Integer vector of length 2. Position of isolated pixel (row, col).

- grid:

  Matrix. Current grid state.

- neighborhood:

  Character. Neighborhood type ("4-hood" or "8-hood").

- walkers:

  List. Current walker states (optional, for context).

- step_count:

  Integer. Current simulation step (optional, for context).

- black_positions:

  Matrix. All black pixel positions (optional, for context).
