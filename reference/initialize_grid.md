# Initialize a Grid

Creates an n x n grid for the random walk simulation. By default, the
center pixel is set to black (1), and all other pixels are white (0).

## Usage

``` r
initialize_grid(n, center_black = TRUE)
```

## Arguments

- n:

  Integer. The size of the grid (n x n). Must be \>= 3.

- center_black:

  Logical. If TRUE, initializes the center pixel as black. Default is
  TRUE.

## Value

A numeric matrix of size n x n with 0 (white) and 1 (black) values.

## Examples

``` r
grid <- initialize_grid(10)
#> INFO [2025-11-09 16:04:49] Initializing grid of size 10x10
grid[5, 5]  # Center pixel should be 1 (black)
#> [1] 1
```
