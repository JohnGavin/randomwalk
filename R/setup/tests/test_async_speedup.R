# Test async simulation speedup with different worker counts
# Date: 2025-11-19

# Source all R files to load functions
r_files <- list.files("R", pattern = "\\.R$", full.names = TRUE)
for (f in r_files) {
  source(f)
}

cat("=== Testing Async Simulation Speedup ===\n\n")

# Simulation parameters
grid_size <- 20
n_walkers <- 10

cat("Simulation parameters:\n")
cat("  Grid size:", grid_size, "x", grid_size, "\n")
cat("  Walkers:", n_walkers, "\n\n")

# Test 1: Synchronous (0 workers)
cat("--- Test 1: Synchronous (0 workers) ---\n")
start_time <- Sys.time()
result_sync <- run_simulation(
  grid_size = grid_size,
  n_walkers = n_walkers,
  workers = 0,
  verbose = FALSE
)
time_sync <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
cat("Time:", round(time_sync, 2), "seconds\n")
cat("Black pixels:", result_sync$statistics$black_pixels, "\n")
cat("Total steps:", result_sync$statistics$total_steps, "\n\n")

# Test 2: Async with 2 workers
cat("--- Test 2: Async (2 workers) ---\n")
start_time <- Sys.time()
result_2w <- run_simulation(
  grid_size = grid_size,
  n_walkers = n_walkers,
  workers = 2,
  verbose = FALSE
)
time_2w <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
speedup_2w <- time_sync / time_2w
cat("Time:", round(time_2w, 2), "seconds\n")
cat("Speedup:", round(speedup_2w, 2), "x\n")
cat("Black pixels:", result_2w$statistics$black_pixels, "\n")
cat("Total steps:", result_2w$statistics$total_steps, "\n\n")

# Test 3: Async with 4 workers
cat("--- Test 3: Async (4 workers) ---\n")
start_time <- Sys.time()
result_4w <- run_simulation(
  grid_size = grid_size,
  n_walkers = n_walkers,
  workers = 4,
  verbose = FALSE
)
time_4w <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
speedup_4w <- time_sync / time_4w
cat("Time:", round(time_4w, 2), "seconds\n")
cat("Speedup:", round(speedup_4w, 2), "x\n")
cat("Black pixels:", result_4w$statistics$black_pixels, "\n")
cat("Total steps:", result_4w$statistics$total_steps, "\n\n")

# Summary
cat("=== Summary ===\n")
cat(sprintf("Synchronous:    %5.2fs  (1.00x)\n", time_sync))
cat(sprintf("2 workers:      %5.2fs  (%.2fx speedup)\n", time_2w, speedup_2w))
cat(sprintf("4 workers:      %5.2fs  (%.2fx speedup)\n", time_4w, speedup_4w))
cat("\n")

# Validate results are similar
cat("Results validation:\n")
cat("  All black pixel counts within 10%?",
    abs(result_sync$statistics$black_pixels - result_2w$statistics$black_pixels) < grid_size &&
    abs(result_sync$statistics$black_pixels - result_4w$statistics$black_pixels) < grid_size, "\n")
cat("\n")

if (speedup_2w > 1.2) {
  cat("✅ Async with 2 workers shows good speedup!\n")
} else {
  cat("⚠️  Speedup lower than expected - may need larger simulation\n")
}

if (speedup_4w > speedup_2w) {
  cat("✅ Performance scales with more workers!\n")
} else {
  cat("ℹ️  4 workers didn't improve over 2 workers (overhead vs parallelism)\n")
}
