# Check if a Position is Within Grid Bounds

Check if a Position is Within Grid Bounds

## Usage

``` r
is_within_bounds(pos, n)
```

## Arguments

- pos:

  Integer vector of length 2 (row, col).

- n:

  Integer. Grid size.

## Value

Logical. TRUE if position is within bounds, FALSE otherwise.

## Examples

``` r
is_within_bounds(c(5, 5), 10)  # TRUE
#> [1] TRUE
is_within_bounds(c(0, 5), 10)  # FALSE
#> [1] FALSE
is_within_bounds(c(11, 5), 10) # FALSE
#> [1] FALSE
```
