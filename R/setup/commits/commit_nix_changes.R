# Commit changes for Issue #34
# Date: 2025-11-20

library(gert)

cat("Committing changes for issue #34...\n\n")

# Add all new and modified files
files_to_add <- c(
  "default-ci.nix",
  "default-dev.nix",
  ".github/workflows/nix-builder.yaml",
  ".github/workflows/tests-r-via-nix.yaml",
  "R/setup/audit_packages.R",
  "R/setup/create_ci_nix.R",
  "R/setup/create_enhancement_issues.R",
  "R/setup/fix_issue_34_nix_optimization.R",
  "R/setup/commit_nix_changes.R",
  "archive/github_issue_dashboard_improvements.md",
  "archive/github_issue_nix_optimization.md"
)

cat("Adding files:\n")
for (file in files_to_add) {
  if (file.exists(file)) {
    gert::git_add(file)
    cat("  ✓", file, "\n")
  }
}

# Commit with descriptive message
commit_msg <- "Optimize Nix environment for CI/CD (Issue #34)

Created minimal default-ci.nix with only 13 essential packages
instead of ~100+ development packages.

Changes:
- Created default-ci.nix (13 packages for CI/CD)
- Backed up default.nix to default-dev.nix (development)
- Updated workflows to use default-ci.nix:
  - .github/workflows/tests-r-via-nix.yaml
  - .github/workflows/nix-builder.yaml
- Added package audit and generation scripts to R/setup/
- Archived enhancement markdown files

Expected impact: 50%+ reduction in workflow execution time
(from 10-12 minutes to <5 minutes)

Fixes #34"

gert::git_commit(commit_msg)

cat("\n✅ Committed changes\n")
cat("\nCommit message:\n")
cat(commit_msg, "\n\n")

# Show commit hash
log <- gert::git_log(max = 1)
cat("Commit hash:", log$commit[1], "\n")
cat("Branch:", gert::git_branch(), "\n\n")

cat("Next: Run local checks (devtools::test(), devtools::check())\n")
