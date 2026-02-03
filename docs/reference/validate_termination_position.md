# Validate Termination Position

Checks if a position is valid for termination (has at least one black
neighbor or is the initial center pixel). Used in async mode to prevent
isolated pixels when workers operate on stale grid snapshots.

## Usage

``` r
validate_termination_position(pos, grid, neighborhood = "4-hood")
```

## Arguments

- pos:

  Integer vector of length 2 (row, col). Position to validate.

- grid:

  Numeric matrix. Current grid state.

- neighborhood:

  Character. "4-hood" or "8-hood". Default "4-hood".

## Value

Logical. TRUE if position is valid for termination, FALSE otherwise.

## Details

A termination position is valid if:

1.  The position itself is already black (touching black), OR

2.  The position has at least one black neighbor

This prevents the creation of isolated black pixels in async mode where
workers may have stale grid snapshots.

## See also

[`validate_no_isolated_pixels`](https://johngavin.github.io/randomwalk/reference/validate_no_isolated_pixels.md)

## Examples

``` r
grid <- initialize_grid(10)
#> INFO [2026-02-03 16:23:12] Initializing grid of size 10x10
# Center (5,5) is black, so (5,6) has a black neighbor
validate_termination_position(c(5, 6), grid, "4-hood")  # TRUE
#> [1] TRUE
# Position (1,1) is far from center - no black neighbors
validate_termination_position(c(1, 1), grid, "4-hood")  # FALSE
#> [1] FALSE
```
