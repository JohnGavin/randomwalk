# Enable Custom Cachix Cache for Issue #34
# Date: 2025-11-20
# Purpose: Switch from read-only rstats-on-nix to our own randomwalk cache

library(gert)

cat("Switching to custom randomwalk Cachix cache...\n\n")

# Stage the workflow changes
gert::git_add(".github/workflows/nix-builder.yaml")
gert::git_add(".github/workflows/tests-r-via-nix.yaml")
gert::git_add("R/setup/enable_custom_cachix.R")
gert::git_add("R/setup/setup_custom_cachix.md")

cat("✅ Staged workflow changes\n\n")

# Commit
commit_msg <- "Enable custom Cachix cache for faster builds

Switched from read-only rstats-on-nix cache to our own
randomwalk Cachix cache with write permissions.

Changes:
- .github/workflows/nix-builder.yaml: Use randomwalk cache
- .github/workflows/tests-r-via-nix.yaml: Use randomwalk cache
- Added authToken from GitHub secrets

Expected impact:
- First build: ~17 min (build and PUSH to cache)
- Second+ builds: ~2-3 min (PULL from cache)
- 85% speedup after initial cache population

Related to #34"

gert::git_commit(commit_msg)

cat("✅ Committed changes\n\n")
cat("Commit message:\n")
cat(commit_msg, "\n\n")

# Show commit
log <- gert::git_log(max = 1)
cat("Commit:", log$commit[1], "\n\n")

# Push
cat("Pushing to trigger workflows...\n")
gert::git_push()

cat("\n✅ Pushed!\n\n")

cat("=== WHAT TO EXPECT ===\n\n")

cat("First Build (Run #96):\n")
cat("- Duration: ~17 min (same as before)\n")
cat("- Cachix: Building packages from source\n")
cat("- Cachix: PUSHING to https://randomwalk.cachix.org\n")
cat("- Look for: 'copying path ... to randomwalk.cachix.org'\n\n")

cat("Second Build (Run #97 - trigger with empty commit):\n")
cat("- Duration: ~2-3 min (85% faster!)\n")
cat("- Cachix: PULLING from https://randomwalk.cachix.org\n")
cat("- Look for: 'copying path ... from randomwalk.cachix.org'\n\n")

cat("Monitor at:\n")
cat("- Workflows: https://github.com/JohnGavin/randomwalk/actions\n")
cat("- Cachix: https://app.cachix.org/cache/randomwalk\n")
