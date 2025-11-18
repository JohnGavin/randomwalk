# Benchmark: Async vs Sync Random Walk Simulation
# Compares performance of synchronous vs asynchronous execution
# Phase 1 target: 1.5-1.8x speedup with 2 workers

library(randomwalk)
library(bench)

# Benchmark parameters
GRID_SIZE <- 20
N_WALKERS <- 20
NEIGHBORHOOD <- "4-hood"
BOUNDARY <- "terminate"

cat("=== Random Walk Async Benchmark ===\n")
cat("Grid size:", GRID_SIZE, "x", GRID_SIZE, "\n")
cat("Walkers:", N_WALKERS, "\n")
cat("Neighborhood:", NEIGHBORHOOD, "\n")
cat("Boundary:", BOUNDARY, "\n\n")

# Run benchmark
cat("Running benchmark (this may take a few minutes)...\n\n")

results <- bench::mark(
  sync = {
    run_simulation(
      grid_size = GRID_SIZE,
      n_walkers = N_WALKERS,
      workers = 0,  # Synchronous
      neighborhood = NEIGHBORHOOD,
      boundary = BOUNDARY,
      verbose = FALSE
    )
  },
  async_2_workers = {
    run_simulation(
      grid_size = GRID_SIZE,
      n_walkers = N_WALKERS,
      workers = 2,  # 2 workers
      neighborhood = NEIGHBORHOOD,
      boundary = BOUNDARY,
      verbose = FALSE
    )
  },
  async_4_workers = {
    run_simulation(
      grid_size = GRID_SIZE,
      n_walkers = N_WALKERS,
      workers = 4,  # 4 workers
      neighborhood = NEIGHBORHOOD,
      boundary = BOUNDARY,
      verbose = FALSE
    )
  },
  iterations = 5,
  check = FALSE  # Don't check equality (async produces different random paths)
)

cat("\n=== Benchmark Results ===\n\n")
print(results)

# Calculate speedup
sync_time <- as.numeric(results$median[results$expression == "sync"])
async_2_time <- as.numeric(results$median[results$expression == "async_2_workers"])
async_4_time <- as.numeric(results$median[results$expression == "async_4_workers"])

speedup_2 <- sync_time / async_2_time
speedup_4 <- sync_time / async_4_time

cat("\n=== Speedup Analysis ===\n\n")
cat(sprintf("Sync median time:          %.2f seconds\n", sync_time))
cat(sprintf("Async (2 workers) time:    %.2f seconds\n", async_2_time))
cat(sprintf("Async (4 workers) time:    %.2f seconds\n", async_4_time))
cat(sprintf("Speedup (2 workers):       %.2fx\n", speedup_2))
cat(sprintf("Speedup (4 workers):       %.2fx\n", speedup_4))
cat("\n")

# Phase 1 target check
cat("=== Phase 1 Target ===\n")
cat("Expected speedup (2 workers): 1.5-1.8x\n")

if (speedup_2 >= 1.5) {
  cat(sprintf("✓ PASS: Achieved %.2fx speedup (>= 1.5x)\n", speedup_2))
} else {
  cat(sprintf("✗ FAIL: Achieved %.2fx speedup (< 1.5x)\n", speedup_2))
}

cat("\n")

# Save results
saveRDS(results, "benchmarks/benchmark_results.rds")
cat("Results saved to: benchmarks/benchmark_results.rds\n")
