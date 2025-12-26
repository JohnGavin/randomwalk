# ==============================================================================
# Issue #157: Switch to r-lib.r-universe.dev Development Versions
# ==============================================================================
# Date: 2025-12-26
# Problem: Custom-built stable versions (nanonext 1.7.2, mirai 2.5.3) have
#          version incompatibility. nanonext v1.7.2 doesn't export .dispatcher
#          which mirai v2.5.3 might expect in certain scenarios.
#
# Investigation Findings:
# ----------------------
# 1. r-lib.r-universe.dev has webR-compiled development versions:
#    - nanonext 1.7.2.9000 (exports .dispatcher) ✅
#    - mirai 2.5.3.9000 (imports .dispatcher) ✅
#
# 2. These versions are already built for webR/emscripten (R 4.5.1)
#
# 3. Both development versions are compatible with each other
#
# 4. The mysterious ".interrupt" error was misleading - neither version
#    uses .interrupt. The real incompatibility was .dispatcher.
#
# Solution:
# ---------
# Update vignettes to install mirai/nanonext from r-lib.r-universe.dev
# instead of our custom-built versions.
#
# Changes:
# --------
# 1. vignettes/articles/dynamic_broadcasting.qmd:
#    - Updated package installation to use r-lib.r-universe.dev
#    - Updated comments to reflect development versions
#
# 2. vignettes/articles/dashboard_comprehensive.qmd:
#    - Same updates as dynamic_broadcasting.qmd
#
# 3. Re-rendered both vignettes with SHINYLIVE_ASSETS_VERSION=0.10.7
#
# 4. Copied rendered HTML and ServiceWorker files to docs/articles/
#
# Files Changed:
# -------------
# - vignettes/articles/dynamic_broadcasting.qmd
# - vignettes/articles/dashboard_comprehensive.qmd
# - docs/articles/dynamic_broadcasting.html (regenerated)
# - docs/articles/dashboard_comprehensive.html (regenerated)
# - vignettes/articles/dynamic_broadcasting.html (regenerated)
# - vignettes/articles/dashboard_comprehensive.html (regenerated)
#
# Expected Result:
# ---------------
# mirai and nanonext should load successfully in browser with no .interrupt
# or .dispatcher errors, enabling async parallel processing in WebAssembly.
#
# Related Issues:
# --------------
# - #151: nanonext/mirai compatibility tracking issue
# - #155: Custom WASM package building (now superseded by r-universe)
# - #156: Custom repository usage (now superseded by r-universe)
#
# References:
# ----------
# - https://r-lib.r-universe.dev/nanonext - nanonext 1.7.2.9000
# - https://r-lib.r-universe.dev/mirai - mirai 2.5.3.9000
# - https://shikokuchuo.net/ - Package author's website
# ==============================================================================

# Verification commands
# ---------------------

# 1. Check r-universe versions
curl -s "https://r-lib.r-universe.dev/bin/emscripten/contrib/4.5/PACKAGES" | grep -A10 "Package: nanonext"
curl -s "https://r-lib.r-universe.dev/bin/emscripten/contrib/4.5/PACKAGES" | grep -A10 "Package: mirai"

# 2. Verify nanonext NAMESPACE exports .dispatcher
curl -sL "https://r-lib.r-universe.dev/bin/emscripten/contrib/4.5/nanonext_1.7.2.9000.tgz" | \
  tar -xzf - nanonext/NAMESPACE && grep "export(.dispatcher)" nanonext/NAMESPACE

# 3. Verify mirai NAMESPACE imports .dispatcher
curl -sL "https://r-lib.r-universe.dev/bin/emscripten/contrib/4.5/mirai_2.5.3.9000.tgz" | \
  tar -xzf - mirai/NAMESPACE && grep "importFrom(nanonext,.dispatcher)" mirai/NAMESPACE

# End of log
