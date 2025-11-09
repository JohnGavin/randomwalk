# Generate Random Starting Positions for Walkers

Creates random starting positions for walkers, avoiding the center pixel
and any black pixels.

## Usage

``` r
generate_walker_positions(n_walkers, grid, avoid_black = TRUE)
```

## Arguments

- n_walkers:

  Integer. Number of walkers to create.

- grid:

  Numeric matrix. The simulation grid.

- avoid_black:

  Logical. If TRUE, avoids placing walkers on black pixels.

## Value

A list of integer vectors, each of length 2 (row, col).

## Examples

``` r
grid <- initialize_grid(10)
#> INFO [2025-11-09 16:04:49] Initializing grid of size 10x10
positions <- generate_walker_positions(5, grid)
```
