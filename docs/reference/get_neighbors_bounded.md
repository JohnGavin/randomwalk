# Get Neighbor Positions (Bounded)

Returns list of neighbor positions based on neighborhood type, filtering
out positions that are out of bounds.

## Usage

``` r
get_neighbors_bounded(position, grid_size, neighborhood)
```

## Arguments

- position:

  Vector c(x, y) current position

- grid_size:

  Integer grid dimensions

- neighborhood:

  Character "4-hood" or "8-hood"

## Value

List of neighbor positions (within bounds only)
