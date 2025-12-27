# Fix Issue #94: Broken vignette links on website - Missing pre-built HTML
# Created: 2025-12-05
# Purpose: Pre-build missing vignette HTML files so pkgdown can include them
#
# Problem: Three vignette links were broken on the website because the HTML
# files didn't exist in vignettes/ directory:
# - https://johngavin.github.io/randomwalk/articles/dashboard.html (existed)
# - https://johngavin.github.io/randomwalk/articles/dashboard_async.html (MISSING)
# - https://johngavin.github.io/randomwalk/articles/dynamic_broadcasting.html (MISSING)
#
# Solution: Pre-built the missing HTML files using Quarto

library(gert)
library(usethis)

# Step 1: Created issue #94 on GitHub
# https://github.com/JohnGavin/randomwalk/issues/94

# Step 2: Create dev branch
# Already done: fix-issue-94-broken-vignette-links

# Step 3: Build missing vignettes

# Build dashboard_async.html
# Command: cd vignettes && quarto render dashboard_async.qmd
# Output: vignettes/dashboard_async.html (29K)

# Build dynamic_broadcasting.html
# First removed library(randomwalk) from setup chunk (vignette is documentation only)
# Command: quarto render dynamic_broadcasting.qmd
# Output: vignettes/dynamic_broadcasting.html (78K)

# Step 4: Verify all vignettes exist
# ✅ vignettes/dashboard.html (50K)
# ✅ vignettes/dashboard_async.html (29K)
# ✅ vignettes/dynamic_broadcasting.html (78K)
# ✅ vignettes/telemetry.html (103K)

# Step 5: Commit changes
gert::git_add("vignettes/dashboard_async.html")
gert::git_add("vignettes/dynamic_broadcasting.html")
gert::git_add("vignettes/dynamic_broadcasting.qmd")  # Modified to remove library() call
gert::git_add("R/setup/fix_issue_94_broken_vignette_links.R")

gert::git_commit("Fix #94: Pre-build missing vignette HTML files

Problem: Three vignette links were broken on the website:
- dashboard_async.html (missing)
- dynamic_broadcasting.html (missing)

Root cause: pkgdown requires pre-built HTML files in vignettes/ directory
to include them on the website.

Solution: Pre-built both missing vignettes using Quarto:
- dashboard_async.html (29K)
- dynamic_broadcasting.html (78K)

Also modified dynamic_broadcasting.qmd to remove library(randomwalk)
call in setup chunk since the vignette is documentation only (no code
execution needed).

All vignette links will now work on the website.

Related: Issue #94 (High priority - broken links)")

cat("✓ Changes committed\n")

# Step 6: DO NOT push to GitHub yet (user requested to wait)
# usethis::pr_push()  # Will run when user approves

# Step 7: Wait for GitHub Actions
# Step 8: Merge PR
# Step 9: Log everything (this file)
