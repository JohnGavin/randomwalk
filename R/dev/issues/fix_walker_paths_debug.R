#!/usr/bin/env Rscript
# Debug script to understand walker path structure and visibility issues
# Issue: Walker paths not showing in dashboard plots

library(randomwalk)

# Run a small simulation
set.seed(123)
result <- run_simulation(
  grid_size = 50,
  n_walkers = 10,
  initial_black_prob = 0.001,
  neighbor_threshold = 1,
  max_steps = 1000,
  boundary = "edge",
  prob_up = 0.25,
  prob_down = 0.25,
  prob_left = 0.25,
  prob_right = 0.25,
  workers = 0  # Sync mode
)

# Debug: Inspect walker structure
cat("=== Checking Walker Structure ===\n")
cat("Number of walkers:", length(result$walkers), "\n")
cat("First walker structure:\n")
str(result$walkers[[1]])

# Check if paths are being recorded
cat("\n=== Checking Path Recording ===\n")
for (i in 1:min(3, length(result$walkers))) {
  walker <- result$walkers[[i]]
  cat(sprintf("Walker %d:\n", i))
  cat("  - ID:", walker$id, "\n")
  cat("  - Active:", walker$active, "\n")
  cat("  - Termination order:", walker$termination_order, "\n")
  cat("  - Termination reason:", walker$termination_reason, "\n")
  cat("  - Path exists:", !is.null(walker$path), "\n")
  if (!is.null(walker$path)) {
    cat("  - Path length:", length(walker$path), "\n")
    if (length(walker$path) > 0) {
      cat("  - First position:", walker$path[[1]], "\n")
      cat("  - Last position:", walker$path[[length(walker$path)]], "\n")
    }
  } else {
    cat("  - Path is NULL!\n")
  }
  cat("  - Final position:", walker$pos, "\n\n")
}

# Check path plotting code directly
cat("=== Testing Path Plotting ===\n")

# Sort walkers by termination order
walkers_ordered <- result$walkers[order(sapply(result$walkers, function(w) {
  if (!is.null(w$termination_order)) w$termination_order else w$id
}))]

# Select first 3 walkers
first_3 <- walkers_ordered[1:3]

# Try to plot
pdf("walker_paths_debug.pdf", width = 8, height = 8)
par(bg = "gray70")
plot(1, type = "n", xlim = c(1, 50), ylim = c(1, 50),
     xlab = "X", ylab = "Y", main = "Debug: Walker Paths", asp = 1)
grid(nx = 50, ny = 50, col = "gray50", lty = 1, lwd = 0.5)

colors <- c("red", "blue", "darkgreen")

for (i in 1:3) {
  walker <- first_3[[i]]
  cat(sprintf("\nPlotting walker %d (ID: %d):\n", i, walker$id))

  # Check path
  if (!is.null(walker$path) && length(walker$path) > 0) {
    cat("  - Path found with", length(walker$path), "points\n")

    # Convert path to matrix
    path_matrix <- do.call(rbind, walker$path)
    cat("  - Path matrix dimensions:", dim(path_matrix), "\n")
    cat("  - First few points:\n")
    print(head(path_matrix, 3))

    # Try to draw the path
    lines(path_matrix[, 2], path_matrix[, 1], col = colors[i], lwd = 3)

    # Mark start
    points(path_matrix[1, 2], path_matrix[1, 1],
           pch = 21, bg = colors[i], col = "black", cex = 2)
  } else {
    cat("  - NO PATH DATA!\n")
  }

  # Mark end position
  if (!is.null(walker$pos)) {
    points(walker$pos[2], walker$pos[1],
           pch = 22, bg = colors[i], col = "black", cex = 2.5)
    cat("  - End position marked at:", walker$pos, "\n")
  }
}

dev.off()
cat("\nDebug plot saved to walker_paths_debug.pdf\n")

# Check if path recording is enabled in run_simulation
cat("\n=== Checking Simulation Code ===\n")
cat("Looking for path recording in simulation...\n")

# Let's check the source code
sim_source <- capture.output(print(run_simulation))
path_recording_lines <- grep("path", sim_source, value = TRUE, ignore.case = TRUE)
if (length(path_recording_lines) > 0) {
  cat("Found path-related code:\n")
  for (line in head(path_recording_lines, 5)) {
    cat("  ", line, "\n")
  }
} else {
  cat("NO path recording found in simulation code!\n")
  cat("This might be the issue - paths aren't being recorded.\n")
}