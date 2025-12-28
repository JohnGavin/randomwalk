# Test Suite: Issue #168 Fix - Isolated Pixels in Sync Mode
# Confirms the fix works across different grid sizes and configurations

devtools::load_all()
library(logger)
log_threshold(WARN)  # Reduce noise

cat("\n=== TESTING ISSUE #168 FIX ===\n")
cat("Testing isolated pixels bug fix across multiple scenarios\n\n")

test_scenarios <- list(
  list(name = "Small grid (50x50)", grid_size = 50, n_walkers = 25),
  list(name = "Medium grid (100x100)", grid_size = 100, n_walkers = 50),
  list(name = "Large grid (200x200)", grid_size = 200, n_walkers = 100),
  list(name = "Extra large (400x400)", grid_size = 400, n_walkers = 150)
)

results <- data.frame(
  scenario = character(),
  grid_size = integer(),
  n_walkers = integer(),
  black_pixels = integer(),
  isolated_pixels = integer(),
  elapsed = numeric(),
  stringsAsFactors = FALSE
)

for (scenario in test_scenarios) {
  cat(sprintf("Testing: %s...", scenario$name))

  start <- Sys.time()
  set.seed(123)
  result <- run_simulation(
    grid_size = scenario$grid_size,
    n_walkers = scenario$n_walkers,
    neighborhood = "4-hood",
    boundary = "terminate",
    max_steps = 5000,
    workers = 0,
    verbose = FALSE,
    quiet = TRUE  # Suppress logs for clean output
  )

  elapsed <- as.numeric(difftime(Sys.time(), start, units = "secs"))

  # Check for isolated pixels
  isolated <- find_isolated_pixels(result$grid, "4-hood")
  n_isolated <- length(isolated)

  results <- rbind(results, data.frame(
    scenario = scenario$name,
    grid_size = scenario$grid_size,
    n_walkers = scenario$n_walkers,
    black_pixels = result$statistics$black_pixels,
    isolated_pixels = n_isolated,
    elapsed = round(elapsed, 2),
    stringsAsFactors = FALSE
  ))

  if (n_isolated == 0) {
    cat(" ✅ PASS (", result$statistics$black_pixels, " black pixels)\n", sep = "")
  } else {
    cat(" ❌ FAIL (", n_isolated, " isolated pixels!)\n", sep = "")
  }
}

cat("\n=== RESULTS SUMMARY ===\n")
print(results, row.names = FALSE)

if (all(results$isolated_pixels == 0)) {
  cat("\n✅ ALL TESTS PASSED - No isolated pixels in any scenario!\n")
} else {
  cat("\n❌ SOME TESTS FAILED - Isolated pixels still present\n")
}

cat("\n=== TEST SUITE COMPLETE ===\n")
