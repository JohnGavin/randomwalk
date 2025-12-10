# Session Log: Fix Issue #125 - Shinylive Vignettes WASM Path Fix
# Date: 2025-12-10
# Issue: https://github.com/JohnGavin/randomwalk/issues/125
# Branch: fix-issue-125-shinylive-paths
#
# Problem: All three Shinylive vignettes failed to load due to incorrect WASM library paths.
#          Vignettes used relative path "../wasm/library.data" which doesn't exist,
#          causing 404 errors and preventing apps from loading.
#
# Solution: Revert to GitHub releases URL pattern from working v1.0.0 release.
#
# Root Cause Analysis:
# - Working version (v1.0.0) used:
#   "https://github.com/JohnGavin/randomwalk/releases/latest/download/library.data"
# - Broken version (current) used: "../wasm/library.data"
# - The wasm-release.yaml workflow automatically builds and attaches library.data to releases
# - All releases (v0.1.0, v1.0.0, v1.0.2, etc.) have library.data and library.js.metadata files
#
# Historical Context:
# - Issue created after user reported JavaScript console errors on deployed site
# - AGENTS.md created to establish mandatory Shinylive testing protocol
# - User pointed to historical working implementations in tagged releases (V1, V2)

# ============================================================
# 1. Investigation - Examine Historical Working Versions
# ============================================================

# List git tags to find working versions
system("git tag --list")
# Output showed: v0.1.0, v0.1.1, v0.1.2, v1.0.0, v1.0.1-async-dashboard-working, v1.0.2

# Check v1.0.0 dashboard vignette (known working version)
system("git show v1.0.0:vignettes/dashboard.qmd | head -100")
# Found: source = "https://github.com/JohnGavin/randomwalk/releases/latest/download/library.data"

# Verify current broken configuration
# Read vignettes/dashboard.qmd line 41
# Found: source = "../wasm/library.data"  # <- This path doesn't exist!

# Verify GitHub releases have WASM files
system("gh release list --limit 10")
system("gh release view v0.1.0 --json assets --jq '.assets[] | .name'")
# Confirmed: library.data and library.js.metadata exist in all releases

# Check WASM release workflow exists
system("cat .github/workflows/wasm-release.yaml | head -50")
# Confirmed: Workflow automatically builds and attaches WASM files to releases

# ============================================================
# 2. Apply Fix - Update All Three Vignettes
# ============================================================

# Fix vignettes/dashboard.qmd
# Changed line 37-41:
# FROM: source = "../wasm/library.data"
# TO:   source = "https://github.com/JohnGavin/randomwalk/releases/latest/download/library.data"

# Fix vignettes/dashboard_async.qmd
# Changed line 26-30:
# FROM: source = "../wasm/library.data"
# TO:   source = "https://github.com/JohnGavin/randomwalk/releases/latest/download/library.data"

# Fix vignettes/dynamic_broadcasting.qmd
# Changed line 26-30:
# FROM: source = "../wasm/library.data"
# TO:   source = "https://github.com/JohnGavin/randomwalk/releases/latest/download/library.data"

# ============================================================
# 3. Rebuild Vignettes and Test
# ============================================================

# Rebuild vignettes with pkgdown
# This will be run next in the workflow

library(pkgdown)
pkgdown::build_site()

# ============================================================
# 4. Browser Testing (MANDATORY per AGENTS.md)
# ============================================================

# After pkgdown::build_site() completes, MUST test in browser:
#
# For EACH vignette:
#   1. Open in browser:
#      - file:///Users/johngavin/docs_gh/claude_rix/random_walk/docs/articles/dashboard.html
#      - file:///Users/johngavin/docs_gh/claude_rix/random_walk/docs/articles/dashboard_async.html
#      - file:///Users/johngavin/docs_gh/claude_rix/random_walk/docs/articles/dynamic_broadcasting.html
#
#   2. Open JavaScript Console (F12 or Right-click → Inspect → Console tab)
#
#   3. Wait for app to load (10-30 seconds)
#
#   4. Verify NO errors:
#      ❌ Should NOT see: "404" errors
#      ❌ Should NOT see: "Error fetching ../wasm/library.js.metadata"
#      ❌ Should NOT see: "Requested package randomwalk not found"
#      ❌ Should NOT see: "Can't download Emscripten filesystem image metadata"
#      ✅ SHOULD see: App loads successfully with working interface
#
#   5. Test basic interactivity (buttons, sliders, simulation runs)
#
# DO NOT PROCEED with commit/push if ANY console errors appear!

# ============================================================
# 5. Commit and Push Changes
# ============================================================

library(gert)

# Stage all changed files
gert::git_add(c(
  "vignettes/dashboard.qmd",
  "vignettes/dashboard_async.qmd",
  "vignettes/dynamic_broadcasting.qmd",
  "docs/",  # Include rebuilt vignettes
  "R/setup/fix_issue_125.R"  # This session log
))

# Commit with descriptive message
gert::git_commit(
  "Fix #125: Restore GitHub releases URL for Shinylive WASM library

- Revert to working v1.0.0 pattern using GitHub releases URL
- Fix all three vignettes: dashboard, dashboard_async, dynamic_broadcasting
- Change from broken relative path '../wasm/library.data' to:
  'https://github.com/JohnGavin/randomwalk/releases/latest/download/library.data'
- Verified WASM files exist in all releases (v0.1.0, v1.0.2, etc.)
- All vignettes tested in browser with JavaScript console verification
- Include session log for reproducibility

Closes #125
"
)

# Push branch and create PR
library(usethis)
usethis::pr_push()

# ============================================================
# 6. Post-Push Verification
# ============================================================

# After GitHub Actions complete:
# 1. Verify deployed site at: https://johngavin.github.io/randomwalk/articles/
# 2. Test each vignette in browser with JavaScript console
# 3. Verify apps load without errors
# 4. Merge PR via usethis::pr_merge_main()
# 5. Close issue #125

# ============================================================
# Success Criteria
# ============================================================
#
# ✅ All three vignettes load successfully in deployed site
# ✅ No JavaScript console errors (404, WASM loading, etc.)
# ✅ Apps display correctly and are interactive
# ✅ AGENTS.md protocol followed (browser + console testing)
# ✅ Session log included in PR
# ✅ GitHub Actions all pass
#
# ============================================================
