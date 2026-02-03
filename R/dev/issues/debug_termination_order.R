# Debug: Why is termination_order not being set?
# Date: 2026-02-03

library(randomwalk)

# Test with minimal walkers
set.seed(123)
result <- run_simulation(
  grid_size = 10,
  n_walkers = 3,
  max_steps = 100,
  workers = 0  # Sync mode
)

# Check walker structure
cat("Walker 1 structure:\n")
str(result$walkers[[1]])

cat("\nWalker 2 structure:\n")
str(result$walkers[[2]])

cat("\nWalker 3 structure:\n")
str(result$walkers[[3]])

# Check if field exists at all
cat("\nChecking termination_order field existence:\n")
for (i in 1:3) {
  w <- result$walkers[[i]]
  cat("Walker", i, "- termination_order exists:", "termination_order" %in% names(w), "\n")
  if ("termination_order" %in% names(w)) {
    cat("  Value:", w$termination_order, "\n")
  }
}

cat("\n✓ If termination_order field exists but is NA, the field is being created but not set\n")
cat("✓ If field doesn't exist, create_walker isn't initializing it\n")