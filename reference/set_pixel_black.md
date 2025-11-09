# Set Pixel Value in Grid

Sets the value at a given position to black (1).

## Usage

``` r
set_pixel_black(grid, pos, boundary = "terminate")
```

## Arguments

- grid:

  Numeric matrix. The simulation grid.

- pos:

  Integer vector of length 2 (row, col).

- boundary:

  Character. Either "terminate" or "wrap". Default is "terminate".

## Value

Modified grid matrix.

## Examples

``` r
grid <- initialize_grid(10)
#> INFO [2025-11-09 16:04:50] Initializing grid of size 10x10
grid <- set_pixel_black(grid, c(3, 3))
grid[3, 3]  # 1
#> [1] 1
```
