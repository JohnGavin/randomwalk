# Move Walker One Step (Fast Version)

Optimized version of step_walker that avoids list creation overhead.
Does NOT store path - use regular step_walker for walkers that need
paths.

## Usage

``` r
step_walker_fast(
  walker,
  grid_size,
  neighborhood = c("4-hood", "8-hood"),
  boundary = c("terminate", "wrap")
)
```

## Arguments

- walker:

  List. Walker object.

- grid_size:

  Integer. Size of the grid.

- neighborhood:

  Character. "4-hood" or "8-hood".

- boundary:

  Character. "terminate" or "wrap".

## Value

Modified walker object.
