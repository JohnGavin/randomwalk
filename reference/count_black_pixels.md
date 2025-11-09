# Count Black Pixels in Grid

Count Black Pixels in Grid

## Usage

``` r
count_black_pixels(grid)
```

## Arguments

- grid:

  Numeric matrix. The simulation grid.

## Value

Integer. Number of black pixels.

## Examples

``` r
grid <- initialize_grid(10)
#> INFO [2025-11-09 16:04:48] Initializing grid of size 10x10
count_black_pixels(grid)  # 1 (only center)
#> [1] 1
```
