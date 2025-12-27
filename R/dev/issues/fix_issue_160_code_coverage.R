# Development Log: Issue #160 - Add covr for Code Coverage Analysis
# Created: 2025-12-27
# Issue: https://github.com/JohnGavin/randomwalk/issues/160

# ==============================================================================
# Summary
# ==============================================================================
# Integrated covr package for test coverage analysis with:
# 1. Coverage reporting in telemetry vignette
# 2. Coverage badge in README
# 3. Codecov.io CI/CD integration
# 4. Targets pipeline integration for pre-computed coverage

# ==============================================================================
# Changes Made
# ==============================================================================

## 1. DESCRIPTION (ALREADY PRESENT)
# covr already existed in Suggests field (line 39)
# No changes needed

## 2. _targets.R - Added code_coverage target
# Location: After git_summary target (line 212-246)
# Purpose: Pre-compute coverage analysis in targets pipeline
# Returns:
#   - overall_pct: Overall coverage percentage
#   - file_summary: Per-file coverage breakdown
#   - coverage_obj: Full covr coverage object

# Target definition:
# tar_target(
#   name = code_coverage,
#   command = {
#     library(covr)
#     devtools::load_all()
#     logger::log_info("Generating code coverage report")
#
#     coverage <- package_coverage()
#     overall_pct <- percent_coverage(coverage)
#
#     file_coverage <- tidy(coverage)
#     file_summary <- file_coverage %>%
#       group_by(filename) %>%
#       summarise(
#         lines_total = n(),
#         lines_covered = sum(value > 0),
#         coverage_pct = (lines_covered / lines_total) * 100,
#         .groups = "drop"
#       ) %>%
#       arrange(desc(coverage_pct))
#
#     list(
#       overall_pct = overall_pct,
#       file_summary = file_summary,
#       coverage_obj = coverage
#     )
#   }
# )

## 3. vignettes/articles/telemetry.qmd - Enabled coverage sections
# Changed all coverage chunks from eval: false to eval: true
# Updated to use pre-computed targets data

# Modified chunks:
# - coverage-summary (line 77-84): Load cov_data from tar_read(code_coverage)
# - coverage-by-file (line 90-102): Use cov_data$file_summary
# - coverage-plot (line 122-146): Uses file_summary (unchanged, works as-is)
# - untested-hotspots (line 152-170): Uses file_summary (unchanged, works as-is)

## 4. .github/workflows/r-cmd-check.yaml - Added codecov step
# Location: After "Run R CMD check" step (line 46-49)
# Runs: covr::codecov(quiet = FALSE) in nix environment
# Uploads coverage to codecov.io
# Requires: CODECOV_TOKEN secret in GitHub repository settings

# Added step:
#     - name: Test coverage
#       run: nix-shell default-ci.nix --quiet --run "Rscript -e \"covr::codecov(quiet = FALSE)\""
#       env:
#         CODECOV_TOKEN: ${{ secrets.CODECOV_TOKEN }}

## 5. README.md - Added codecov badge
# Location: Line 5 (after R-CMD-check badge)
# Badge URL: https://codecov.io/gh/JohnGavin/randomwalk/branch/main/graph/badge.svg
# Target URL: https://codecov.io/gh/JohnGavin/randomwalk

# ==============================================================================
# Testing & Validation
# ==============================================================================

# Manual coverage testing (optional - requires running targets pipeline):
# library(targets)
# tar_make()
# cov_data <- tar_read(code_coverage)
# cat(sprintf("Overall Coverage: %.1f%%\n", cov_data$overall_pct))
# print(cov_data$file_summary)

# Vignette rendering (requires targets pipeline):
# quarto render vignettes/articles/telemetry.qmd

# CI/CD validation will occur when PR is created

# ==============================================================================
# Setup Required
# ==============================================================================

# User Action: Configure codecov.io
# 1. Visit https://codecov.io/
# 2. Sign in with GitHub
# 3. Add JohnGavin/randomwalk repository
# 4. Copy CODECOV_TOKEN from codecov.io settings
# 5. Add token to GitHub repository:
#    - Go to Settings > Secrets and variables > Actions
#    - Click "New repository secret"
#    - Name: CODECOV_TOKEN
#    - Value: <paste token from codecov.io>

# ==============================================================================
# Acceptance Criteria Status
# ==============================================================================

# [x] covr added to DESCRIPTION (Suggests) - ALREADY PRESENT
# [x] Coverage sections enabled in telemetry vignette (eval: true)
# [x] code_coverage target added to _targets.R
# [x] Coverage badge in README
# [x] CI/CD runs coverage on PRs (workflow updated)
# [~] codecov.io integration configured (requires CODECOV_TOKEN secret)

# ==============================================================================
# Notes
# ==============================================================================

# 1. Telemetry vignette fully enabled:
#    The telemetry.qmd vignette's coverage sections are now enabled and will
#    work once the targets pipeline is run (tar_make()). However, the full
#    vignette is still disabled in _targets.R due to missing pipeline
#    visualization targets (plot_pipeline_timing, plot_pipeline_memory).
#
#    To fully enable telemetry vignette, additional work needed:
#    - Implement plot_pipeline_timing target
#    - Implement plot_pipeline_memory target
#    - Replace dummy telemetry_summary with real tar_meta() data
#    - Uncomment telemetry vignette in _targets.R (line 428-431)
#
#    Recommend creating separate issue for full telemetry vignette enablement.

# 2. Coverage in Nix environment:
#    The CI workflow runs coverage within the nix shell (default-ci.nix) to
#    ensure consistent environment and dependencies.

# 3. First coverage run:
#    Initial codecov upload may take a few minutes. Subsequent runs will be
#    faster due to caching.

# ==============================================================================
# Related Files
# ==============================================================================

# Modified:
# - _targets.R (added code_coverage target)
# - vignettes/articles/telemetry.qmd (enabled coverage chunks)
# - .github/workflows/r-cmd-check.yaml (added codecov step)
# - README.md (added codecov badge)

# Created:
# - R/dev/issues/fix_issue_160_code_coverage.R (this file)

# ==============================================================================
# Next Steps (Post-Merge)
# ==============================================================================

# 1. Verify codecov.io badge displays correctly in README
# 2. Monitor first CI run with coverage upload
# 3. Review coverage report on codecov.io dashboard
# 4. Consider adding coverage targets to PRs (e.g., minimum 70% coverage)
# 5. Create issue for full telemetry vignette enablement (pipeline viz)
