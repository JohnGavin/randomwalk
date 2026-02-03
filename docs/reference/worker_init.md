# Initialize Worker with Subscriber Socket

Sets up a worker process to receive grid state updates via nanonext.
Called once per worker at startup.

## Usage

``` r
worker_init(pub_address)
```

## Arguments

- pub_address:

  Character. Publisher socket address (e.g., "tcp://127.0.0.1:5555").

## Value

A list containing:

- socket:

  nanonext subscriber socket

- cache:

  List with black_pixels and version

## Details

Creates a subscriber socket that listens for pixel update broadcasts
from the main process. Also initializes a local cache to store the
current set of black pixels and grid state version.

The cache is used to avoid querying the main process for grid state on
every walker step. Workers check for updates periodically and refresh
the cache when the version number changes.

## See also

[`worker_check_updates`](https://johngavin.github.io/randomwalk/reference/worker_check_updates.md),
[`worker_step_walker`](https://johngavin.github.io/randomwalk/reference/worker_step_walker.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Worker initialization (executed in crew worker process)
worker_state <- worker_init("tcp://127.0.0.1:5555")
} # }
```
