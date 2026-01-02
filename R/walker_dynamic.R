#' Simulate Walker with Dynamic Grid Broadcasting
#'
#' Simulates a single walker with real-time grid synchronization via nanonext
#' pub/sub pattern. Workers receive broadcasts of new black pixels, enabling
#' realistic walker interactions.
#'
#' @param walker_id Integer. Unique walker identifier.
#' @param initial_grid Matrix. Initial grid state.
#' @param pub_socket Publisher socket for broadcasting updates (optional).
#'   If NULL, worker returns results without broadcasting (main process broadcasts).
#' @param sub_socket Subscriber socket for receiving updates.
#' @param grid_size Integer. Grid dimensions (n x n).
#' @param neighborhood Character. "4-hood" or "8-hood".
#' @param boundary Character. "terminate" or "wrap".
#' @param max_steps Integer. Maximum steps before forced termination.
#'
#' @return List with walker results:
#'   \describe{
#'     \item{walker_id}{Walker ID}
#'     \item{status}{Termination reason}
#'     \item{steps}{Steps taken}
#'     \item{position}{Final position}
#'     \item{path}{List of positions visited}
#'     \item{black_pixel_created}{Logical. TRUE if created black pixel}
#'   }
#'
#' @export
simulate_walker_dynamic <- function(walker_id,
                                   initial_grid,
                                   pub_socket = NULL,
                                   sub_socket,
                                   grid_size,
                                   neighborhood = "4-hood",
                                   boundary = "terminate",
                                   max_steps = 10000L) {

  local_grid <- initial_grid
  path <- list()

  # ═══════════════════════════════════════════════════════════
  # STEP 0: Sample starting position and check if already black
  # ═══════════════════════════════════════════════════════════
  position <- sample_start_position(grid_size, grid_size)

  if (local_grid[position[1], position[2]] == 1) {
    # Started on black pixel - terminate immediately
    # This pixel was already broadcast by whoever created it
    return(list(
      walker_id = walker_id,
      status = "started_on_black",
      steps = 0,
      position = position,
      path = list(),
      black_pixel_created = FALSE
    ))
  }

  # ═══════════════════════════════════════════════════════════
  # MAIN SIMULATION LOOP (Steps 1-N)
  # ═══════════════════════════════════════════════════════════
  for (step in seq_len(max_steps)) {

    # ───────────────────────────────────────────────────────────
    # STEP 1: Pop ALL broadcast messages, update local grid
    # ───────────────────────────────────────────────────────────
    # Only try to receive broadcasts if socket is available
    # Wrap in tryCatch - nanonext sockets may fail in subprocess contexts
    if (!is.null(sub_socket)) {
      local_grid <- tryCatch(
        update_grid_from_broadcasts(sub_socket, local_grid),
        error = function(e) local_grid  # On error, keep current grid
      )
    }

    # ───────────────────────────────────────────────────────────
    # STEP 2: Check neighbors for black pixels
    # ───────────────────────────────────────────────────────────
    neighbors <- get_neighbors_bounded(position, grid_size, neighborhood)

    has_black_neighbor <- any(sapply(neighbors, function(pos) {
      if (pos[1] < 1 || pos[1] > grid_size || pos[2] < 1 || pos[2] > grid_size) {
        return(FALSE)  # Out of bounds
      }
      local_grid[pos[1], pos[2]] == 1  # Grid uses 1 for black
    }))

    if (has_black_neighbor) {
      # FOUND BLACK NEIGHBOR!
      # Walker STOPS - current position becomes BLACK
      local_grid[position[1], position[2]] <- 1  # Grid uses 1 for black

      # BROADCAST: New black pixel created at walker's current position
      # Only if pub_socket provided (main process may broadcast instead)
      if (!is.null(pub_socket)) {
        broadcast_black_pixel(pub_socket, position, walker_id)
      }

      return(list(
        walker_id = walker_id,
        status = "black_neighbor_detected",
        steps = step,
        position = position,
        path = path,
        black_pixel_created = TRUE
      ))
    }

    # ───────────────────────────────────────────────────────────
    # STEP 3: No black neighbors - make next move
    # ───────────────────────────────────────────────────────────

    # Choose next position based on neighborhood
    next_position <- choose_next_position(position, local_grid, neighborhood)

    # Check boundary
    if (is_boundary(next_position, grid_size, grid_size)) {
      if (boundary == "terminate") {
        # Hit boundary - walker leaves grid, no black pixel
        return(list(
          walker_id = walker_id,
          status = "boundary",
          steps = step,
          position = position,
          path = path,
          black_pixel_created = FALSE
        ))
      }

      # Handle boundary (wrap or reflect)
      next_position <- handle_boundary(next_position, boundary, grid_size, grid_size)
    }

    # Record path and move
    path[[step]] <- position
    position <- next_position
  }

  # ═══════════════════════════════════════════════════════════
  # Max steps reached - walker just stops (no black pixel)
  # ═══════════════════════════════════════════════════════════
  return(list(
    walker_id = walker_id,
    status = "max_steps",
    steps = max_steps,
    position = position,
    path = path,
    black_pixel_created = FALSE
  ))
}


