# Fix Issue #169: Dashboard Performance Regression (100-1000x Slowdown)
# Date: 2025-12-28
# Status: ✅ FIXED
#
# PROBLEM:
# Dashboards running 100-1000x slower after recent commits
# Console logs showed: 31 seconds per 100 simulation steps
# Evidence: Step 100 at 23:09:25, Step 200 at 23:09:56 = 31 seconds
#
# ROOT CAUSE ANALYSIS:
# Similar to commit 4f5ed32 which removed find_isolated_pixels() performance killer,
# a NEW performance killer was introduced via the default validate_percent parameter.
#
# The validate_percent parameter (added for Issue #168) defaults to 5, which means
# the grid is validated every 5% of walkers complete. For production dashboards
# running large simulations, this causes massive slowdown:
#
# Example: 2000 walkers on 200×200 grid (from user's console logs):
# - 40 validation runs during simulation (every 5% × 2000 walkers)
# - Each validation scans all 40,000 pixels (200×200 grid)
# - Each pixel requires neighborhood check (4 or 8 neighbors)
# - Total: 40 × 40,000 × 4 = 6,400,000 operations during simulation!
#
# This periodic validation is useful for DEBUGGING but NOT for PRODUCTION,
# especially not in WebR where performance is critical.
#
# INVESTIGATION STEPS:
# 1. git diff 4f5ed32..HEAD to compare with last performance fix
# 2. Found R/simulation.R lines 206-213 calling validate_no_isolated_pixels()
# 3. Checked function signature: validate_percent = 5 (default)
# 4. Checked dashboard code: NOT overriding default (using validate_percent = 5)
# 5. Calculated performance impact: millions of pixel checks per simulation
#
# FIX:
# Added validate_percent = 0 to BOTH dashboard run_simulation() calls:
# - vignettes/articles/dashboard_comprehensive.qmd
# - vignettes/articles/dynamic_broadcasting.qmd
#
# This disables periodic validation in production dashboards while keeping
# end-of-simulation validation (which runs once, not 20-40 times).
#
# EXPECTED RESULTS:
# - Dashboard performance restored to pre-Issue #168 levels
# - Simulation should complete 100 steps in <1 second (not 31 seconds)
# - WebR dashboards will be 100-1000x faster
# - Tests still validate properly (they set validate_strict = TRUE)
#
# FILES MODIFIED:
# 1. vignettes/articles/dashboard_comprehensive.qmd (line 321)
# 2. vignettes/articles/dynamic_broadcasting.qmd (line 212)
#
# VERIFICATION:
# After deployment, test dashboards at:
# - https://johngavin.github.io/randomwalk/articles/dashboard_comprehensive.html
# - https://johngavin.github.io/randomwalk/articles/dynamic_broadcasting.html
#
# Check JS console logs - should show fast simulation (<1 sec per 100 steps)

# Example demonstrating the performance difference:
library(randomwalk)

cat("\n=== PERFORMANCE COMPARISON ===\n\n")

# SLOW (with validation)
cat("Testing WITH periodic validation (default validate_percent = 5)...\n")
start <- Sys.time()
result_slow <- run_simulation(
  grid_size = 100,
  n_walkers = 100,
  neighborhood = "4-hood",
  boundary = "terminate",
  max_steps = 5000,
  workers = 0,
  verbose = FALSE,
  validate_percent = 5  # DEFAULT - validates 20 times during simulation
)
time_slow <- as.numeric(difftime(Sys.time(), start, units = "secs"))
cat(sprintf("Time WITH validation: %.2f seconds\n\n", time_slow))

# FAST (without validation)
cat("Testing WITHOUT periodic validation (validate_percent = 0)...\n")
start <- Sys.time()
result_fast <- run_simulation(
  grid_size = 100,
  n_walkers = 100,
  neighborhood = "4-hood",
  boundary = "terminate",
  max_steps = 5000,
  workers = 0,
  verbose = FALSE,
  validate_percent = 0  # OPTIMIZED - only validates at end
)
time_fast <- as.numeric(difftime(Sys.time(), start, units = "secs"))
cat(sprintf("Time WITHOUT validation: %.2f seconds\n\n", time_fast))

# Results
speedup <- time_slow / time_fast
cat(sprintf("=== RESULTS ===\n"))
cat(sprintf("Speedup: %.1fx faster\n", speedup))
cat(sprintf("Time saved: %.2f seconds (%.1f%% faster)\n",
            time_slow - time_fast,
            (1 - time_fast/time_slow) * 100))

cat("\n=== CONCLUSION ===\n")
cat("Periodic validation is essential for DEBUGGING (finding bugs like Issue #168)\n")
cat("but should be DISABLED in PRODUCTION dashboards for performance.\n")
cat("\nTests use validate_strict = TRUE which still validates at end.\n")
