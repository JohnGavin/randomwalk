# Check Termination Using Cached Black Pixels

Checks if walker should terminate based on cached black pixel set.
Internal function used by
[`worker_step_walker()`](https://johngavin.github.io/randomwalk/reference/worker_step_walker.md).

## Usage

``` r
check_termination_cached(
  walker,
  black_pixels,
  neighborhood,
  boundary,
  grid_size,
  max_steps
)
```

## Arguments

- walker:

  List. Walker object.

- black_pixels:

  List. Cached black pixel positions (keyed by "row,col").

- neighborhood:

  Character. "4-hood" or "8-hood".

- boundary:

  Character. "terminate" or "wrap".

- grid_size:

  Integer. Grid dimension.

- max_steps:

  Integer. Maximum steps limit.

## Value

Modified walker object with updated active status.

## Details

Similar to
[`check_termination()`](https://johngavin.github.io/randomwalk/reference/check_termination.md)
but uses a cached set of black pixels instead of querying the grid
matrix. This enables fast termination checks in worker processes without
grid access.

Termination conditions:

1.  Walker is on a black pixel (touches_black)

2.  Walker has a black neighbor (has_black_neighbor)

3.  Walker exceeded max_steps limit

## See also

[`check_termination`](https://johngavin.github.io/randomwalk/reference/check_termination.md)
