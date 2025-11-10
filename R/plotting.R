#' Plot Final Grid State
#'
#' Visualizes the final state of the simulation grid, showing black pixels
#' that formed during the random walk simulation. Returns a ggplot2 object
#' for display via targets pipeline.
#'
#' @param result A simulation result object returned by \code{\link{run_simulation}}
#' @param main Character string for the plot title. Default is "Random Walk Simulation - Final Grid State"
#' @param col_palette A vector of two colors for white (0) and black (1) pixels.
#'   Default is c("white", "black")
#'
#' @return A ggplot2 object that can be displayed or saved
#'
#' @examples
#' \dontrun{
#' result <- run_simulation(grid_size = 20, n_walkers = 8)
#' p <- plot_grid(result)
#' print(p)  # Display the plot
#' }
#'
#' @export
plot_grid <- function(result,
                      main = "Random Walk Simulation - Final Grid State",
                      col_palette = c("white", "black")) {

  # Validate input
  if (!is.list(result) || !all(c("grid", "statistics") %in% names(result))) {
    logger::log_error("Invalid result object. Must be output from run_simulation()")
    stop("Invalid result object")
  }

  # Convert grid matrix to data frame for ggplot2
  grid_data <- result$grid
  n <- nrow(grid_data)

  # Create long format data frame
  grid_df <- expand.grid(x = 1:n, y = 1:n)
  grid_df$value <- as.vector(grid_data)

  # Create ggplot2 object
  p <- ggplot2::ggplot(grid_df, ggplot2::aes(x = x, y = y, fill = factor(value))) +
    ggplot2::geom_tile(color = "gray90", linewidth = 0.1) +
    ggplot2::scale_fill_manual(
      values = stats::setNames(col_palette, c("0", "1")),
      labels = c("Empty", "Black"),
      name = "State"
    ) +
    ggplot2::coord_fixed() +
    ggplot2::labs(
      title = main,
      x = "X",
      y = "Y"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      plot.title = ggplot2::element_text(hjust = 0.5, face = "bold"),
      panel.grid = ggplot2::element_blank(),
      legend.position = "right"
    )

  return(p)
}


#' Plot Walker Paths
#'
#' Visualizes the paths taken by all walkers during the simulation, showing
#' their starting positions, trajectories, and termination points.
#'
#' @param result A simulation result object returned by \code{\link{run_simulation}}
#' @param main Character string for the plot title. Default is "Walker Paths and Final Positions"
#' @param colors Optional vector of colors for walker paths. If NULL (default),
#'   uses rainbow colors
#' @param add_grid Logical indicating whether to add grid lines. Default is TRUE
#' @param grid_col Color for grid lines. Default is "lightgray"
#' @param lwd Line width for paths. Default is 1.5
#' @param cex_start Size of starting position markers. Default is 1.5
#' @param cex_end Size of ending position markers. Default is 2
#' @param legend Logical indicating whether to add a legend. Default is TRUE
#' @param legend_pos Position of legend. Default is "topright"
#'
#' @return Invisibly returns NULL. Called for side effect of creating a plot.
#'
#' @details
#' Walker paths are shown in different colors. Starting positions are marked
#' with circles. Ending positions are marked with squares (if terminated due
#' to black neighbor) or triangles (if hit boundary).
#'
#' @examples
#' \dontrun{
#' result <- run_simulation(grid_size = 20, n_walkers = 8)
#' plot_walker_paths(result)
#' }
#'
#' @export
plot_walker_paths <- function(result,
                               main = "Walker Paths and Final Positions",
                               colors = NULL,
                               add_grid = TRUE,
                               grid_col = "lightgray",
                               lwd = 1.5,
                               cex_start = 1.5,
                               cex_end = 2,
                               legend = TRUE,
                               legend_pos = "topright") {
  
  # Validate input
  if (!is.list(result) || !all(c("walkers", "parameters") %in% names(result))) {
    logger::log_error("Invalid result object. Must be output from run_simulation()")
    stop("Invalid result object")
  }
  
  grid_size <- result$parameters$grid_size
  walkers <- result$walkers
  n_walkers <- length(walkers)
  
  # Set colors
  if (is.null(colors)) {
    colors <- grDevices::rainbow(n_walkers)
  } else if (length(colors) < n_walkers) {
    logger::log_warn("Not enough colors provided, recycling colors")
    colors <- rep(colors, length.out = n_walkers)
  }
  
  # Create empty plot
  plot(1, type = "n", xlim = c(1, grid_size), ylim = c(1, grid_size),
       xlab = "X", ylab = "Y",
       main = main,
       asp = 1)
  
  # Add grid lines if requested
  if (add_grid) {
    grid(nx = grid_size, ny = grid_size, col = grid_col, lty = 1)
  }
  
  # Plot each walker's path
  for (i in seq_along(walkers)) {
    walker <- walkers[[i]]
    
    # Extract path as matrix
    if (length(walker$path) > 0) {
      path_matrix <- do.call(rbind, walker$path)
      
      # Plot path
      lines(path_matrix[, 2], path_matrix[, 1], col = colors[i], lwd = lwd)
      
      # Mark starting position
      points(path_matrix[1, 2], path_matrix[1, 1],
             pch = 19, col = colors[i], cex = cex_start)
    }
    
    # Mark ending position with different shapes based on termination reason
    end_pch <- if (walker$termination_reason == "black_neighbor") 15 else 17
    points(walker$pos[2], walker$pos[1],
           pch = end_pch, col = colors[i], cex = cex_end)
  }
  
  # Add legend
  if (legend) {
    legend(legend_pos,
           legend = c("Start", "End (black neighbor)", "End (boundary)"),
           pch = c(19, 15, 17),
           col = "black",
           cex = 0.8,
           bg = "white")
  }
  
  invisible(NULL)
}


#' Plot Simulation Results
#'
#' Creates a combined visualization showing both the final grid state and
#' walker paths in a side-by-side layout.
#'
#' @param result A simulation result object returned by \code{\link{run_simulation}}
#' @param ... Additional arguments passed to \code{\link{plot_grid}} and
#'   \code{\link{plot_walker_paths}}
#'
#' @return Invisibly returns the previous graphical parameters (from \code{par()}).
#'
#' @examples
#' \dontrun{
#' result <- run_simulation(grid_size = 20, n_walkers = 8)
#' plot_simulation(result)
#' }
#'
#' @export
plot_simulation <- function(result, ...) {
  # Save current par settings
  old_par <- par(no.readonly = TRUE)
  on.exit(par(old_par))
  
  # Set up side-by-side plots
  par(mfrow = c(1, 2))
  
  # Create both plots
  plot_grid(result, ...)
  plot_walker_paths(result, ...)
  
  invisible(old_par)
}
