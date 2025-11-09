# Check if Walker Has Black Neighbor

Checks if any of the walker's neighbors are black pixels.

## Usage

``` r
has_black_neighbor(
  walker,
  grid,
  neighborhood = "4-hood",
  boundary = "terminate"
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

  Character. Boundary condition.

## Value

Logical. TRUE if walker has at least one black neighbor.
