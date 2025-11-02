#' Create a Walker
#'
#' Creates a walker object for the random walk simulation.
#'
#' @param id Integer. Unique identifier for the walker.
#' @param pos Integer vector of length 2 (row, col). Starting position.
#' @param grid_size Integer. Size of the grid.
#'
#' @return A list representing the walker with components:
#'   \describe{
#'     \item{id}{Walker identifier}
#'     \item{pos}{Current position}
#'     \item{steps}{Number of steps taken}
#'     \item{active}{Logical indicating if walker is still active}
#'     \item{termination_reason}{Character string if terminated, NULL otherwise}
#'     \item{path}{List of all positions visited}
#'   }
#'
#' @examples
#' walker <- create_walker(1, c(5, 5), 10)
#'
#' @export
create_walker <- function(id, pos, grid_size) {
  logger::log_debug("Creating walker {id} at position ({pos[1]}, {pos[2]})")

  list(
    id = id,
    pos = pos,
    steps = 0L,
    active = TRUE,
    termination_reason = NULL,
    path = list(pos),
    grid_size = grid_size
  )
}

#' Generate Random Starting Positions for Walkers
#'
#' Creates random starting positions for walkers, avoiding the center pixel
#' and any black pixels.
#'
#' @param n_walkers Integer. Number of walkers to create.
#' @param grid Numeric matrix. The simulation grid.
#' @param avoid_black Logical. If TRUE, avoids placing walkers on black pixels.
#'
#' @return A list of integer vectors, each of length 2 (row, col).
#'
#' @examples
#' grid <- initialize_grid(10)
#' positions <- generate_walker_positions(5, grid)
#'
#' @export
generate_walker_positions <- function(n_walkers, grid, avoid_black = TRUE) {
  n <- nrow(grid)
  center <- ceiling(n / 2)

  positions <- list()

  for (i in seq_len(n_walkers)) {
    max_attempts <- 1000
    attempt <- 0

    repeat {
      pos <- c(sample(n, 1), sample(n, 1))
      attempt <- attempt + 1

      # Avoid center and black pixels
      is_center <- all(pos == c(center, center))
      is_black <- avoid_black && grid[pos[1], pos[2]] == 1

      if (!is_center && !is_black) {
        positions[[i]] <- pos
        break
      }

      if (attempt >= max_attempts) {
        logger::log_warn("Could not find valid position for walker {i} after {max_attempts} attempts")
        # Use a random position anyway
        positions[[i]] <- pos
        break
      }
    }
  }

  positions
}

#' Get Neighboring Positions
#'
#' Returns all valid neighbor positions for a given position.
#'
#' @param pos Integer vector of length 2 (row, col).
#' @param neighborhood Character. Either "4-hood" (NSEW) or "8-hood" (includes diagonals).
#'   Default is "4-hood".
#'
#' @return A list of integer vectors, each of length 2.
#'
#' @examples
#' get_neighbors(c(5, 5), "4-hood")  # Returns 4 neighbors
#' get_neighbors(c(5, 5), "8-hood")  # Returns 8 neighbors
#'
#' @export
get_neighbors <- function(pos, neighborhood = "4-hood") {
  if (neighborhood == "4-hood") {
    # North, South, East, West
    neighbors <- list(
      c(pos[1] - 1, pos[2]),     # North
      c(pos[1] + 1, pos[2]),     # South
      c(pos[1], pos[2] + 1),     # East
      c(pos[1], pos[2] - 1)      # West
    )
  } else if (neighborhood == "8-hood") {
    # N, S, E, W, NE, NW, SE, SW
    neighbors <- list(
      c(pos[1] - 1, pos[2]),     # North
      c(pos[1] + 1, pos[2]),     # South
      c(pos[1], pos[2] + 1),     # East
      c(pos[1], pos[2] - 1),     # West
      c(pos[1] - 1, pos[2] + 1), # NE
      c(pos[1] - 1, pos[2] - 1), # NW
      c(pos[1] + 1, pos[2] + 1), # SE
      c(pos[1] + 1, pos[2] - 1)  # SW
    )
  } else {
    stop("neighborhood must be either '4-hood' or '8-hood'")
  }

  neighbors
}

