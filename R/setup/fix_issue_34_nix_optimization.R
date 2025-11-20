# Fix Issue #34: Optimize Nix Environment for CI/CD Workflows
# Date: 2025-11-20
# Issue: https://github.com/JohnGavin/randomwalk/issues/34
# Purpose: Create minimal default-ci.nix to speed up GitHub Actions workflows

library(usethis)
library(gert)
library(gh)

# Step 1: Create development branch
# ----------------------------------
cat("Step 1: Creating development branch...\n")
usethis::pr_init("fix-issue-34-nix-optimization")

cat("\n✅ Development branch created\n")
cat("Branch: fix-issue-34-nix-optimization\n")
cat("Next: Audit package usage and create minimal default-ci.nix\n")
