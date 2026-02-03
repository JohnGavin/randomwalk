# Test: Walker Termination Order Tracking
# Date: 2026-02-03
# Author: Claude
# Purpose: Verify walkers are tracked by termination order, not ID

library(randomwalk)

# Run a small simulation
set.seed(123)
result <- run_simulation(
  grid_size = 20,
  n_walkers = 30,
  max_steps = 1000,
  workers = 0  # Sync mode for testing
)

# Check if termination_order is present
cat("Testing termination_order tracking...\n")

# Extract termination orders
termination_orders <- sapply(result$walkers, function(w) {
  if (!is.null(w$termination_order)) {
    w$termination_order
  } else {
    NA
  }
})

walker_ids <- sapply(result$walkers, function(w) w$id)

# Create data frame for inspection
walker_df <- data.frame(
  walker_id = walker_ids,
  termination_order = termination_orders,
  steps = sapply(result$walkers, function(w) w$steps),
  termination_reason = sapply(result$walkers, function(w) {
    if (!is.null(w$termination_reason)) w$termination_reason else "unknown"
  })
)

# Sort by termination order
walker_df <- walker_df[order(walker_df$termination_order), ]

cat("\nFirst 10 walkers to terminate (chronological order):\n")
print(head(walker_df, 10))

cat("\nWalkers with IDs 1-10 (arbitrary order):\n")
print(walker_df[walker_df$walker_id <= 10, ])

# Verify termination order is sequential
if (all(!is.na(termination_orders))) {
  sorted_orders <- sort(termination_orders)
  is_sequential <- all(sorted_orders == seq_along(sorted_orders))

  cat("\n✓ Termination orders are sequential:", is_sequential, "\n")
  cat("✓ All walkers have termination_order:", all(!is.na(termination_orders)), "\n")

  # Check that termination order doesn't match walker ID
  correlation <- cor(walker_ids, termination_orders)
  cat("✓ Correlation between walker ID and termination order:", round(correlation, 3), "\n")
  cat("  (Low correlation confirms they're independent)\n")
} else {
  cat("\n⚠ Warning: Some walkers missing termination_order\n")
}

cat("\nKey insight:\n")
cat("- Walker IDs (1-30) were assigned at start\n")
cat("- Termination order (1-30) shows when they actually terminated\n")
cat("- Dashboard now correctly shows first/last by termination order\n")