#' Check if Walker Touches a Black Pixel
#'
#' Checks if the walker's current position is on a black pixel.
#'
#' @param walker List. Walker object.
#' @param grid Numeric matrix. The simulation grid.
#' @param boundary Character. Boundary condition ("terminate" or "wrap").
#'
#' @return Logical. TRUE if walker is on a black pixel.
#'
#' @export
touches_black <- function(walker, grid, boundary = "terminate") {
  pixel_value <- get_pixel(grid, walker$pos, boundary)
  !is.na(pixel_value) && pixel_value == 1
}

#' Check if Walker Has Black Neighbor
#'
#' Checks if any of the walker's neighbors are black pixels.
#'
#' @param walker List. Walker object.
#' @param grid Numeric matrix. The simulation grid.
#' @param neighborhood Character. "4-hood" or "8-hood".
#' @param boundary Character. Boundary condition.
#'
#' @return Logical. TRUE if walker has at least one black neighbor.
#'
#' @export
has_black_neighbor <- function(walker, grid, neighborhood = "4-hood",
                                boundary = "terminate") {
  neighbors <- get_neighbors(walker$pos, neighborhood)

  for (neighbor_pos in neighbors) {
    pixel_value <- get_pixel(grid, neighbor_pos, boundary)
    if (!is.na(pixel_value) && pixel_value == 1) {
      return(TRUE)
    }
  }

  FALSE
}

#' Move Walker One Step
#'
#' Moves the walker one random step in the neighborhood.
#'
#' @param walker List. Walker object.
#' @param neighborhood Character. "4-hood" or "8-hood".
#' @param boundary Character. "terminate" or "wrap".
#'
#' @return Modified walker object.
#'
#' @export
step_walker <- function(walker, neighborhood = "4-hood", boundary = "terminate") {
  if (!walker$active) {
    return(walker)
  }

  neighbors <- get_neighbors(walker$pos, neighborhood)
  new_pos <- neighbors[[sample(length(neighbors), 1)]]

  # Handle boundary conditions
  if (boundary == "wrap") {
    new_pos <- wrap_position(new_pos, walker$grid_size)
  } else if (!is_within_bounds(new_pos, walker$grid_size)) {
    # Walker hit boundary - terminate
    walker$active <- FALSE
    walker$termination_reason <- "hit_boundary"
    logger::log_trace("Walker {walker$id} hit boundary at ({walker$pos[1]}, {walker$pos[2]})")
    return(walker)
  }

  walker$pos <- new_pos
  walker$steps <- walker$steps + 1L
  walker$path <- c(walker$path, list(new_pos))

  logger::log_trace("Walker {walker$id} moved to ({new_pos[1]}, {new_pos[2]}), step {walker$steps}")

  walker
}

#' Check Walker Termination Conditions
#'
#' Checks if the walker should terminate based on simulation rules.
#'
#' @param walker List. Walker object.
#' @param grid Numeric matrix. The simulation grid.
#' @param neighborhood Character. "4-hood" or "8-hood".
#' @param boundary Character. "terminate" or "wrap".
#' @param max_steps Integer. Maximum steps before forced termination. Default 10000.
#'
#' @return Modified walker object with updated active status.
#'
#' @export
check_termination <- function(walker, grid, neighborhood = "4-hood",
                               boundary = "terminate", max_steps = 10000L) {
  if (!walker$active) {
    return(walker)
  }

  # Check if on black pixel
  if (touches_black(walker, grid, boundary)) {
    walker$active <- FALSE
    walker$termination_reason <- "touched_black"
    logger::log_trace("Walker {walker$id} touched black pixel at ({walker$pos[1]}, {walker$pos[2]})")
    return(walker)
  }

  # Check if has black neighbor
  if (has_black_neighbor(walker, grid, neighborhood, boundary)) {
    walker$active <- FALSE
    walker$termination_reason <- "black_neighbor"
    logger::log_trace("Walker {walker$id} has black neighbor at ({walker$pos[1]}, {walker$pos[2]})")
    return(walker)
  }

  # Check max steps safety limit
  if (walker$steps >= max_steps) {
    walker$active <- FALSE
    walker$termination_reason <- "max_steps"
    logger::log_warn("Walker {walker$id} reached max steps limit at ({walker$pos[1]}, {walker$pos[2]})")
    return(walker)
  }

  walker
}
