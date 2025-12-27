# Test Full Cachix Caching - Run #97
# Date: 2025-11-20
# Purpose: Trigger build to test pulling from populated cache

library(gert)

cat("=== FIRST BUILD RESULTS (Run #96) ===\n\n")

cat("✅ R-tests-via-nix: 7m 18s (was 17+ min)\n")
cat("✅ nix-builder: 6m 33s (was 17+ min)\n")
cat("✅ 62% speedup achieved!\n\n")

cat("Cache is now populated at:\n")
cat("https://app.cachix.org/cache/randomwalk\n\n")

cat("=== TRIGGERING SECOND BUILD (Run #97) ===\n\n")

cat("This build should be EVEN FASTER (~2-3 min)\n")
cat("because everything is now cached.\n\n")

# Create empty commit
system("git commit --allow-empty -m 'Test full Cachix caching (Run #97)

Run #96 results:
- R-tests-via-nix: 7m 18s (was ~17 min)
- nix-builder: 6m 33s (was ~17 min)
- 62% speedup achieved!

This build tests pulling from fully populated cache.
Expected: ~2-3 min (pure cache pull, no building)'")

cat("✅ Empty commit created\n\n")

cat("Pushing to trigger workflows...\n")
gert::git_push()

cat("\n✅ Pushed! Run #97 starting...\n\n")

cat("Expected results:\n")
cat("- Duration: ~2-3 min (even faster!)\n")
cat("- All packages pulled from cache\n")
cat("- Look for: 'copying path ... from randomwalk.cachix.org'\n\n")

cat("Monitor at:\n")
cat("- Workflows: https://github.com/JohnGavin/randomwalk/actions\n")
cat("- Cachix: https://app.cachix.org/cache/randomwalk\n\n")

cat("If Run #97 is ~2-3 min:\n")
cat("✅ Issue #34 SOLVED - 85%+ speedup achieved!\n")
cat("✅ Ready to merge PR #35\n")
