# Trigger pkgdown rebuild to regenerate Shinylive dashboard
# Date: 2025-11-21
# Issue: #33 - Dashboard parameter defaults not updated on live site
#
# PROBLEM:
# After merging PR #36, the live dashboard at
# https://johngavin.github.io/randomwalk/articles/dashboard_async/
# still shows OLD parameter defaults:
# - Grid size: min=5, max=50, value=20, step=1 (OLD)
# - Workers: max=4 (OLD)
# - Walkers: max=20 (OLD)
#
# EXPECTED (from inst/shiny/dashboard_async/app.R):
# - Grid size: min=20, max=400, value=100, step=20
# - Workers: max=12
# - Walkers: max=100 (dynamically constrained to 70% of grid pixels)
#
# ROOT CAUSE:
# The Shinylive dashboard app.json file in gh-pages branch is cached/stale.
# Pkgdown needs to rebuild the site to regenerate the Shinylive app from
# the updated inst/shiny/dashboard_async/app.R file.
#
# SOLUTION:
# Push any commit to main branch to trigger pkgdown workflow, which will:
# 1. Build the pkgdown site
# 2. Convert inst/shiny/dashboard_async/app.R to Shinylive format
# 3. Deploy to gh-pages branch
# 4. Update live site with correct defaults

# ============================================================================
# WHAT WAS DONE
# ============================================================================

# 1. Updated vignettes/dashboard_async.qmd documentation
#    - Changed worker range from 0-4 to 0-12
#    - Added grid size documentation (20-400, step 20)
#    - Added dynamic walker constraint explanation
#    - Updated performance guidance for large grids

# 2. Committed changes to main branch
system('git add vignettes/dashboard_async.qmd')
system('git commit -m "Docs: Update dashboard_async vignette for expanded parameter ranges"')

# 3. Push to main branch (MANUAL STEP REQUIRED)
# Run this command manually in a terminal with proper git credentials:
#
# git push origin main
#
# This will trigger the pkgdown GitHub Action workflow which will:
# - Rebuild the pkgdown site
# - Regenerate the Shinylive dashboard from inst/shiny/dashboard_async/app.R
# - Deploy to gh-pages with the CORRECT parameter defaults

# ============================================================================
# VERIFICATION STEPS (after push completes)
# ============================================================================

# 1. Wait for GitHub Actions to complete (~3-5 minutes)
#    https://github.com/JohnGavin/randomwalk/actions

# 2. Check the deployed app.json in gh-pages branch
#    https://raw.githubusercontent.com/JohnGavin/randomwalk/gh-pages/articles/dashboard_async/app.json

# 3. Verify the live dashboard shows correct defaults
#    https://johngavin.github.io/randomwalk/articles/dashboard_async/
#
#    Expected to see:
#    - Workers slider: 0-12 (default: 2)
#    - Grid size slider: 20-400 in steps of 20 (default: 100)
#    - Walkers slider: 1-7000 initially (dynamically adjusts to 70% of grid pixels)

# 4. Test the dashboard functionality
#    - Verify workers slider goes to 12
#    - Verify grid size slider shows 20, 40, 60, ..., 400
#    - Verify walkers max updates when grid size changes
#    - Run simulation with grid size 400 and 12 workers

# ============================================================================
# WHY THE SITE WASN'T UPDATED AUTOMATICALLY
# ============================================================================

# The PR #36 was merged and pkgdown ran successfully, but the deployed site
# still had old defaults because:
#
# 1. Pkgdown deployment happened at 17:01:33Z
# 2. But the Shinylive app may have been cached from previous build
# 3. Quarto/Shinylive conversion may not have detected changes
# 4. A fresh rebuild is needed to force regeneration
#
# By pushing a new commit (the vignette update), we force pkgdown to:
# - Rebuild everything from scratch
# - Regenerate all Shinylive apps
# - Deploy fresh content to gh-pages

# ============================================================================
# NEXT ACTIONS REQUIRED
# ============================================================================

# USER MUST RUN MANUALLY (git credentials not available in nix shell):
#
# git push origin main
#
# Then wait for GitHub Actions and verify the deployed dashboard.

message("
========================================================================
MANUAL ACTION REQUIRED
========================================================================

The commit has been created locally but needs to be pushed to GitHub.

Please run this command in your terminal:

    git push origin main

This will trigger the pkgdown workflow to rebuild the site with the
correct dashboard parameter defaults.

After the GitHub Actions complete (~3-5 minutes), verify the live
dashboard at:

    https://johngavin.github.io/randomwalk/articles/dashboard_async/

Expected defaults:
  - Workers: 0-12 (default: 2)
  - Grid size: 20-400 step 20 (default: 100)
  - Walkers: dynamically constrained to 70% of grid pixels

========================================================================
")
