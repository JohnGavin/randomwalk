# Wrap Position Around Grid Boundaries (Torus Topology)

Wrap Position Around Grid Boundaries (Torus Topology)

## Usage

``` r
wrap_position(pos, n)
```

## Arguments

- pos:

  Integer vector of length 2 (row, col).

- n:

  Integer. Grid size.

## Value

Integer vector of length 2 with wrapped coordinates.

## Examples

``` r
wrap_position(c(0, 5), 10)   # c(10, 5)
#> [1] 10  5
wrap_position(c(11, 5), 10)  # c(1, 5)
#> [1] 1 5
wrap_position(c(5, 0), 10)   # c(5, 10)
#> [1]  5 10
```
