# Create Nanonext Publisher Socket

Creates a nanonext publisher socket for broadcasting grid state updates
to all worker processes.

## Usage

``` r
create_pub_socket(port = 5555)
```

## Arguments

- port:

  Integer. TCP port for the publisher socket (default: 5555). Must be
  available and not blocked by firewall.

## Value

A nanonext socket object configured for publishing.

## Details

The publisher socket uses TCP on localhost to broadcast grid updates.
Workers subscribe to this socket to receive notifications when pixels
are added to the black set (walker termination events).

Communication pattern:

- Main process publishes updates via this socket

- Worker processes subscribe (see
  [`worker_init()`](https://johngavin.github.io/randomwalk/reference/worker_init.md))

- Non-blocking: workers poll for updates between steps

The socket binds to `tcp://127.0.0.1:<port>` and allows multiple
subscribers to connect.

## See also

[`broadcast_update`](https://johngavin.github.io/randomwalk/reference/broadcast_update.md),
[`cleanup_async`](https://johngavin.github.io/randomwalk/reference/cleanup_async.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Create publisher socket
pub_socket <- create_pub_socket(port = 5555)

# Broadcast an update
broadcast_update(pub_socket, position = c(10, 15), version = 42)

# Clean up
nanonext::close(pub_socket)
} # }
```
