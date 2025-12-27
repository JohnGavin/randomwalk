# Trigger caching test with empty commit
# Date: 2025-11-20

library(gert)
library(usethis)

cat("Creating empty commit to test Cachix caching...\n\n")

# Create empty commit (nothing to stage)
# Use --allow-empty via bash since gert doesn't support it
system("git commit --allow-empty -m 'Test Cachix caching for default-ci.nix

Empty commit to trigger nix-builder workflow and verify that
Cachix properly caches the default-ci.nix environment.

Expected: ~2-3 min (vs 17.1 min on first build)'")

cat("✅ Empty commit created\n\n")

# Push to trigger workflows
cat("Pushing to trigger workflows...\n")
gert::git_push()

cat("\n✅ Pushed!\n\n")

cat("Monitor workflows at:\n")
cat("https://github.com/JohnGavin/randomwalk/actions\n\n")

cat("What to look for:\n")
cat("1. nix-builder workflow starts\n")
cat("2. Look for 'Run nix-build' step duration\n")
cat("3. Should be ~2-3 min if Cachix is working\n")
cat("4. If still ~17 min, Cachix may not be caching properly\n")
