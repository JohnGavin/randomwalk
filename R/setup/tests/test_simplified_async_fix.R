# Test Simplified Async Fix (No nanonext sockets)
# Date: 2025-11-19
# Purpose: Verify async simulation works without nanonext pub/sub

# Load package
library(randomwalk)
library(logger)

log_threshold(INFO)

cat("\n=== Testing Simplified Async Simulation ===\n\n")

# Test 1: Small async simulation
cat("Test 1: Small async simulation (2 workers, 3 walkers)...\n")
result <- tryCatch({
  run_simulation(
    grid_size = 10,
    n_walkers = 3,
    workers = 2,
    neighborhood = "4-hood",
    boundary = "terminate",
    verbose = TRUE
  )
}, error = function(e) {
  cat("ERROR:", e$message, "\n")
  NULL
})

if (!is.null(result)) {
  cat("\n✅ Test 1 PASSED\n")
  cat("Completed walkers:", result$statistics$completed_walkers, "/", result$statistics$total_walkers, "\n")
  cat("Black pixels:", result$statistics$black_pixels, "\n")
  cat("Elapsed time:", round(result$statistics$elapsed_time_secs, 2), "seconds\n")
} else {
  cat("\n❌ Test 1 FAILED\n")
}

# Test 2: Single worker
cat("\nTest 2: Single worker async simulation...\n")
result2 <- tryCatch({
  run_simulation(
    grid_size = 8,
    n_walkers = 2,
    workers = 1,
    neighborhood = "4-hood",
    boundary = "terminate",
    verbose = FALSE
  )
}, error = function(e) {
  cat("ERROR:", e$message, "\n")
  NULL
})

if (!is.null(result2)) {
  cat("\n✅ Test 2 PASSED\n")
  cat("Completed walkers:", result2$statistics$completed_walkers, "/", result2$statistics$total_walkers, "\n")
} else {
  cat("\n❌ Test 2 FAILED\n")
}

cat("\n=== Tests Complete ===\n")
