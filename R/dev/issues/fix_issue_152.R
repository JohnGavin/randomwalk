# Fix Issue #152: ServiceWorker version mismatch (0.9.1 → 0.10.7)
# Date: 2025-12-25
# Branch: main (direct fix - critical bug)

# ============================================================================
# Problem
# ============================================================================
# After PR #149 upgraded Shinylive assets to 0.10.7, the ServiceWorker files
# being served were still version 0.9.1, causing registration failures.
#
# Browser console showed:
# "Service Worker registration failed"
# "ServiceWorker controller was not found!"
#
# Investigation revealed:
# - Deployed HTML uses Shinylive 0.10.7 assets ✅
# - ServiceWorker files are version 0.9.1 ❌
# - Mismatch causes registration failure

# ============================================================================
# Root Cause Analysis
# ============================================================================
# The `resources: - shinylive-sw.js` directive in vignette YAML copies from
# `vignettes/articles/shinylive-sw.js`, which was never updated to 0.10.7.
#
# File Checksums:
# - OLD (0.9.1): e55e51174b2e26084450d937b6f16ebf50434a9b1e9a7d5d47d193f8cf465f87
# - NEW (0.10.7): aa9666525139a8f1181452a3467d6a8792a52a357d9ed5d625c938df8331d2cf
#
# Files affected:
# - vignettes/articles/shinylive-sw.js (0.9.1) ❌
# - docs/articles/shinylive-sw.js (0.9.1) ❌
# - docs/shinylive-sw.js (0.9.1) ❌
# - vignettes/articles/dynamic_broadcasting_files/.../shinylive-0.10.7/shinylive-sw.js (0.10.7) ✅

# ============================================================================
# Solution
# ============================================================================
# Copy the new ServiceWorker file from Shinylive 0.10.7 assets to replace
# the old 0.9.1 version in all locations.

# Working directory: /Users/johngavin/docs_gh/randomwalk/vignettes
system("cp articles/dynamic_broadcasting_files/libs/quarto-contrib/shinylive-0.10.7/shinylive-sw.js articles/shinylive-sw.js")
system("cp articles/shinylive-sw.js ../docs/articles/")
system("cp articles/shinylive-sw.js ../docs/")

# Verify checksums match
system("sha256sum articles/shinylive-sw.js ../docs/articles/shinylive-sw.js ../docs/shinylive-sw.js")
# All files now: aa9666525139a8f1181452a3467d6a8792a52a357d9ed5d625c938df8331d2cf ✅

# ============================================================================
# Commit and Deploy
# ============================================================================
library(gert)
git_add(c(
  "vignettes/articles/shinylive-sw.js",
  "docs/articles/shinylive-sw.js",
  "docs/shinylive-sw.js",
  "R/dev/issues/fix_issue_152.R"
))

git_commit("Fix #152: Upgrade ServiceWorker files from 0.9.1 to 0.10.7

- Replaced old ServiceWorker files with version from Shinylive 0.10.7 assets
- All SW files now match: aa9666525139a8f1181452a3467d6a8792a52a357d9ed5d625c938df8331d2cf
- Fixes ServiceWorker registration failure in browser

Files updated:
- vignettes/articles/shinylive-sw.js (0.9.1 → 0.10.7)
- docs/articles/shinylive-sw.js (0.9.1 → 0.10.7)
- docs/shinylive-sw.js (0.9.1 → 0.10.7)

Root cause: resources: directive copied old cached version
Solution: Copy from embedded Shinylive 0.10.7 assets

Closes #152")

git_push()

# ============================================================================
# Expected Outcome
# ============================================================================
# After deployment, browser should show:
# ✅ Service Worker registered (URL: /randomwalk/shinylive-sw.js)
# ✅ ServiceWorker controller found
# ✅ R version 4.5.1 running
# ✅ mirai/nanonext packages loading (pending #151 resolution)

# ============================================================================
# Verification Commands
# ============================================================================
# Check deployed ServiceWorker version:
# curl -s "https://johngavin.github.io/randomwalk/articles/shinylive-sw.js" | head -3
# Should show: // Shinylive 0.10.7
#
# Check browser DevTools Console at:
# https://johngavin.github.io/randomwalk/articles/dynamic_broadcasting.html
# Should show: "Service Worker registered"

# ============================================================================
# Related Issues
# ============================================================================
# - Issue #148: Upgrade Shinylive assets to 0.10.7 ✅
# - Issue #150: Remove duplicate meta tags ✅
# - Issue #152: Fix ServiceWorker version mismatch ✅ (this fix)
# - Issue #151: nanonext/mirai compatibility ⏳ (pending)

# ============================================================================
# Timeline
# ============================================================================
# 1. #148: Upgraded Shinylive assets → HTML uses 0.10.7 ✅
# 2. #150: Removed duplicate meta tags → Single meta tag ✅
# 3. #152: Upgraded ServiceWorker files → SW matches assets ✅
# 4. #151: Fix nanonext/mirai → Enable async features ⏳
