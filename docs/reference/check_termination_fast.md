# Check Termination Conditions (Fast Version)

Optimized version of check_termination using vectorized neighbor checks.
Avoids function call overhead for hot path.

## Usage

``` r
check_termination_fast(
  walker,
  grid,
  grid_size,
  neighborhood = c("4-hood", "8-hood"),
  max_steps = 10000L
)
```

## Arguments

- walker:

  List. Walker object.

- grid:

  Numeric matrix. The simulation grid.

- grid_size:

  Integer. Size of the grid.

- neighborhood:

  Character. "4-hood" or "8-hood".

- max_steps:

  Integer. Maximum steps before forced termination.

## Value

Modified walker object with updated active status.
