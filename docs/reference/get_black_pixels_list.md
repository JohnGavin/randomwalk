# Get Black Pixels as Named List

Converts grid matrix to a named list of black pixel positions. Used for
initializing worker caches in async mode.

## Usage

``` r
get_black_pixels_list(grid)
```

## Arguments

- grid:

  Numeric matrix. The simulation grid.

## Value

Named list where keys are "row,col" and values are c(row, col).
