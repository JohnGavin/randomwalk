#!/usr/bin/env Rscript
# Debug walker selection bug in dashboard
# Issue: Only first walker path renders, others show only end symbols

devtools::load_all()
set.seed(123)

# Run simulation to get test data
result <- run_simulation(
  grid_size = 50,
  n_walkers = 20,
  max_steps = 500,
  workers = 0
)

n_walkers <- length(result$walkers)
cat("Total walkers:", n_walkers, "\n\n")

# Sort walkers by termination order
walkers_ordered <- result$walkers[order(sapply(result$walkers, function(w) {
  if (!is.null(w$termination_order)) w$termination_order else w$id
}))]

# Test "Last N" selection with different values
for (last_n in c(1, 2, 3, 11)) {
  cat("=== Testing Last", last_n, "walkers ===\n")

  # Calculate indices for last N
  walker_indices <- (n_walkers - last_n + 1):n_walkers
  cat("Walker indices:", paste(walker_indices, collapse=", "), "\n")

  # Get selected walkers
  filtered_walkers <- walkers_ordered[walker_indices]

  # Check each walker
  for (i in seq_along(filtered_walkers)) {
    walker <- filtered_walkers[[i]]
    cat(sprintf("  Walker %d (index %d):\n", i, walker_indices[i]))
    cat("    - ID:", walker$id, "\n")
    cat("    - Termination order:", walker$termination_order, "\n")
    cat("    - Has path:", !is.null(walker$path), "\n")
    if (!is.null(walker$path)) {
      cat("    - Path length:", length(walker$path), "\n")
    }
    cat("    - Final position:", walker$pos, "\n")
  }
  cat("\n")
}

# Check if the issue is overlapping indices when both first_n and last_n are used
cat("=== Testing overlap with First 5 and Last 3 ===\n")
first_n <- 5
last_n <- 3

walker_indices <- unique(c(
  if(first_n > 0) 1:first_n else NULL,
  if(last_n > 0) (n_walkers - last_n + 1):n_walkers else NULL
))

cat("Combined indices:", paste(walker_indices, collapse=", "), "\n")
cat("Total selected:", length(walker_indices), "\n\n")

# Check if paths are actually being stored
cat("=== Path storage check ===\n")
paths_exist <- sapply(walkers_ordered, function(w) !is.null(w$path))
cat("Walkers with paths:", sum(paths_exist), "/", length(walkers_ordered), "\n")

# Show first few and last few
cat("First 5 have paths:", paste(paths_exist[1:5], collapse=", "), "\n")
cat("Last 5 have paths:", paste(paths_exist[(n_walkers-4):n_walkers], collapse=", "), "\n")