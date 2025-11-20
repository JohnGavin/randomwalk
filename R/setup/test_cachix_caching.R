# Test Cachix Caching for Issue #34
# Date: 2025-11-20
# Purpose: Trigger another workflow run to verify Cachix speeds up subsequent builds

library(gh)

cat("Testing Cachix caching by triggering another nix-builder run...\n\n")

# Check current workflow runs for nix-builder
cat("Recent nix-builder workflow runs:\n")
runs <- gh::gh(
  "GET /repos/JohnGavin/randomwalk/actions/workflows/nix-builder.yaml/runs",
  per_page = 5
)

for (i in seq_len(min(3, length(runs$workflow_runs)))) {
  run <- runs$workflow_runs[[i]]
  duration_sec <- as.numeric(difftime(
    as.POSIXct(run$updated_at, format = "%Y-%m-%dT%H:%M:%SZ"),
    as.POSIXct(run$created_at, format = "%Y-%m-%dT%H:%M:%SZ"),
    units = "secs"
  ))
  duration_min <- round(duration_sec / 60, 1)

  cat(sprintf("  Run #%d: %s - %s (%.1f min)\n",
              run$run_number,
              run$conclusion %||% run$status,
              run$head_branch,
              duration_min))
}

cat("\n")

# Trigger a new workflow run via workflow_dispatch
# Note: This requires the workflow to have workflow_dispatch trigger
# If not available, we can push an empty commit to trigger it

cat("To test caching, you can either:\n")
cat("1. Push an empty commit to trigger the workflow:\n")
cat("   git commit --allow-empty -m 'Test Cachix caching'\n")
cat("   git push\n\n")

cat("2. Or manually trigger via GitHub UI:\n")
cat("   https://github.com/JohnGavin/randomwalk/actions/workflows/nix-builder.yaml\n")
cat("   Click 'Run workflow' dropdown\n\n")

cat("Expected results:\n")
cat("- First run: 16m 46s (compile from source)\n")
cat("- Second run: ~2-3 min (download from Cachix)\n")
cat("- Speedup: ~6-8x faster\n\n")

cat("Monitor at: https://github.com/JohnGavin/randomwalk/actions\n")
