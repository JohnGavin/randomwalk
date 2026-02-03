# Find Isolated Pixels in Grid

Scans the grid to find black pixels that have no black neighbors, which
violates the connectivity requirement for DLA simulations.

## Usage

``` r
find_isolated_pixels(grid, neighborhood = "4-hood")
```

## Arguments

- grid:

  Numeric matrix representing the grid state (0 = white, 1 = black)

- neighborhood:

  Character string specifying neighborhood type: `"4-hood"` (orthogonal)
  or `"8-hood"` (includes diagonals)

## Value

List of isolated pixel positions (each element is a 2-element numeric
vector with row and column indices). Returns empty list if no isolated
pixels found.

## Details

This function is useful for:

- Debugging WebR/Shiny reactive timing issues

- Validating grid state after async simulations

- Testing grid connectivity requirements

A pixel is considered isolated if:

- It is black (value = 1)

- None of its neighbors (in the specified neighborhood) are black

Note: The center pixel is never considered isolated (it's the seed).

## See also

[`validate_termination_position`](https://johngavin.github.io/randomwalk/reference/validate_termination_position.md),
[`validate_no_isolated_pixels`](https://johngavin.github.io/randomwalk/reference/validate_no_isolated_pixels.md)

## Examples

``` r
grid <- initialize_grid(10)
#> INFO [2026-02-03 16:23:07] Initializing grid of size 10x10
grid[3, 3] <- 1  # Add isolated pixel far from center
isolated <- find_isolated_pixels(grid, "4-hood")
#> WARN [2026-02-03 16:23:07] Grid has 2 isolated pixel(s)
length(isolated)  # Should be 1
#> [1] 2
```
