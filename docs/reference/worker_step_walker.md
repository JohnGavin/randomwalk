# Execute Walker Step (Worker)

Executes one step of a walker using cached grid state. This is the main
work function executed by crew workers.

## Usage

``` r
worker_step_walker(
  walker,
  grid_state,
  worker_state,
  neighborhood = "4-hood",
  boundary = "terminate",
  max_steps = 10000L
)
```

## Arguments

- walker:

  List. Walker object (from
  [`create_walker()`](https://johngavin.github.io/randomwalk/reference/create_walker.md)).

- grid_state:

  List. Contains grid matrix and black_pixels set.

- worker_state:

  List. Worker state from
  [`worker_init()`](https://johngavin.github.io/randomwalk/reference/worker_init.md).

- neighborhood:

  Character. "4-hood" or "8-hood" (default: "4-hood").

- boundary:

  Character. "terminate" or "wrap" (default: "terminate").

- max_steps:

  Integer. Maximum steps before forced termination (default: 10000).

## Value

Modified walker object after one step.

## Details

Performs one iteration of the random walk:

1.  Check for grid updates (refresh cache)

2.  Move walker one step using
    [`step_walker()`](https://johngavin.github.io/randomwalk/reference/step_walker.md)

3.  Check termination using cached black pixels

The worker uses its local cache of black pixels to check termination
conditions. This avoids querying the main process on every step,
significantly reducing synchronization overhead.

Cache staleness is acceptable because:

- Random walks are stochastic (small delays don't affect statistical
  properties)

- Updates are broadcast immediately when walkers terminate

- Worker checks for updates before each step

## See also

[`step_walker`](https://johngavin.github.io/randomwalk/reference/step_walker.md),
[`check_termination`](https://johngavin.github.io/randomwalk/reference/check_termination.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Step a walker in a worker process
walker <- worker_step_walker(
  walker = walker,
  grid_state = grid_state,
  worker_state = worker_state,
  neighborhood = "4-hood",
  boundary = "terminate"
)
} # }
```
