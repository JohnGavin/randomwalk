# Setup GitHub Actions workflows for randomwalk package
# Following context.md guidelines

# Load only gh for issue creation
if (!requireNamespace("gh", quietly = TRUE)) {
  install.packages("gh", repos = "https://cloud.r-project.org")
}

library(gh)

setwd("/Users/johngavin/docs_gh/claude_rix/random_walk")

# Step 1: Create GitHub Issue
cat("=== Step 1: Creating GitHub Issue ===\n")
issue_body <- "## Overview
Set up GitHub Actions workflows based on ropensci/rix examples to ensure reproducible builds using Nix.

## Workflows to Add

1. **R CMD check via Nix** (`tests-r-via-nix.yaml`)
   - Run devtools::test() in Nix environment
   - Test on both macOS and Ubuntu
   - Ensure reproducibility

2. **Nix Build** (`nix-builder.yaml`)
   - Build and test default.nix configuration
   - Verify Nix shell works correctly

3. **pkgdown Site** (`pkgdown.yaml`)
   - Build and deploy package documentation
   - Deploy to GitHub Pages

## Requirements

- [ ] Add .github/workflows directory
- [ ] Create tests-r-via-nix.yaml
- [ ] Create nix-builder.yaml
- [ ] Create pkgdown.yaml
- [ ] Update dev_log.R with all commands
- [ ] Configure GitHub Pages
- [ ] Verify all workflows pass

## References

- https://github.com/ropensci/rix/tree/main/.github/workflows
- context.md guidelines"

issue <- gh("POST /repos/JohnGavin/randomwalk/issues",
           title = "Add GitHub Actions workflows for CI/CD with Nix",
           body = issue_body)

cat("Issue created: #", issue$number, "\n", sep = "")
cat("URL:", issue$html_url, "\n\n")

# Save issue number
writeLines(as.character(issue$number), "issue_number_workflows.txt")

cat("Issue number saved to issue_number_workflows.txt\n")

