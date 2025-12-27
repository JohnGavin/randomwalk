#' Initialize a Grid
#'
#' Creates an n x n grid for the random walk simulation. By default, the center
#' pixel is set to black (1), and all other pixels are white (0).
#'
#' @param n Integer. The size of the grid (n x n). Must be >= 3.
#' @param center_black Logical. If TRUE, initializes the center pixel as black.
#'   Default is TRUE.
#'
#' @return A numeric matrix of size n x n with 0 (white) and 1 (black) values.
#'
#' @examples
#' grid <- initialize_grid(10)
#' grid[5, 5]  # Center pixel should be 1 (black)
#'
#' @export
initialize_grid <- function(n, center_black = TRUE) {
  if (!is.numeric(n) || length(n) != 1 || n < 3) {
    logger::log_error("Grid size must be a single integer >= 3")
    stop("Grid size must be a single integer >= 3")
  }

  logger::log_info("Initializing grid of size {n}x{n}")

  grid <- matrix(0, nrow = n, ncol = n)

  if (center_black) {
    center <- ceiling(n / 2)
    grid[center, center] <- 1
    logger::log_debug("Set center pixel ({center}, {center}) to black")
  }

  grid
}

#' Check if a Position is Within Grid Bounds
#'
#' @param pos Integer vector of length 2 (row, col).
#' @param n Integer. Grid size.
#'
#' @return Logical. TRUE if position is within bounds, FALSE otherwise.
#'
#' @examples
#' is_within_bounds(c(5, 5), 10)  # TRUE
#' is_within_bounds(c(0, 5), 10)  # FALSE
#' is_within_bounds(c(11, 5), 10) # FALSE
#'
#' @export
is_within_bounds <- function(pos, n) {
  pos[1] >= 1 && pos[1] <= n && pos[2] >= 1 && pos[2] <= n
}

#' Wrap Position Around Grid Boundaries (Torus Topology)
#'
#' @param pos Integer vector of length 2 (row, col).
#' @param n Integer. Grid size.
#'
#' @return Integer vector of length 2 with wrapped coordinates.
#'
#' @examples
#' wrap_position(c(0, 5), 10)   # c(10, 5)
#' wrap_position(c(11, 5), 10)  # c(1, 5)
#' wrap_position(c(5, 0), 10)   # c(5, 10)
#'
#' @export
wrap_position <- function(pos, n) {
  c(
    ((pos[1] - 1) %% n) + 1,
    ((pos[2] - 1) %% n) + 1
  )
}

#' Get Pixel Value from Grid
#'
#' Retrieves the value at a given position, handling boundary conditions.
#'
#' @param grid Numeric matrix. The simulation grid.
#' @param pos Integer vector of length 2 (row, col).
#' @param boundary Character. Either "terminate" or "wrap". Default is "terminate".
#'
#' @return Integer. The pixel value (0 or 1), or NA if out of bounds with
#'   "terminate" boundary.
#'
#' @examples
#' grid <- initialize_grid(10)
#' get_pixel(grid, c(5, 5))  # 1 (center is black)
#' get_pixel(grid, c(0, 5))  # NA (out of bounds with terminate)
#' get_pixel(grid, c(0, 5), boundary = "wrap")  # Value from wrapped position
#'
#' @export
get_pixel <- function(grid, pos, boundary = "terminate") {
  n <- nrow(grid)

  if (boundary == "wrap") {
    pos <- wrap_position(pos, n)
  } else if (!is_within_bounds(pos, n)) {
    return(NA_integer_)
  }

  grid[pos[1], pos[2]]
}

#' Set Pixel Value in Grid
#'
#' Sets the value at a given position to black (1).
#'
#' @param grid Numeric matrix. The simulation grid.
#' @param pos Integer vector of length 2 (row, col).
#' @param boundary Character. Either "terminate" or "wrap". Default is "terminate".
#'
#' @return Modified grid matrix.
#'
#' @examples
#' grid <- initialize_grid(10)
#' grid <- set_pixel_black(grid, c(3, 3))
#' grid[3, 3]  # 1
#'
#' @export
set_pixel_black <- function(grid, pos, boundary = "terminate") {
  n <- nrow(grid)

  if (boundary == "wrap") {
    pos <- wrap_position(pos, n)
  } else if (!is_within_bounds(pos, n)) {
    logger::log_warn("Attempting to set pixel outside grid bounds: ({pos[1]}, {pos[2]})")
    return(grid)
  }

  grid[pos[1], pos[2]] <- 1
  logger::log_trace("Set pixel ({pos[1]}, {pos[2]}) to black")
  grid
}

