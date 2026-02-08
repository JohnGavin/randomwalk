# Test walker path color stability issue
# The dashboard should assign consistent colors to walkers based on their termination order

library(randomwalk)

# Run a small simulation
set.seed(123)
result <- run_simulation(
  n_walkers = 50,
  grid_size = 30,
  max_steps = 1000
)

# Test color assignment logic from dashboard
distinct_colors <- c("red", "blue", "darkgreen", "purple", "orange",
                     "brown", "deeppink", "darkcyan", "darkmagenta", "darkblue",
                     "darkred", "forestgreen", "black", "goldenrod", "darkviolet")

# Create color map based on termination order
color_map <- list()
for (walker in result$walkers) {
  if (!is.null(walker$termination_order)) {
    term_order <- walker$termination_order
    # Use modulo to cycle through colors if more walkers than colors
    color_index <- ((term_order - 1) %% length(distinct_colors)) + 1
    color_map[[as.character(term_order)]] <- distinct_colors[color_index]
  }
}

# Test that walker colors are stable across different selections
test_selections <- list(
  first_10 = 1:10,
  first_20 = 1:20,
  last_10 = 41:50,
  mixed = c(1:5, 46:50)
)

# Function to get colors for a selection
get_colors_for_selection <- function(walker_indices) {
  walkers_ordered <- result$walkers[order(sapply(result$walkers, function(w) {
    if (!is.null(w$termination_order)) w$termination_order else w$id
  }))]

  filtered_walkers <- walkers_ordered[walker_indices]

  colors <- sapply(filtered_walkers, function(walker) {
    color_map[[as.character(walker$termination_order)]]
  })

  names(colors) <- sapply(filtered_walkers, function(w) w$termination_order)
  colors
}

# Test each selection
cat("Testing color stability across different walker selections:\n")
cat(paste(rep("=", 60), collapse=""), "\n")

all_results <- list()
for (name in names(test_selections)) {
  indices <- test_selections[[name]]
  colors <- get_colors_for_selection(indices)
  all_results[[name]] <- colors

  cat("\nSelection:", name, "(indices", paste(range(indices), collapse="-"), ")\n")
  cat("First 5 walker colors:\n")
  print(head(colors, 5))
}

# Check for consistency
cat("\n", paste(rep("=", 60), collapse=""), "\n")
cat("Checking color consistency for overlapping walkers:\n\n")

# Compare first_10 and first_20 (walkers 1-10 should have same colors)
first_10_colors <- all_results$first_10
first_20_colors <- all_results$first_20

common_walkers <- intersect(names(first_10_colors), names(first_20_colors))
if (length(common_walkers) > 0) {
  cat("Comparing first_10 vs first_20 for walkers", paste(head(common_walkers, 3), collapse=", "), ":\n")

  for (walker_id in head(common_walkers, 3)) {
    color_10 <- first_10_colors[walker_id]
    color_20 <- first_20_colors[walker_id]
    match_symbol <- if(color_10 == color_20) "✓" else "✗"
    cat(sprintf("  Walker %s: %s (first_10) vs %s (first_20) %s\n",
                walker_id, color_10, color_20, match_symbol))
  }
}

# Verify the color cycling works correctly
cat("\n", paste(rep("=", 60), collapse=""), "\n")
cat("Testing color cycling (15 colors, so walker 1 and 16 should have same color):\n\n")

# Check if we have walkers with termination orders that differ by 15
for (i in 1:35) {
  walker_i <- as.character(i)
  walker_i_plus_15 <- as.character(i + 15)

  if (walker_i %in% names(color_map) && walker_i_plus_15 %in% names(color_map)) {
    color_i <- color_map[[walker_i]]
    color_i_plus_15 <- color_map[[walker_i_plus_15]]
    match_symbol <- if(color_i == color_i_plus_15) "✓" else "✗"
    cat(sprintf("Walker %2d color: %-12s | Walker %2d color: %-12s %s\n",
                i, color_i, i + 15, color_i_plus_15, match_symbol))
  }
}

cat("\n", paste(rep("=", 60), collapse=""), "\n")
cat("Summary:\n")
cat("- Total walkers:", length(result$walkers), "\n")
cat("- Walkers with termination_order:", sum(sapply(result$walkers, function(w) !is.null(w$termination_order))), "\n")
cat("- Unique colors available:", length(distinct_colors), "\n")
cat("- Color map entries:", length(color_map), "\n")

# Visual test - plot a few walkers to see if colors look distinct
if (interactive()) {
  cat("\nGenerating visual test plot...\n")

  # Plot first 15 walkers to see all distinct colors
  walkers_ordered <- result$walkers[order(sapply(result$walkers, function(w) {
    if (!is.null(w$termination_order)) w$termination_order else w$id
  }))]

  first_15 <- walkers_ordered[1:min(15, length(walkers_ordered))]

  # Create plot
  plot(1, type = "n", xlim = c(1, 30), ylim = c(1, 30),
       xlab = "X", ylab = "Y",
       main = "First 15 Walker Paths - Color Stability Test",
       asp = 1)

  grid(nx = 30, ny = 30, col = "gray90", lty = 1, lwd = 0.3)

  # Plot each walker path with its assigned color
  for (i in seq_along(first_15)) {
    walker <- first_15[[i]]
    walker_color <- color_map[[as.character(walker$termination_order)]]

    if (!is.null(walker$path) && length(walker$path) > 0) {
      path_matrix <- do.call(rbind, walker$path)
      points(path_matrix[, 2], path_matrix[, 1],
             pch = 16, col = walker_color, cex = 0.8)

      # Add termination order label
      text(path_matrix[nrow(path_matrix), 2],
           path_matrix[nrow(path_matrix), 1],
           walker$termination_order, col = walker_color, cex = 0.7, font = 2)
    }
  }

  cat("Visual test plot created - each walker labeled with its termination order\n")
}

cat("\nTest complete. Color stability analysis finished.\n")