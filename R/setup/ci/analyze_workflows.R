# Analyze workflow differences and Cachix logs
# Date: 2025-11-20

library(gh)

cat("=== WORKFLOW COMPARISON ===\n\n")

cat("1. PKGDOWN (fast, ~5 min):\n")
cat("   - Uses: r-lib/actions (NOT Nix)\n")
cat("   - R packages: Installed from RSPM binaries (pre-compiled)\n")
cat("   - Caching: GitHub Actions cache + RSPM\n")
cat("   - No compilation needed\n\n")

cat("2. R-TESTS-VIA-NIX & NIX-BUILDER (slow, ~17 min):\n")
cat("   - Uses: Nix with nix-shell\n")
cat("   - R packages: Built via Nix (from source or Cachix)\n")
cat("   - Caching: Supposed to use Cachix (rstats-on-nix)\n")
cat("   - Issue: Appears to be rebuilding instead of using cache\n\n")

cat("=== CHECKING CACHIX LOGS ===\n\n")

# Get the latest workflow run
runs <- gh::gh(
  "GET /repos/JohnGavin/randomwalk/actions/workflows/nix-builder.yaml/runs",
  branch = "fix-issue-34-nix-optimization",
  per_page = 1
)

if (length(runs$workflow_runs) > 0) {
  run <- runs$workflow_runs[[1]]
  cat("Latest nix-builder run:\n")
  cat("  Run:", run$run_number, "\n")
  cat("  Status:", run$status, "/", run$conclusion %||% "in_progress", "\n")
  cat("  URL:", run$html_url, "\n\n")

  # Get jobs for this run
  jobs <- gh::gh(
    "GET /repos/JohnGavin/randomwalk/actions/runs/{run_id}/jobs",
    run_id = run$id
  )

  if (length(jobs$jobs) > 0) {
    job <- jobs$jobs[[1]]
    cat("Job:", job$name, "\n")
    cat("  Status:", job$status, "/", job$conclusion %||% "in_progress", "\n")
    cat("  Duration:", round(as.numeric(difftime(
      as.POSIXct(job$completed_at %||% Sys.time(), format = "%Y-%m-%dT%H:%M:%SZ"),
      as.POSIXct(job$started_at, format = "%Y-%m-%dT%H:%M:%SZ"),
      units = "mins"
    )), 1), "min\n\n")

    # Get logs
    cat("Fetching logs to check Cachix activity...\n")
    cat("Log URL:", job$html_url, "\n")

    # Try to get logs
    tryCatch({
      logs_url <- sprintf(
        "GET /repos/JohnGavin/randomwalk/actions/jobs/%s/logs",
        job$id
      )

      # Note: Logs are returned as plain text, not JSON
      # We'll need to search for Cachix messages
      cat("\nTo check Cachix logs manually:\n")
      cat("1. Visit:", job$html_url, "\n")
      cat("2. Look for 'cachix' step\n")
      cat("3. Search for:\n")
      cat("   - 'copying path ... to https://rstats-on-nix.cachix.org' (pushing)\n")
      cat("   - 'copying path ... from https://rstats-on-nix.cachix.org' (pulling)\n\n")

    }, error = function(e) {
      cat("Could not fetch logs automatically\n")
      cat("Manual check required at:", job$html_url, "\n\n")
    })
  }
}

cat("\n=== KEY QUESTIONS ===\n\n")
cat("1. Is Cachix PULLING cached packages?\n")
cat("   - Look for: 'copying path ... from https://rstats-on-nix.cachix.org'\n")
cat("   - If YES: Cachix is working\n")
cat("   - If NO: Cachix cache is empty or not being used\n\n")

cat("2. Is Cachix PUSHING built packages?\n")
cat("   - Look for: 'copying path ... to https://rstats-on-nix.cachix.org'\n")
cat("   - If YES: Future builds should be cached\n")
cat("   - If NO: Cache won't be populated\n\n")

cat("3. Are packages being built from source?\n")
cat("   - Look for: 'building' messages in nix-build step\n")
cat("   - Long build times = compiling from source\n\n")

cat("=== HYPOTHESIS ===\n\n")
cat("The rstats-on-nix Cachix cache likely:\n")
cat("- Has packages for default.nix (which is why old runs were faster)\n")
cat("- Does NOT have packages for default-ci.nix (new configuration)\n")
cat("- Is REBUILDING the 13 packages from source each time\n")
cat("- May not be PUSHING to cache (permission issue?)\n\n")

cat("=== SOLUTION OPTIONS ===\n\n")
cat("A. Wait for cache to populate (if it's pushing)\n")
cat("B. Use same nix configuration as cached builds\n")
cat("C. Switch workflows to use r-lib/actions like pkgdown\n")
cat("D. Investigate why Cachix isn't caching our builds\n")
