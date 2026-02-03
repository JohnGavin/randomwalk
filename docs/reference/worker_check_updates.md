# Check for Grid Updates (Worker)

Non-blocking check for grid state updates from the publisher socket.
Updates the worker's local cache if new pixel updates are available.

## Usage

``` r
worker_check_updates(worker_state)
```

## Arguments

- worker_state:

  List. Worker state from
  [`worker_init()`](https://johngavin.github.io/randomwalk/reference/worker_init.md).

## Value

Modified worker_state with updated cache (if updates received).

## Details

Polls the subscriber socket for new messages without blocking. If
updates are available, processes all queued messages and updates the
local black_pixels cache and version number.

This function should be called periodically between walker steps to keep
the cache reasonably fresh. In Phase 1, it's called before each walker
step.

Update message format (from broadcaster):
`list(type = "pixel_update", position = c(row, col), version = int)`

## See also

[`worker_init`](https://johngavin.github.io/randomwalk/reference/worker_init.md),
[`broadcast_update`](https://johngavin.github.io/randomwalk/reference/broadcast_update.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Check for updates before stepping walker
worker_state <- worker_check_updates(worker_state)
} # }
```
