# Create Pull Request for Issue #34
# Date: 2025-11-20

library(gh)

cat("Creating pull request for issue #34...\n\n")

pr_body <- "## Summary

This PR optimizes the Nix environment for CI/CD workflows by creating a minimal `default-ci.nix` configuration file with only the essential packages needed for automated testing and deployment.

## Problem

GitHub Actions workflows were taking 10-12 minutes to complete because they were using `default.nix`, which contains ~100+ R packages needed for local development but not required for CI/CD.

## Solution

- ✅ Created `default-ci.nix` with only 13 essential packages
- ✅ Backed up `default.nix` to `default-dev.nix` for clarity
- ✅ Updated 2 workflows to use `default-ci.nix`:
  - `.github/workflows/tests-r-via-nix.yaml`
  - `.github/workflows/nix-builder.yaml`
- ✅ Added package audit and generation scripts to `R/setup/` for reproducibility

## Package Reduction

**Before (default.nix)**: ~100+ packages (development environment)
**After (default-ci.nix)**: 13 packages (CI/CD only)

### Minimal Package List
- Core dependencies: logger, ggplot2, crew, nanonext
- Testing: testthat, covr
- Documentation: roxygen2, pkgdown, knitr, rmarkdown
- CI tools: devtools, rcmdcheck
- Deployment: shinylive

## Expected Impact

- ⚡ **50%+ faster workflows** (target: <5 min from 10-12 min)
- 💾 **Better Cachix caching** (smaller environment = more efficient)
- 🚀 **Faster development cycle** (quicker CI feedback)
- 📦 **Lower resource usage** (network bandwidth, disk space)
- 🎯 **Clearer separation** (dev vs CI environments)

## Testing

All existing tests should pass with the minimal environment. The workflows will verify:
- Nix environment builds successfully
- All package dependencies are satisfied
- Tests complete without errors

## Files Modified

### New Files
- `default-ci.nix` - Minimal CI/CD environment (13 packages)
- `default-dev.nix` - Backup of original development environment
- `R/setup/audit_packages.R` - Package usage audit
- `R/setup/create_ci_nix.R` - Generate CI nix file
- `R/setup/create_enhancement_issues.R` - Issue creation script
- `R/setup/fix_issue_34_nix_optimization.R` - Workflow log
- `R/setup/commit_nix_changes.R` - Commit script
- `R/setup/push_and_create_pr.R` - PR creation script

### Modified Files
- `.github/workflows/tests-r-via-nix.yaml` - Use default-ci.nix
- `.github/workflows/nix-builder.yaml` - Use default-ci.nix

### Archived
- `archive/github_issue_dashboard_improvements.md`
- `archive/github_issue_nix_optimization.md`

## Verification Checklist

- [ ] Nix-builder workflow completes successfully
- [ ] Tests-r-via-nix workflow completes successfully
- [ ] Workflow execution time reduced by >50%
- [ ] All tests pass with minimal environment
- [ ] Cachix properly caches the environment

## References

Closes #34

## Next Steps

If this PR is successful, we can apply the same optimization strategy to other projects using Nix for CI/CD."

pr <- gh::gh(
  "POST /repos/JohnGavin/randomwalk/pulls",
  title = "Optimize Nix environment for CI/CD workflows",
  head = "fix-issue-34-nix-optimization",
  base = "main",
  body = pr_body
)

cat("\n✅ Pull Request created!\n")
cat("   Number: #", pr$number, "\n", sep = "")
cat("   Title: ", pr$title, "\n", sep = "")
cat("   URL: ", pr$html_url, "\n\n", sep = "")

cat("Monitor GitHub Actions at:\n")
cat("https://github.com/JohnGavin/randomwalk/actions\n\n")

cat("When workflows pass, merge with:\n")
cat("  usethis::pr_merge_main()\n")
cat("  usethis::pr_finish()\n")
