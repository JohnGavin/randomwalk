# ==============================================================================
# Issue #158: Fix ServiceWorker Scope + Disable WebR Async
# ==============================================================================
# Date: 2025-12-26
#
# Problems:
# ---------
# 1. ServiceWorker registration failed - "ServiceWorker controller not found"
#    Cause: Duplicate meta tags with conflicting paths (../.., .)
#
# 2. mirai/nanonext compatibility persists even with r-lib.r-universe.dev
#    Error: object '.interrupt' is not exported by 'namespace:nanonext'
#    This error occurs with BOTH custom-built and r-universe packages
#
# Solutions:
# ----------
# 1. ServiceWorker Fix:
#    Added JavaScript to modify Quarto's meta tag before Shinylive loads
#    The script finds the first meta tag and updates its content to "."
#
# 2. WebR Async Disable:
#    Removed mirai/nanonext installation code from vignettes
#    Documented that async is disabled in WebR due to compatibility issues
#    Apps now run in synchronous mode (workers=1) in browser
#    Async still works in native R with crew backend
#
# Changes:
# --------
# 1. vignettes/articles/dynamic_broadcasting.qmd:
#    - Added JavaScript to fix serviceworker_dir meta tag
#    - Removed mirai/nanonext installation code
#    - Updated documentation to note WebR async limitation
#    - Updated header comments
#
# 2. vignettes/articles/dashboard_comprehensive.qmd:
#    - Same changes as dynamic_broadcasting.qmd
#
# 3. Re-rendered both vignettes with SHINYLIVE_ASSETS_VERSION=0.10.7
#
# 4. Copied rendered HTML to docs/articles/
#
# Expected Results:
# ----------------
# 1. ServiceWorker registration successful ✅
# 2. No more .interrupt errors ✅
# 3. Apps run in synchronous mode in browser ✅
# 4. Clear documentation of WebR limitation ✅
#
# Testing Commands:
# ----------------
# # Check deployed meta tags
# curl -s "https://johngavin.github.io/randomwalk/articles/dynamic_broadcasting.html" | \
#   grep -o '<meta name="shinylive:serviceworker_dir"[^>]*>'
#
# # Check JavaScript fix
# curl -s "https://johngavin.github.io/randomwalk/articles/dynamic_broadcasting.html" | \
#   grep -A5 "Fix serviceworker_dir"
#
# # Verify ServiceWorker file exists
# curl -sI "https://johngavin.github.io/randomwalk/articles/shinylive-sw.js"
#
# Related Issues:
# --------------
# - #151: nanonext/mirai compatibility (resolved by disabling async in WebR)
# - #154: ServiceWorker scope issue (resolved with JavaScript fix)
# - #155: Custom WASM packages (superseded by disabling async)
# - #156: Custom repository (superseded by disabling async)
# - #157: r-universe attempt (didn't resolve .interrupt issue)
#
# Known Limitations:
# -----------------
# - WebR runs in synchronous mode only (workers=1)
# - Async parallel processing only available in native R with crew
# - Future work: Investigate if newer mirai/nanonext versions support WebR
# ==============================================================================
