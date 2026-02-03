# Debug: Add temporary output to trace termination_order
# Date: 2026-02-03

# Add this temporarily to simulation.R line 271-273:
cat("DEBUG: Walker", walker$id, "terminated\n")
cat("  Before: termination_order =", walker$termination_order, "\n")
termination_counter <- termination_counter + 1
walker$termination_order <- termination_counter
cat("  After: termination_order =", walker$termination_order, "\n")
cat("  Counter now =", termination_counter, "\n")

# And at line 294:
cat("DEBUG: Saving walker", i, "with termination_order =", walker$termination_order, "\n")

# Then at the end after line 353:
cat("\n=== FINAL CHECK ===\n")
for (i in 1:length(walkers)) {
  w <- walkers[[i]]
  cat("Walker", w$id, "has termination_order:",
      if("termination_order" %in% names(w)) w$termination_order else "MISSING", "\n")
}

# This will show us exactly when and how termination_order is set