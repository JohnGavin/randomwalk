# Broadcast Grid Update to Workers

Sends a grid state update message to all subscribed workers via the
nanonext publisher socket.

## Usage

``` r
broadcast_update(socket, position, version)
```

## Arguments

- socket:

  A nanonext publisher socket created by
  [`create_pub_socket()`](https://johngavin.github.io/randomwalk/reference/create_pub_socket.md).

- position:

  Integer vector of length 2. Grid coordinates `c(row, col)` of the
  newly black pixel.

- version:

  Integer. Current version number of the grid state. Workers use this to
  detect stale caches.

## Value

NULL (invisibly). Message is sent asynchronously.

## Details

Broadcasts a pixel update message containing:

- `type`: Always "pixel_update"

- `position`: Coordinates of new black pixel

- `version`: Grid state version number

Workers listening on the subscriber socket will receive this message and
update their local caches accordingly.

This is a non-blocking operation - the function returns immediately
after queuing the message for transmission.

## See also

[`create_pub_socket`](https://johngavin.github.io/randomwalk/reference/create_pub_socket.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Broadcast update when walker terminates
broadcast_update(
  socket = pub_socket,
  position = c(10, 15),
  version = 42
)
} # }
```
