# Get Percentage of Black Pixels

Get Percentage of Black Pixels

## Usage

``` r
get_black_percentage(grid)
```

## Arguments

- grid:

  Numeric matrix. The simulation grid.

## Value

Numeric. Percentage of black pixels (0-100).

## Examples

``` r
grid <- initialize_grid(10)
#> INFO [2025-11-09 16:04:49] Initializing grid of size 10x10
get_black_percentage(grid)  # 1% for 10x10 grid
#> [1] 1
```
