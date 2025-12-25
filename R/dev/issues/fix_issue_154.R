# Fix Issue #154: ServiceWorker scope restriction
# Date: 2025-12-25
# Branch: main (critical bug fix)

# ============================================================================
# Problem
# ============================================================================
# After #153, ServiceWorker was registering successfully but controller not found:
# - "Service Worker registered" ✅
# - "ServiceWorker controller was not found!" ❌
#
# Root cause: ServiceWorker SCOPE restriction
# - SW location: /articles/dynamic_broadcasting_files/libs/quarto-contrib/shinylive-0.10.7/shinylive-sw.js
# - SW scope: /articles/dynamic_broadcasting_files/libs/quarto-contrib/shinylive-0.10.7/ (default)
# - Page location: /articles/dynamic_broadcasting.html
# - Page is OUTSIDE SW scope! ❌

# ============================================================================
# ServiceWorker Scope Rules
# ============================================================================
# A ServiceWorker can ONLY control pages within its scope.
# The default scope is the directory containing the SW file.
#
# Example:
# - SW at: /foo/bar/baz/sw.js
# - Default scope: /foo/bar/baz/
# - Can control: /foo/bar/baz/page.html ✅
# - Cannot control: /foo/bar/page.html ❌
# - Cannot control: /foo/page.html ❌
#
# You CANNOT widen the scope beyond the SW's directory (browser security restriction).

# ============================================================================
# Solution
# ============================================================================
# Copy ServiceWorker file to /articles/ directory so it can control pages in /articles/
#
# New configuration:
# - SW location: /articles/shinylive-sw.js
# - SW scope: /articles/ (default)
# - Page location: /articles/dynamic_broadcasting.html
# - Page is INSIDE SW scope! ✅

# ============================================================================
# Implementation
# ============================================================================

# Step 1: Copy SW file to articles directory
# Working directory: /Users/johngavin/docs_gh/randomwalk/vignettes
system("cp articles/dynamic_broadcasting_files/libs/quarto-contrib/shinylive-0.10.7/shinylive-sw.js articles/shinylive-sw.js")

# Step 2: Update vignette YAML to point to same directory
# Changed meta tag: content="dynamic_broadcasting_files/libs/quarto-contrib/shinylive-0.10.7" → content="."
# Added resources: - shinylive-sw.js

# Step 3: Re-render vignettes
system("SHINYLIVE_ASSETS_VERSION=0.10.7 quarto render articles/dynamic_broadcasting.qmd")
system("SHINYLIVE_ASSETS_VERSION=0.10.7 quarto render articles/dashboard_comprehensive.qmd")

# Step 4: Remove duplicate Quarto meta tags
system('sed -i.bak \'/<meta name="shinylive:serviceworker_dir" content="\.\.\/\.\.">/d\' articles/dynamic_broadcasting.html')
system('sed -i.bak \'/<meta name="shinylive:serviceworker_dir" content="\.\.\/\.\.">/d\' articles/dashboard_comprehensive.html')

# Step 5: Copy to docs
system("cp articles/dynamic_broadcasting.html articles/dashboard_comprehensive.html ../docs/articles/")
system("cp articles/shinylive-sw.js ../docs/articles/")

# Step 6: Commit changes
library(gert)
git_add(c(
  "vignettes/articles/dynamic_broadcasting.qmd",
  "vignettes/articles/dashboard_comprehensive.qmd",
  "vignettes/articles/dynamic_broadcasting.html",
  "vignettes/articles/dashboard_comprehensive.html",
  "vignettes/articles/shinylive-sw.js",
  "docs/articles/dynamic_broadcasting.html",
  "docs/articles/dashboard_comprehensive.html",
  "docs/articles/shinylive-sw.js",
  "R/dev/issues/fix_issue_154.R"
))

git_commit("Fix #154: ServiceWorker scope - copy SW to /articles/ for proper scope

ServiceWorker was registering but couldn't control page due to scope restriction.

Previous (broken):
- SW location: .../shinylive-0.10.7/shinylive-sw.js
- SW scope: .../shinylive-0.10.7/ (default)
- Page: /articles/dynamic_broadcasting.html
- Page OUTSIDE scope ❌

Current (fixed):
- SW location: /articles/shinylive-sw.js
- SW scope: /articles/ (default)
- Page: /articles/dynamic_broadcasting.html
- Page INSIDE scope ✅

Changes:
- Copied SW file to /articles/ directory
- Updated meta tag: content='.' (same directory)
- Added resources directive to copy SW file

Browser should now show:
- ✅ Service Worker registered
- ✅ ServiceWorker controller found
- ❌ NO 'controller was not found' error

Closes #154

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>")

git_push()

# ============================================================================
# Expected Outcome
# ============================================================================
# After deployment:
# ✅ Service Worker registered
# ✅ ServiceWorker controller found
# ✅ No more scope errors
# ✅ R 4.5.1 running
# ⏳ nanonext/mirai (Issue #151 pending)

# ============================================================================
# Verification Commands
# ============================================================================
# Check SW location:
# curl -I "https://johngavin.github.io/randomwalk/articles/shinylive-sw.js"
# Should return: HTTP 200
#
# Check meta tag:
# curl -s "https://johngavin.github.io/randomwalk/articles/dynamic_broadcasting.html" | grep serviceworker_dir
# Should show: content="."
#
# Browser Console should show:
# - "Service Worker registered"
# - NO "ServiceWorker controller was not found!"

# ============================================================================
# Related Issues
# ============================================================================
# - Issue #148: Shinylive assets upgrade ✅
# - Issue #150: Duplicate meta tags ✅
# - Issue #152: SW version mismatch ✅
# - Issue #153: SW path fix ✅
# - Issue #154: SW scope fix ✅ (this fix)
# - Issue #151: nanonext/mirai ⏳
