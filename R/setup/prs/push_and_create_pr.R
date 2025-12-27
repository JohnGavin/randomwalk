# Push branch and create PR for Issue #34
# Date: 2025-11-20

library(usethis)
library(gh)

cat("Pushing branch and creating PR for issue #34...\n\n")

# Push branch to create PR
usethis::pr_push()

cat("\n✅ Branch pushed\n")
cat("GitHub Actions will now test the optimized nix environment\n\n")

cat("Monitor workflows at:\n")
cat("https://github.com/JohnGavin/randomwalk/actions\n\n")

cat("Expected outcomes:\n")
cat("1. Nix-builder workflow completes faster (<5 min vs 10-12 min)\n")
cat("2. Tests-r-via-nix workflow completes faster\n")
cat("3. All tests pass with minimal 13-package environment\n")
cat("4. Cachix properly caches the smaller environment\n\n")

cat("If all workflows pass:\n")
cat("- Run usethis::pr_merge_main() to merge\n")
cat("- Run usethis::pr_finish() to clean up branch\n")
