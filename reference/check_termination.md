# Check Walker Termination Conditions

Checks if the walker should terminate based on simulation rules.

## Usage

``` r
check_termination(
  walker,
  grid,
  neighborhood = "4-hood",
  boundary = "terminate",
  max_steps = 10000L
)
```

## Arguments

- walker:

  List. Walker object.

- grid:

  Numeric matrix. The simulation grid.

- neighborhood:

  Character. "4-hood" or "8-hood".

- boundary:

  Character. "terminate" or "wrap".

- max_steps:

  Integer. Maximum steps before forced termination. Default 10000.

## Value

Modified walker object with updated active status.
