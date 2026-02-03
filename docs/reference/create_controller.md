# Create Async Controller (Auto-detect Backend)

Creates an async controller for parallel random walk simulation.
Automatically selects the appropriate backend:

- WebR/WebAssembly: mirai (crew not available)

- Native R: crew (preferred for better abstractions)

## Usage

``` r
create_controller(n_workers = 2, seconds_idle = 60)
```

## Arguments

- n_workers:

  Integer. Number of parallel workers to create (default: 2).
  Recommended: 2-4 for medium grids, 4-8 for large grids.

- seconds_idle:

  Numeric. Seconds of idle time before worker shutdown (default: 60).
  Note: Only applies to crew backend (ignored for mirai).

## Value

An async controller object with initialized workers.

- Crew backend: R6 crew controller object

- Mirai backend: List with crew-compatible interface

## Details

The controller manages a pool of R worker processes that execute walker
step functions in parallel. Each worker maintains its own local cache of
the grid state and subscribes to updates from the main process.

**Backend Selection:**

- WebR/WebAssembly detected by
  [`is_webr()`](https://johngavin.github.io/randomwalk/reference/is_webr.md)
  → uses mirai

- Native R → uses crew

Both backends provide the same interface:

- `push()`: Submit task

- `pop()`: Retrieve completed task

- `terminate()`: Shutdown workers

Workers are automatically started when the controller is created and can
be cleanly shut down using
[`cleanup_async()`](https://johngavin.github.io/randomwalk/reference/cleanup_async.md).

## See also

[`create_pub_socket`](https://johngavin.github.io/randomwalk/reference/create_pub_socket.md),
[`cleanup_async`](https://johngavin.github.io/randomwalk/reference/cleanup_async.md),
[`create_mirai_controller`](https://johngavin.github.io/randomwalk/reference/create_mirai_controller.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Create controller (auto-detects environment)
controller <- create_controller(n_workers = 2)

# Use controller for parallel tasks
# ... simulation code ...

# Clean up when done
cleanup_async(controller, socket)
} # }
```
