# Get Pixel Value from Grid

Retrieves the value at a given position, handling boundary conditions.

## Usage

``` r
get_pixel(grid, pos, boundary = "terminate")
```

## Arguments

- grid:

  Numeric matrix. The simulation grid.

- pos:

  Integer vector of length 2 (row, col).

- boundary:

  Character. Either "terminate" or "wrap". Default is "terminate".

## Value

Integer. The pixel value (0 or 1), or NA if out of bounds with
"terminate" boundary.

## Examples

``` r
grid <- initialize_grid(10)
#> INFO [2025-11-09 16:04:49] Initializing grid of size 10x10
get_pixel(grid, c(5, 5))  # 1 (center is black)
#> [1] 1
get_pixel(grid, c(0, 5))  # NA (out of bounds with terminate)
#> [1] NA
get_pixel(grid, c(0, 5), boundary = "wrap")  # Value from wrapped position
#> [1] 0
```
