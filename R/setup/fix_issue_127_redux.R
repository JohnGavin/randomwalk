# Session Log: Fix Issue #127 Redux - The Real Problem
# Date: 2025-12-11
# Issue: #127 Shinylive dashboards still showing errors after PR #128 merged

# ============================================================
# PROBLEM STATEMENT (REVISED)
# ============================================================

# User reported that after merging PR #128, dashboards still show:
# "Requested package randomwalk not found in webR binary repo"
# - No diagnostic logging visible
# - Same errors as before
# - User demanded concrete evidence that changes actually deployed

# ============================================================
# INVESTIGATION & DISCOVERY
# ============================================================

# 1. Checked deployed HTML in docs/ folder locally
# Result: HTML has correct simple library() pattern (no webr::)

# 2. Verified deployment workflow ran successfully
# Command: gh run list --workflow=deploy-pages.yaml --limit=5
# Result: Workflow completed successfully at 2025-12-11T14:16:44Z

# 3. Checked what's ACTUALLY deployed on GitHub Pages
# Command: curl -s "https://johngavin.github.io/randomwalk/articles/dynamic_broadcasting.html" | grep -A 5 "Shinylive will automatically"
# Result: CORRECT code is deployed!
#   # Shinylive will automatically detect and bundle these packages
#   library(shiny)
#   library(randomwalk)

# ============================================================
# ROOT CAUSE IDENTIFIED
# ============================================================

# The code IS correct and IS deployed!

# The problem is BROWSER-SIDE:
# 1. Shinylive registers a Service Worker (shinylive-sw.js)
# 2. Service Workers cache responses aggressively
# 3. Old Service Worker is still serving OLD cached vignette code
# 4. Even though server has correct files, browser never requests them

# Evidence:
# - Server has correct HTML (verified via curl)
# - User's browser shows old errors
# - This is classic Service Worker caching issue

# ============================================================
# SOLUTION
# ============================================================

# User must clear browser cache AND unregister Service Workers:

# 1. Clear browser cache completely
#    - Chrome/Edge: Cmd+Shift+Delete → Select "All time" → Clear
#    - Firefox: Similar
#    - Safari: Develop → Empty Caches

# 2. Unregister Service Workers
#    - Open DevTools (F12)
#    - Go to "Application" tab
#    - Click "Service Workers" in left sidebar
#    - Find any workers for johngavin.github.io
#    - Click "Unregister" for each

# 3. Hard reload page
#    - Cmd+Shift+R (Mac)
#    - Ctrl+Shift+R (Windows/Linux)

# 4. Verify in console
#    - Should see Shinylive loading messages
#    - Should see randomwalk package loading
#    - Should NOT see "package not found" errors

# ============================================================
# LESSONS LEARNED
# ============================================================

# 1. **Service Workers Persist Across Deployments**
#    - Clearing cache doesn't unregister Service Workers
#    - Old SW can serve stale content indefinitely
#    - Must explicitly unregister

# 2. **Always Verify Server vs Client**
#    - User's browser != Deployed server
#    - curl shows server truth
#    - Browser DevTools shows client state

# 3. **Shinylive Service Worker Behavior**
#    - Caches all app resources aggressively
#    - Intercepts network requests
#    - Can prevent updates from being seen

# 4. **Testing Shinylive Changes Requires Clean State**
#    - Always test in Incognito/Private mode OR
#    - Clear SW + cache between tests
#    - Document this in AGENTS.md

# ============================================================
# HISTORICAL CONTEXT
# ============================================================

# Issue #125 fixed vignettes by manually editing HTML files:
# - Commit ee389db: "Replace GitHub releases URLs with simple library() calls in HTML"
# - Did NOT rebuild from .qmd sources
# - Edited docs/*.html directly with R/setup/fix_html_correct_pattern.R

# Why manual HTML editing was necessary:
# - Quarto Shinylive filter requires packages to be installed locally
# - randomwalk package can't be installed in nix store (read-only)
# - Chicken-and-egg: can't build vignettes without randomwalk,
#   can't install randomwalk without building package
# - Solution: Skip Quarto rebuild, edit HTML directly

# ============================================================
# VERIFICATION STEPS
# ============================================================

# Verify deployment is correct (run these anytime):

# 1. Check local docs/ HTML
# cat docs/articles/dynamic_broadcasting.html | grep -A 5 "Shinylive will automatically"

# 2. Check deployed GitHub Pages
# curl -s "https://johngavin.github.io/randomwalk/articles/dynamic_broadcasting.html" | \
#   grep -A 5 "Shinylive will automatically"

# Both should show:
#   # Shinylive will automatically detect and bundle these packages
#   library(shiny)
#   library(randomwalk)

# ============================================================
# FUTURE IMPROVEMENTS
# ============================================================

# 1. Add clear instructions in vignette HTML:
#    "If you see errors, clear your browser cache and Service Workers"

# 2. Version the Service Worker filename:
#    - shinylive-sw-v2.js instead of shinylive-sw.js
#    - Forces browser to load new SW on each deployment

# 3. Add SW update check:
#    - Check for new SW version on page load
#    - Prompt user to refresh if update available

# 4. Document in AGENTS.md:
#    - Testing Shinylive changes requires clean browser state
#    - Always verify with curl what's actually deployed
#    - Service Workers can mask deployment issues

# ============================================================
# REFERENCES
# ============================================================

# - Issue #127: https://github.com/JohnGavin/randomwalk/issues/127
# - PR #128: https://github.com/JohnGavin/randomwalk/pull/128
# - Issue #125: https://github.com/JohnGavin/randomwalk/issues/125
# - Service Workers MDN: https://developer.mozilla.org/en-US/docs/Web/API/Service_Worker_API
# - Shinylive for R: https://github.com/posit-dev/r-shinylive

# ============================================================
# END OF SESSION LOG
# ============================================================
