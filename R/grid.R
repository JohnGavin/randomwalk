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