#' Get Neighbor Positions (Bounded)
#'
#' Returns list of neighbor positions based on neighborhood type,
#' filtering out positions that are out of bounds.
#'
#' @param position Vector c(x, y) current position
#' @param grid_size Integer grid dimensions
#' @param neighborhood Character "4-hood" or "8-hood"
#' @return List of neighbor positions (within bounds only)
#' @export
get_neighbors_bounded <- function(position, grid_size, neighborhood) {
  x <- position[1]
  y <- position[2]

  if (neighborhood == "4-hood") {
    neighbors <- list(
      c(x - 1, y),     # North
      c(x + 1, y),     # South
      c(x, y - 1),     # West
      c(x, y + 1)      # East
    )
  } else {  # 8-hood
    neighbors <- list(
      c(x - 1, y),     # North
      c(x + 1, y),     # South
      c(x, y - 1),     # West
      c(x, y + 1),     # East
      c(x - 1, y - 1), # NW
      c(x - 1, y + 1), # NE
      c(x + 1, y - 1), # SW
      c(x + 1, y + 1)  # SE
    )
  }

  # Filter out-of-bounds neighbors
  neighbors[sapply(neighbors, function(pos) {
    pos[1] >= 1 && pos[1] <= grid_size && pos[2] >= 1 && pos[2] <= grid_size
  })]
}


#' Choose Next Position
#'
#' Randomly selects next position from valid neighbors
#'
#' @param position Vector c(x, y) current position
#' @param grid Matrix current grid state
#' @param neighborhood Character "4-hood" or "8-hood"
#' @return Vector c(x, y) next position
#' @keywords internal
choose_next_position <- function(position, grid, neighborhood) {
  grid_size <- nrow(grid)
  neighbors <- get_neighbors(position, neighborhood)

  # Randomly select one neighbor
  if (length(neighbors) > 0) {
    neighbors[[sample(length(neighbors), 1)]]
  } else {
    position  # No valid neighbors, stay in place
  }
}


#' Check if Position is at Boundary
#'
#' @param position Vector c(x, y)
#' @param nrow Integer number of rows
#' @param ncol Integer number of columns
#' @return Logical TRUE if at boundary
#' @keywords internal
is_boundary <- function(position, nrow, ncol) {
  position[1] < 1 || position[1] > nrow || position[2] < 1 || position[2] > ncol
}


#' Handle Boundary Condition
#'
#' @param position Vector c(x, y) position that hit boundary
#' @param boundary Character "wrap" or "terminate"
#' @param nrow Integer grid rows
#' @param ncol Integer grid columns
#' @return Vector c(x, y) adjusted position
#' @keywords internal
handle_boundary <- function(position, boundary, nrow, ncol) {
  if (boundary == "wrap") {
    # Wrap around
    x <- ((position[1] - 1) %% nrow) + 1
    y <- ((position[2] - 1) %% ncol) + 1
    c(x, y)
  } else {
    # Terminate - return original
    position
  }
}


#' Sample Random Starting Position
#'
#' @param nrow Integer grid rows
#' @param ncol Integer grid columns
#' @return Vector c(x, y) random position
#' @keywords internal
sample_start_position <- function(nrow, ncol) {
  c(sample(nrow, 1), sample(ncol, 1))
}
