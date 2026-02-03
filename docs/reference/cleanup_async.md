# Clean Up Async Resources

Shuts down crew workers and closes nanonext sockets. Should always be
called when async simulation completes or errors.

## Usage

``` r
cleanup_async(controller, socket)
```

## Arguments

- controller:

  A crew controller object created by
  [`create_controller()`](https://johngavin.github.io/randomwalk/reference/create_controller.md).
  Can be NULL if controller was not successfully created.

- socket:

  A nanonext publisher socket created by
  [`create_pub_socket()`](https://johngavin.github.io/randomwalk/reference/create_pub_socket.md).
  Can be NULL if socket was not successfully created.

## Value

NULL (invisibly). Side effect: workers stopped, sockets closed.

## Details

Performs graceful shutdown:

1.  Terminates all crew workers (sends shutdown signal)

2.  Closes nanonext publisher socket

3.  Logs cleanup status

This function is safe to call multiple times and handles NULL inputs
gracefully (useful for error cleanup).

Always call this function in a
[`tryCatch()`](https://rdrr.io/r/base/conditions.html) finally block to
ensure resources are cleaned up even if the simulation errors.

## See also

[`create_controller`](https://johngavin.github.io/randomwalk/reference/create_controller.md),
[`create_pub_socket`](https://johngavin.github.io/randomwalk/reference/create_pub_socket.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Typical usage pattern
controller <- NULL
socket <- NULL

tryCatch({
  controller <- create_controller(n_workers = 2)
  socket <- create_pub_socket(port = 5555)

  # ... run simulation ...

}, finally = {
  cleanup_async(controller, socket)
})
} # }
```
