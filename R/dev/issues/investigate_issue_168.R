# Investigation: Issue #168 - Isolated Pixels in Sync Mode
# Bug: Isolated pixels appearing in synchronous mode (workers=0)
# Date: 2025-12-28
# Status: ✅ FIXED
#
# ROOT CAUSE: R/simulation.R:191 was painting pixels black for ALL termination
# reasons except "hit_boundary", including "max_steps" which creates isolated pixels.
#
# FIX: Only paint black for "black_neighbor" terminations to maintain connectivity.
#
# BEFORE: if (!walker$active && walker$termination_reason != "hit_boundary")
# AFTER:  if (!walker$active && walker$termination_reason == "black_neighbor")
#
# RESULTS:
# - Before: 23 isolated pixels from 100 walkers
# - After: 0 isolated pixels, 4 black pixels (matching 4 "black_neighbor" terminations)
# - All 381 package tests pass
# - Tested across 4 grid sizes (50x50 to 400x400) - all pass
#
# This script reproduces the original bug for regression testing

# Load package from source
devtools::load_all()
library(logger)

# Enable detailed logging
log_threshold(DEBUG)

cat("\n=== REPRODUCING ISOLATED PIXELS BUG ===\n")
cat("Running exact example from step_distribution_analysis.qmd\n\n")

# Exact example from vignette that shows 20+ isolated pixels
set.seed(123)
result <- run_simulation(
  grid_size = 200,
  n_walkers = 100,
  neighborhood = "4-hood",
  boundary = "terminate",
  max_steps = 5000,
  workers = 0,  # SYNC MODE - should have ZERO isolated pixels
  verbose = TRUE
)

cat("\n=== RESULTS ===\n")
cat("Total walkers:", length(result$walkers), "\n")
cat("Black pixels:", result$statistics$black_pixels, "\n")

# Check for isolated pixels
isolated <- find_isolated_pixels(result$grid, "4-hood")

if (length(isolated) == 0) {
  cat("✅ SUCCESS: No isolated pixels found!\n")
} else {
  # isolated is a list of position vectors [row, col]
  cat("❌ FAILURE: Found", length(isolated), "isolated pixel(s)\n")

  # Analyze termination reasons for isolated pixels
  cat("\n=== ANALYZING ISOLATED PIXEL WALKERS ===\n")

  for (i in seq_along(isolated)) {
    pos <- isolated[[i]]

    # Find walker that created this pixel
    walker <- NULL
    for (w in result$walkers) {
      if (identical(w$pos, pos)) {
        walker <- w
        break
      }
    }

    if (!is.null(walker)) {
      cat(sprintf(
        "Walker %d at (%d,%d): reason=%s, steps=%d, active=%s\n",
        walker$id, pos[1], pos[2],
        walker$termination_reason %||% "unknown",
        walker$steps,
        walker$active
      ))
    } else {
      cat(sprintf("No walker found at (%d,%d) - UNEXPECTED!\n", pos[1], pos[2]))
    }
  }

  # Summary statistics
  cat("\n=== TERMINATION REASON SUMMARY FOR ALL WALKERS ===\n")
  termination_counts <- table(sapply(result$walkers, function(w) {
    w$termination_reason %||% "unknown"
  }))
  print(termination_counts)
}

cat("\n=== INVESTIGATION COMPLETE ===\n")
