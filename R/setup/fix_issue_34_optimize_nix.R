# Issue #34: Optimize Nix environment for CI/CD workflows
# Date: 2025-11-20
# Branch: fix-issue-34-nix-optimization
#
# Goal: Reduce GitHub Actions workflow time by creating minimal CI-specific
# Nix environment instead of using bloated development environment
#
# Problem: Workflows were taking 10-12 minutes because default.nix contained
# ~117 R packages needed for local development but not required for CI/CD

# =============================================================================
# STEP 1: Audit Package Usage
# =============================================================================

# Scanned all R code, tests, and vignettes for package usage
# Found 24 packages actually used in project:
actual_packages <- c(
  "bench", "covr", "crew", "devtools", "dplyr", "duckdb",
  "ggplot2", "grDevices", "knitr", "logger", "munsell",
  "nanonext", "pkgdown", "quarto", "rmarkdown", "shiny",
  "shinylive", "shinytest2", "stats", "tarchetypes",
  "targets", "testthat", "usethis", "visNetwork"
)

# =============================================================================
# STEP 2: Create Minimal CI Package List
# =============================================================================

library(rix)

# Minimal CI package list (21 packages + dependencies)
r_pkgs_ci <- c(
  # Core dependencies (from DESCRIPTION Imports)
  "logger", "ggplot2", "crew", "nanonext",
  
  # Testing
  "testthat", "covr",
  
  # Documentation
  "roxygen2", "pkgdown", "knitr", "rmarkdown", "quarto",
  
  # CI tools
  "devtools", "rcmdcheck",
  
  # Vignette dependencies (from DESCRIPTION Suggests)
  "targets", "tarchetypes", "visNetwork", "dplyr",
  "shiny", "shinylive", "munsell", "duckdb"
)

# System packages for CI
system_pkgs_ci <- c(
  "git",        # Version control
  "gh",         # GitHub CLI
  "quarto",     # Documentation
  "pandoc",     # Documentation
  "curlMinimal" # Network operations
)

# =============================================================================
# STEP 3: Generate default-ci.nix
# =============================================================================

# Generated minimal CI environment
rix(
  r_ver = "latest-upstream",
  r_pkgs = r_pkgs_ci,
  system_pkgs = system_pkgs_ci,
  ide = "none",
  project_path = ".",
  overwrite = TRUE,
  print = FALSE,
  shell_hook = NULL
)

# Renamed default.nix to default-ci.nix
# system("mv default.nix default-ci.nix")

# =============================================================================
# STEP 4: Update GitHub Workflows
# =============================================================================

# Updated three workflow files to use default-ci.nix:
# 1. .github/workflows/pkgdown.yaml - Convert from r-lib actions to nix-shell
# 2. .github/workflows/tests-r-via-nix.yaml - Already using default-ci.nix
# 3. .github/workflows/nix-builder.yaml - Already using default-ci.nix

# =============================================================================
# RESULTS
# =============================================================================

# Environment comparison:
# - Full dev environment (default-dev.nix): ~117 R packages + system tools
# - Minimal CI environment (default-ci.nix): 21 R packages + 5 system packages
# - Reduction: ~82% fewer R packages
#
# Expected performance improvement:
# - Faster nix environment initialization
# - Better Cachix caching efficiency  
# - Reduced network bandwidth and disk usage
# - Target: <5 minutes for most workflows (vs. current 10-12 minutes)
#
# Files created/modified:
# - default-ci.nix (created)
# - .github/workflows/pkgdown.yaml (updated)
# - .github/workflows/tests-r-via-nix.yaml (already using default-ci.nix)
# - .github/workflows/nix-builder.yaml (already using default-ci.nix)
# - R/setup/fix_issue_34_optimize_nix.R (this log file)

# =============================================================================
# NEXT STEPS
# =============================================================================

# 1. Commit changes to branch: fix-issue-34-nix-optimization
# 2. Push to GitHub and create PR
# 3. Monitor workflow execution times
# 4. Verify all workflows pass
# 5. Compare before/after timing metrics
# 6. Merge PR if successful