#' Count Black Pixels in Grid
#'
#' @param grid Numeric matrix. The simulation grid.
#'
#' @return Integer. Number of black pixels.
#'
#' @examples
#' grid <- initialize_grid(10)
#' count_black_pixels(grid)  # 1 (only center)
#'
#' @export
count_black_pixels <- function(grid) {
  sum(grid == 1)
}

#' Get Percentage of Black Pixels
#'
#' @param grid Numeric matrix. The simulation grid.
#'
#' @return Numeric. Percentage of black pixels (0-100).
#'
#' @examples
#' grid <- initialize_grid(10)
#' get_black_percentage(grid)  # 1% for 10x10 grid
#'
#' @export
get_black_percentage <- function(grid) {
  (count_black_pixels(grid) / length(grid)) * 100
}

#' Validate Grid State for Isolated Pixels
#'
#' Checks that no black pixel is completely isolated (has no black neighbors).
#' An isolated pixel indicates a bug in the simulation logic. Also validates
#' that the grid has at least one black pixel, as the number of black pixels
#' should increase monotonically from the initial center pixel.
#'
#' @param grid Numeric matrix representing the grid.
#' @param neighborhood Character, "4-hood" or "8-hood" for neighbor checking.
#'   Default is "4-hood".
#' @param strict Logical, if TRUE throws error on isolation, if FALSE logs
#'   warning. Default FALSE.
#'
#' @return Logical, TRUE if valid (no isolated pixels), FALSE otherwise.
#'
#' @examples
#' grid <- initialize_grid(10)
#' validate_no_isolated_pixels(grid)  # TRUE for single center pixel initially
#'
#' # Create invalid grid with isolated pixel
#' bad_grid <- initialize_grid(10, center_black = FALSE)
#' bad_grid[3, 3] <- 1
#' validate_no_isolated_pixels(bad_grid)  # FALSE - isolated pixel
#'
#' @export
validate_no_isolated_pixels <- function(grid, neighborhood = "4-hood", strict = FALSE) {
  # Get all black pixel positions
  black_positions <- which(grid == 1, arr.ind = TRUE)

  # Grid should always have at least 1 black pixel (center initialization)
  # If there are no black pixels, this is a serious bug
  if (nrow(black_positions) == 0) {
    msg <- "Grid has no black pixels - this should never happen (monotonically increasing)"
    logger::log_error(msg)
    if (strict) {
      stop(msg)
    }
    return(FALSE)
  }

  # If only 1 black pixel exists (initial center pixel before any walker terminates),
  # this is valid - skip validation until walkers complete
  if (nrow(black_positions) == 1) {
    logger::log_trace("Only 1 black pixel (initial state), skipping isolation check")
    return(TRUE)
  }

  n <- nrow(grid)
  isolated_pixels <- list()

  for (i in seq_len(nrow(black_positions))) {
    pos <- black_positions[i, ]

    # Get neighbors for this position
    neighbors <- get_neighbors(pos, neighborhood)

    # Check if any neighbor is black
    has_black_neighbor <- FALSE
    for (neighbor_pos in neighbors) {
      # Check bounds
      if (is_within_bounds(neighbor_pos, n)) {
        if (grid[neighbor_pos[1], neighbor_pos[2]] == 1) {
          has_black_neighbor <- TRUE
          break
        }
      }
    }

    # If no black neighbors, this pixel is isolated
    if (!has_black_neighbor) {
      isolated_pixels <- c(isolated_pixels, list(pos))
    }
  }

  # Handle isolated pixels
  if (length(isolated_pixels) > 0) {
    positions_str <- paste(
      sapply(isolated_pixels, function(p) sprintf("(%d,%d)", p[1], p[2])),
      collapse = ", "
    )

    msg <- sprintf(
      "Found %d isolated black pixel(s) with no black neighbors: %s",
      length(isolated_pixels),
      positions_str
    )

    if (strict) {
      logger::log_error(msg)
      stop(msg)
    } else {
      logger::log_warn(msg)
      return(FALSE)
    }
  }

  return(TRUE)
}


