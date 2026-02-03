# Check if Position Has Black Neighbor (Vectorized)

Vectorized version of has_black_neighbor for better performance. Uses
matrix indexing instead of loops.

## Usage

``` r
has_black_neighbor_fast(
  pos,
  grid,
  grid_size,
  neighborhood = c("4-hood", "8-hood")
)
```

## Arguments

- pos:

  Integer vector of length 2 (row, col).

- grid:

  Numeric matrix. The simulation grid.

- grid_size:

  Integer. Size of the grid.

- neighborhood:

  Character. "4-hood" or "8-hood".

## Value

Logical. TRUE if position has at least one black neighbor.
