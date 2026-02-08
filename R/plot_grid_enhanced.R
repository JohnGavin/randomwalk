#' Enhanced Grid Plot with Arrival Time Coloring
#'
#' Visualizes the final state of the simulation grid with pixels colored
#' by their arrival time (termination order). Earlier arrivals are shown
#' in darker colors, later arrivals in lighter colors.
#'
#' @param result A simulation result object from run_simulation()
#' @param main Custom title. If NULL, auto-generates with pixel statistics
#' @param quantiles Number of quantiles for color grouping (default 5)
#' @param color_scheme Color palette name: "viridis", "plasma", "blues", "heat"
#'
#' @return A ggplot2 object
#' @importFrom grDevices gray.colors
#' @importFrom rlang .data
#' @export
plot_grid_enhanced <- function(result,
                              main = NULL,
                              quantiles = 5,
                              color_scheme = "viridis") {

  # Validate input
  if (!is.list(result) || !all(c("grid", "statistics", "walkers") %in% names(result))) {
    stop("Invalid result object. Must be output from run_simulation()")
  }

  grid_data <- result$grid
  n <- nrow(grid_data)
  stats <- result$statistics

  # Calculate pixel statistics
  black_count <- stats$black_pixels
  total_pixels <- n * n
  black_percent <- round(100 * black_count / total_pixels)  # Round to nearest percent

  # Generate title with pixel statistics
  if (is.null(main)) {
    main <- sprintf("DLA Fractal Pattern: %d black pixels (%d%% of %dx%d grid)",
                   black_count, black_percent, n, n)
  }

  # Create arrival time matrix
  arrival_times <- matrix(0, nrow = n, ncol = n)

  # Map walker termination orders to their final positions
  for (walker in result$walkers) {
    if (!walker$active && !is.null(walker$termination_order)) {
      # Get final position from path if available
      if (!is.null(walker$path) && length(walker$path) > 0) {
        final_pos <- walker$path[[length(walker$path)]]
      } else {
        final_pos <- walker$pos
      }

      # Only mark if position resulted in a black pixel
      if (walker$termination_reason %in% c("touched_black", "black_neighbor")) {
        x <- final_pos[1]
        y <- final_pos[2]

        # Check bounds
        if (x >= 1 && x <= n && y >= 1 && y <= n) {
          # Store termination order as arrival time
          if (grid_data[x, y] == 1) {
            arrival_times[x, y] <- walker$termination_order
          }
        }
      }
    }
  }

  # Create long format data frame
  grid_df <- expand.grid(x = 1:n, y = 1:n)
  grid_df$is_black <- as.vector(grid_data)
  grid_df$arrival_time <- as.vector(arrival_times)

  # For black pixels without arrival time (e.g., center pixel), set to 0
  grid_df$arrival_time[grid_df$is_black == 1 & grid_df$arrival_time == 0] <- 0

  # Calculate quantiles for black pixels only
  black_arrivals <- grid_df$arrival_time[grid_df$is_black == 1 & grid_df$arrival_time > 0]

  if (length(black_arrivals) > 0) {
    # Create quantile breaks
    breaks <- quantile(black_arrivals, probs = seq(0, 1, length.out = quantiles + 1))
    breaks[1] <- 0  # Include the center pixel in first quantile

    # Assign quantile groups
    grid_df$quantile_group <- cut(grid_df$arrival_time,
                                  breaks = unique(breaks),
                                  include.lowest = TRUE,
                                  labels = FALSE)
    grid_df$quantile_group[grid_df$is_black == 0] <- NA

    # Create color mapping - ensure colors are dark enough
    if (color_scheme == "viridis") {
      # Use darker part of viridis palette (skip the lightest yellows)
      all_colors <- viridisLite::viridis(quantiles * 2)
      colors <- all_colors[1:quantiles]  # Use darker half
    } else if (color_scheme == "plasma") {
      colors <- viridisLite::plasma(quantiles)
    } else if (color_scheme == "blues") {
      # Use darker blues
      colors <- RColorBrewer::brewer.pal(max(3, min(9, quantiles + 2)), "Blues")[3:(quantiles + 2)]
    } else {
      # Use grayscale for maximum contrast
      colors <- gray.colors(quantiles, start = 0.1, end = 0.7, rev = FALSE)
    }
  } else {
    # Fallback if no arrival times available
    grid_df$quantile_group <- ifelse(grid_df$is_black == 1, 1, NA)
    colors <- "black"
    quantiles <- 1
  }

  # Create the plot
  p <- ggplot2::ggplot(grid_df, ggplot2::aes(x = x, y = y)) +
    ggplot2::geom_tile(ggplot2::aes(fill = factor(.data$quantile_group)),
                      color = "gray90", linewidth = 0.05) +
    ggplot2::scale_fill_manual(
      values = colors,
      na.value = "gray60",  # Gray background for empty cells matching plot background
      guide = "none"  # No legend, using caption instead
    ) +
    ggplot2::coord_fixed() +
    ggplot2::labs(
      title = main,
      x = NULL,
      y = NULL
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      plot.title = ggplot2::element_text(hjust = 0.5, face = "bold", size = 12),
      panel.grid.major = ggplot2::element_line(color = "gray50", linewidth = 0.25),
      panel.grid.minor = ggplot2::element_blank(),
      panel.background = ggplot2::element_rect(fill = "gray60", color = NA),
      plot.background = ggplot2::element_rect(fill = "gray60", color = NA),
      axis.text = ggplot2::element_text(color = "black", size = 8),  # Show axis numbers
      axis.ticks = ggplot2::element_line(color = "black", linewidth = 0.3),  # Show tick marks
      plot.margin = ggplot2::margin(10, 10, 40, 10)  # Extra bottom margin for caption
    )

  # Calculate caption text but don't add to plot - let dashboard display it
  caption_text <- ""
  if (length(black_arrivals) > 0 && quantiles > 1) {
    # Calculate walker statistics for each quantile
    quantile_stats <- sapply(1:quantiles, function(q) {
      sum(grid_df$quantile_group == q, na.rm = TRUE)
    })

    caption_text <- sprintf(
      "Color indicates arrival order: darkest = earliest arrivals (center), lightest = latest arrivals (periphery)\nQuantile distribution: %s",
      paste(sprintf("Q%d: %d pixels", 1:quantiles, quantile_stats), collapse = ", ")
    )
  }

  # Return plot with caption text as an attribute
  attr(p, "caption") <- caption_text
  return(p)
}