#' Validate Termination Position
#'
#' Checks if a position is valid for termination (has at least one black neighbor
#' or is the initial center pixel). Used in async mode to prevent isolated pixels
#' when workers operate on stale grid snapshots.
#'
#' @param pos Integer vector of length 2 (row, col). Position to validate.
#' @param grid Numeric matrix. Current grid state.
#' @param neighborhood Character. "4-hood" or "8-hood". Default "4-hood".
#'
#' @return Logical. TRUE if position is valid for termination, FALSE otherwise.
#'
#' @details
#' A termination position is valid if:
#' 1. The position itself is already black (touching black), OR
#' 2. The position has at least one black neighbor
#'
#' This prevents the creation of isolated black pixels in async mode where
#' workers may have stale grid snapshots.
#'
#' @examples
#' grid <- initialize_grid(10)
#' # Center (5,5) is black, so (5,6) has a black neighbor
#' validate_termination_position(c(5, 6), grid, "4-hood")  # TRUE
#' # Position (1,1) is far from center - no black neighbors
#' validate_termination_position(c(1, 1), grid, "4-hood")  # FALSE
#'
#' @seealso \code{\link{validate_no_isolated_pixels}}
#'
#' @export
validate_termination_position <- function(pos, grid, neighborhood = "4-hood") {
  n <- nrow(grid)

  # Check if position itself is black (touching black pixel)
  if (grid[pos[1], pos[2]] == 1) {
    logger::log_trace("Position ({pos[1]}, {pos[2]}) is valid: already black")
    return(TRUE)
  }

  # Check if position has at least one black neighbor
  neighbors <- get_neighbors(pos, neighborhood)

  for (neighbor_pos in neighbors) {
    if (is_within_bounds(neighbor_pos, n)) {
      if (grid[neighbor_pos[1], neighbor_pos[2]] == 1) {
        logger::log_trace(
          "Position ({pos[1]}, {pos[2]}) is valid: has black neighbor at ({neighbor_pos[1]}, {neighbor_pos[2]})"
        )
        return(TRUE)
      }
    }
  }

  # No black neighbors found - this would create an isolated pixel
  # Note: This is expected with async static mode (workers have stale grid snapshots)
  logger::log_debug(
    "Position ({pos[1]}, {pos[2]}) is INVALID: would create isolated pixel (no black neighbors in {neighborhood})"
  )
  return(FALSE)
}

#' Find Isolated Pixels in Grid
#'
#' Scans the grid to find black pixels that have no black neighbors,
#' which violates the connectivity requirement for DLA simulations.
#'
#' @param grid Numeric matrix representing the grid state (0 = white, 1 = black)
#' @param neighborhood Character string specifying neighborhood type:
#'   \code{"4-hood"} (orthogonal) or \code{"8-hood"} (includes diagonals)
#'
#' @return List of isolated pixel positions (each element is a 2-element numeric vector with row and column indices).
#'   Returns empty list if no isolated pixels found.
#'
#' @details
#' This function is useful for:
#' \itemize{
#'   \item Debugging WebR/Shiny reactive timing issues
#'   \item Validating grid state after async simulations
#'   \item Testing grid connectivity requirements
#' }
#'
#' A pixel is considered isolated if:
#' \itemize{
#'   \item It is black (value = 1)
#'   \item None of its neighbors (in the specified neighborhood) are black
#' }
#'
#' Note: The center pixel is never considered isolated (it's the seed).
#'
#' @examples
#' grid <- initialize_grid(10)
#' grid[3, 3] <- 1  # Add isolated pixel far from center
#' isolated <- find_isolated_pixels(grid, "4-hood")
#' length(isolated)  # Should be 1
#'
#' @seealso \code{\link{validate_termination_position}}, \code{\link{validate_no_isolated_pixels}}
#'
#' @export
find_isolated_pixels <- function(grid, neighborhood = "4-hood") {
  black_positions <- which(grid == 1, arr.ind = TRUE)

  # No black pixels or only center pixel - no isolated pixels possible
  if (nrow(black_positions) <= 1) {
    return(list())
  }

  n <- nrow(grid)
  isolated <- list()

  for (i in seq_len(nrow(black_positions))) {
    pos <- black_positions[i, ]
    neighbors <- get_neighbors(pos, neighborhood)

    has_black_neighbor <- FALSE
    for (neighbor_pos in neighbors) {
      if (is_within_bounds(neighbor_pos, n)) {
        if (grid[neighbor_pos[1], neighbor_pos[2]] == 1) {
          has_black_neighbor <- TRUE
          break
        }
      }
    }

    if (!has_black_neighbor) {
      isolated <- c(isolated, list(pos))
      logger::log_debug(
        "Found isolated pixel at ({pos[1]}, {pos[2]})"
      )
    }
  }

  if (length(isolated) > 0) {
    logger::log_warn(
      "Grid has {length(isolated)} isolated pixel(s)"
    )
  }

  isolated
}
