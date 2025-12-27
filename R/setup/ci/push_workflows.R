# Push workflows to GitHub
# Simple script using only base R and system commands

setwd("/Users/johngavin/docs_gh/claude_rix/random_walk")

# Step 1: Check git status
cat("=== Current Git Status ===\n")
system("git status")

# Step 2: Create branch
cat("\n=== Creating Feature Branch ===\n")
system("git checkout -b feature/github-workflows-5")

# Step 3: Add files
cat("\n=== Adding Files ===\n")
system("git add .github/workflows/")
system("git add R/setup/dev_log.R")
system("git status")

# Step 4: Commit
cat("\n=== Committing Changes ===\n")
commit_msg <- "Add GitHub Actions workflows for CI/CD with Nix

- Add tests-r-via-nix.yaml for running tests in Nix environment
- Add nix-builder.yaml for building and testing default.nix
- Add pkgdown.yaml for building and deploying documentation
- All workflows based on ropensci/rix examples
- Ensures reproducible builds across platforms

Addresses GitHub Actions CI/CD setup"

system2("git", c("commit", "-m", shQuote(commit_msg)))

# Step 5: Push to remote
cat("\n=== Pushing to GitHub ===\n")
system("git push -u origin feature/github-workflows-5")

cat("\n=== Done! ===\n")
cat("Next steps:\n")
cat("1. Create issue on GitHub website\n")
cat("2. Create PR from feature/github-workflows-5\n")
cat("3. Wait for workflows to pass\n")
cat("4. Merge PR\n")
