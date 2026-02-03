# Trace: Add debug output to understand termination order
# Date: 2026-02-03

library(randomwalk)

# Temporarily add logging
trace(randomwalk:::check_termination_fast, quote({
  if (!walker$active && is.null(walker$termination_reason)) {
    cat("Walker", walker$id, "terminating with reason:", walker$termination_reason, "\n")
  }
}), at = 1)

# Run small test
set.seed(123)
result <- run_simulation(
  grid_size = 10,
  n_walkers = 3,
  max_steps = 100,
  workers = 0
)

untrace(randomwalk:::check_termination_fast)

# Check results
cat("\n=== Final Walker States ===\n")
for (i in 1:3) {
  w <- result$walkers[[i]]
  cat("Walker", i, ": steps=", w$steps,
      ", termination_order=",
      if("termination_order" %in% names(w)) w$termination_order else "MISSING",
      ", reason=", w$termination_reason, "\n")
}

# Check if issue is with walkers that terminate at step 0
cat("\n=== Walkers that terminated immediately (0 steps) ===\n")
for (i in 1:length(result$walkers)) {
  w <- result$walkers[[i]]
  if (w$steps == 0) {
    cat("Walker", w$id, "terminated immediately with reason:", w$termination_reason, "\n")
    cat("  Position:", w$pos, "\n")
    cat("  Grid size:", w$grid_size, "\n")
    cat("  On boundary?:", (w$pos[1] == 1 || w$pos[1] == w$grid_size ||
                           w$pos[2] == 1 || w$pos[2] == w$grid_size), "\n")
  }
}