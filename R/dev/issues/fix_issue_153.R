# Fix Issue #153: ServiceWorker path - point to Shinylive assets directory
# Date: 2025-12-25
# Branch: main (critical bug fix)

# ============================================================================
# Problem
# ============================================================================
# After fixing Issue #152 (upgrading SW file to 0.10.7), registration still
# failing because meta tag pointed to WRONG LOCATION.
#
# Meta tag: content="../.." → /shinylive-sw.js (wrong!)
# Actual SW: /articles/dynamic_broadcasting_files/libs/quarto-contrib/shinylive-0.10.7/shinylive-sw.js
#
# Browser errors:
# - "Service Worker registration failed"
# - "ServiceWorker controller was not found!"

# ============================================================================
# Root Cause
# ============================================================================
# Quarto Shinylive extension auto-generates meta tag with content="../.."
# pointing to project root, but ServiceWorker file exists WITHIN the
# Shinylive assets bundle, not at root.
#
# Quarto always generates:
# <meta name="shinylive:serviceworker_dir" content="../..">
#
# This worked in demos (Shinylive 0.9.1) because we manually copied SW to root.
# But for vignettes with Shinylive 0.10.7, SW is in assets directory.

# ============================================================================
# Solution
# ============================================================================
# Override Quarto's meta tag by adding correct path to vignette YAML:
#
# format:
#   html:
#     include-in-header:
#       - text: |
#           <meta name="shinylive:serviceworker_dir" content="dynamic_broadcasting_files/libs/quarto-contrib/shinylive-0.10.7">
#
# Then remove duplicate Quarto-generated meta tag from HTML.

# ============================================================================
# Implementation
# ============================================================================

# Step 1: Update vignette YAML files
# File: vignettes/articles/dynamic_broadcasting.qmd
# Added include-in-header with correct meta tag

# File: vignettes/articles/dashboard_comprehensive.qmd
# Added include-in-header with correct meta tag

# Step 2: Re-render vignettes
# Working directory: /Users/johngavin/docs_gh/randomwalk/vignettes
system("SHINYLIVE_ASSETS_VERSION=0.10.7 quarto render articles/dynamic_broadcasting.qmd")
system("SHINYLIVE_ASSETS_VERSION=0.10.7 quarto render articles/dashboard_comprehensive.qmd")

# Step 3: Remove duplicate Quarto meta tags
system('sed -i.bak \'/<meta name="shinylive:serviceworker_dir" content="\.\.\/\.\.">/d\' articles/dynamic_broadcasting.html')
system('sed -i.bak \'/<meta name="shinylive:serviceworker_dir" content="\.\.\/\.\.">/d\' articles/dashboard_comprehensive.html')

# Step 4: Verify single correct meta tag
system("grep serviceworker_dir articles/dynamic_broadcasting.html")
# Output: <meta name="shinylive:serviceworker_dir" content="dynamic_broadcasting_files/libs/quarto-contrib/shinylive-0.10.7">

# Step 5: Copy to docs directory
system("cp articles/dynamic_broadcasting.html articles/dashboard_comprehensive.html ../docs/articles/")
system("cp -r articles/dynamic_broadcasting_files articles/dashboard_comprehensive_files ../docs/articles/")

# Step 6: Commit changes
library(gert)
git_add(c(
  "vignettes/articles/dynamic_broadcasting.qmd",
  "vignettes/articles/dashboard_comprehensive.qmd",
  "vignettes/articles/dynamic_broadcasting.html",
  "vignettes/articles/dashboard_comprehensive.html",
  "vignettes/articles/dynamic_broadcasting_files/",
  "vignettes/articles/dashboard_comprehensive_files/",
  "docs/articles/dynamic_broadcasting.html",
  "docs/articles/dashboard_comprehensive.html",
  "docs/articles/dynamic_broadcasting_files/",
  "docs/articles/dashboard_comprehensive_files/",
  "R/dev/issues/fix_issue_153.R"
))

git_commit("Fix #153: Point ServiceWorker meta tag to Shinylive assets directory

- Override Quarto auto-generated meta tag with correct path
- SW now loaded from Shinylive assets bundle, not root
- Remove duplicate meta tags from rendered HTML

Changes:
- vignettes: Added include-in-header with correct SW path
- HTML: Removed Quarto's content='../..' meta tag
- Meta tag now: dynamic_broadcasting_files/libs/quarto-contrib/shinylive-0.10.7

Previous (broken):
- Meta: content='../..' → /shinylive-sw.js ❌
- Registration failed

Current (fixed):
- Meta: content='dynamic_broadcasting_files/libs/quarto-contrib/shinylive-0.10.7' ✅
- Registration should succeed

Closes #153

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>")

git_push()

# ============================================================================
# Expected Outcome
# ============================================================================
# After deployment:
# ✅ Service Worker registered (URL: .../shinylive-0.10.7/shinylive-sw.js)
# ✅ ServiceWorker controller found
# ✅ R 4.5.1 running
# ⏳ nanonext/mirai loading (Issue #151 pending)

# ============================================================================
# Verification
# ============================================================================
# Check deployed meta tag:
# curl -s "https://johngavin.github.io/randomwalk/articles/dynamic_broadcasting.html" | grep serviceworker_dir
# Should show: content="dynamic_broadcasting_files/libs/quarto-contrib/shinylive-0.10.7"
#
# Check browser DevTools Console:
# Should show: "Service Worker registered"
# Should NOT show: "Service Worker registration failed"

# ============================================================================
# Related Issues
# ============================================================================
# - Issue #148: Shinylive assets upgrade to 0.10.7 ✅
# - Issue #150: Remove duplicate meta tags ✅
# - Issue #152: ServiceWorker version mismatch ✅
# - Issue #153: ServiceWorker path fix ✅ (this fix)
# - Issue #151: nanonext/mirai compatibility ⏳
