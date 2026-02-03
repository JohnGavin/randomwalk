# Run Walker Until Termination (Worker Task)

Executes a complete walker simulation until termination. This is the
function pushed to crew workers as a task.

## Usage

``` r
worker_run_walker(
  walker,
  grid_state,
  pub_address = NULL,
  neighborhood = "4-hood",
  boundary = "terminate",
  max_steps = 10000L
)
```

## Arguments

- walker:

  List. Walker object.

- grid_state:

  List. Grid state (grid matrix, black_pixels, grid_size).

- pub_address:

  Character. Publisher socket address.

- neighborhood:

  Character. "4-hood" or "8-hood".

- boundary:

  Character. "terminate" or "wrap".

- max_steps:

  Integer. Maximum steps limit.

## Value

Terminated walker object with complete path.

## Details

This function represents a complete worker task:

1.  Initialize worker (create subscriber socket, cache)

2.  Step walker repeatedly until termination

3.  Clean up worker resources

4.  Return final walker state

The worker maintains a local cache of black pixels and subscribes to
updates from the main process. This allows independent execution while
staying reasonably synchronized with the global grid state.

## See also

[`worker_step_walker`](https://johngavin.github.io/randomwalk/reference/worker_step_walker.md),
[`worker_init`](https://johngavin.github.io/randomwalk/reference/worker_init.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# This function is called by crew workers, not directly by users
# Controller pushes this task:
controller$push(
  command = worker_run_walker(walker, grid_state, pub_address, ...),
  data = list(walker = walker, grid_state = grid_state, ...)
)
} # }
```
