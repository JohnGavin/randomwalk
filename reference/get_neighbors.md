# Get Neighboring Positions

Returns all valid neighbor positions for a given position.

## Usage

``` r
get_neighbors(pos, neighborhood = "4-hood")
```

## Arguments

- pos:

  Integer vector of length 2 (row, col).

- neighborhood:

  Character. Either "4-hood" (NSEW) or "8-hood" (includes diagonals).
  Default is "4-hood".

## Value

A list of integer vectors, each of length 2.

## Examples

``` r
get_neighbors(c(5, 5), "4-hood")  # Returns 4 neighbors
#> [[1]]
#> [1] 4 5
#> 
#> [[2]]
#> [1] 6 5
#> 
#> [[3]]
#> [1] 5 6
#> 
#> [[4]]
#> [1] 5 4
#> 
get_neighbors(c(5, 5), "8-hood")  # Returns 8 neighbors
#> [[1]]
#> [1] 4 5
#> 
#> [[2]]
#> [1] 6 5
#> 
#> [[3]]
#> [1] 5 6
#> 
#> [[4]]
#> [1] 5 4
#> 
#> [[5]]
#> [1] 4 6
#> 
#> [[6]]
#> [1] 4 4
#> 
#> [[7]]
#> [1] 6 6
#> 
#> [[8]]
#> [1] 6 4
#> 
```
