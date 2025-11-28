# Session Log: Fix Issue #44 - Broken Dashboard Links
# Date: 2025-11-28
# Issue: https://github.com/JohnGavin/randomwalk/issues/44
#
# =============================================================================
# PROBLEM
# =============================================================================
#
# Dashboard links on https://johngavin.github.io/randomwalk/articles/ return 404:
# 1. Interactive Dashboard: articles/dashboard/ → 404 ❌
# 2. Async/Parallel Dashboard: articles/dashboard_async/ → 404 ❌
#
# =============================================================================
# ROOT CAUSE
# =============================================================================
#
# Dashboard vignettes use Shinylive filter which creates .html files, not
# pkgdown-style article directories.
#
# _pkgdown.yml was using directory paths:
#   href: articles/dashboard/         # Wrong
#
# Should use .html extension:
#   href: articles/dashboard.html     # Correct
#
# =============================================================================
# FIX
# =============================================================================
#
# Updated _pkgdown.yml (3 locations):
#
# 1. home.links (line 14):
#    - href: articles/dashboard/        # Before
#    + href: articles/dashboard.html    # After
#
# 2. navbar.components.articles.menu (lines 25, 27):
#    - href: articles/dashboard/        # Before
#    + href: articles/dashboard.html    # After
#
#    - href: articles/dashboard_async/  # Before
#    + href: articles/dashboard_async.html  # After
#
# =============================================================================
# VERIFICATION
# =============================================================================
#
# After deployment, verify these URLs work:
# - https://johngavin.github.io/randomwalk/articles/dashboard.html
# - https://johngavin.github.io/randomwalk/articles/dashboard_async.html
# - https://johngavin.github.io/randomwalk/articles/telemetry.html
#
# =============================================================================
# WORKFLOW COMMANDS
# =============================================================================

library(gert)
library(usethis)

# 1. Create development branch
usethis::pr_init("fix-issue-44-broken-dashboard-links")

# 2. Stage and commit changes
gert::git_add("_pkgdown.yml")
gert::git_add("R/setup/fix_issue_44_broken_links.R")

gert::git_commit("Fix #44: Correct dashboard link paths in _pkgdown.yml

Dashboard vignettes use Shinylive which creates .html files, not directories.
Updated three links from directory paths to .html extensions:
- home.links: articles/dashboard.html
- navbar menu: dashboard.html and dashboard_async.html

Closes #44")

# 3. Push and create PR
usethis::pr_push()

# 4. After GitHub Actions pass, merge
usethis::pr_merge_main()
usethis::pr_finish()
