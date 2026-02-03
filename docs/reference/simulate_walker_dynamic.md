# Simulate Walker with Dynamic Grid Broadcasting

Simulates a single walker with real-time grid synchronization via
nanonext pub/sub pattern. Workers receive broadcasts of new black
pixels, enabling realistic walker interactions.

## Usage

``` r
simulate_walker_dynamic(
  walker_id,
  initial_grid,
  pub_socket = NULL,
  sub_socket,
  grid_size,
  neighborhood = "4-hood",
  boundary = "terminate",
  max_steps = 10000L
)
```

## Arguments

- walker_id:

  Integer. Unique walker identifier.

- initial_grid:

  Matrix. Initial grid state.

- pub_socket:

  Publisher socket for broadcasting updates (optional). If NULL, worker
  returns results without broadcasting (main process broadcasts).

- sub_socket:

  Subscriber socket for receiving updates.

- grid_size:

  Integer. Grid dimensions (n x n).

- neighborhood:

  Character. "4-hood" or "8-hood".

- boundary:

  Character. "terminate" or "wrap".

- max_steps:

  Integer. Maximum steps before forced termination.

## Value

List with walker results:

- walker_id:

  Walker ID

- status:

  Termination reason

- steps:

  Steps taken

- position:

  Final position

- path:

  List of positions visited

- black_pixel_created:

  Logical. TRUE if created black pixel
