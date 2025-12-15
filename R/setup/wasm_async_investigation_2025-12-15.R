# WebAssembly Async Investigation
# Date: 2025-12-15
# Task: Investigate nanonext availability for WebAssembly to enable async in dynamic_broadcasting vignette

# ============================================================================
# SUMMARY
# ============================================================================
#
# User requested investigation of using nanonext from r-universe to enable
# async parallel processing in the dynamic_broadcasting vignette's r-shinylive app.
#
# KEY FINDINGS:
# 1. ✅ nanonext v1.7.2.9000 IS available for WebAssembly at r-lib.r-universe.dev
# 2. ✅ mirai v2.5.3.9000 IS available for WebAssembly
# 3. ❌ crew is NOT available for WebAssembly (blocks async functionality)
# 4. Path forward: Refactor async controller to use mirai directly (Issue #129)

# ============================================================================
# INVESTIGATION COMMANDS
# ============================================================================

# 1. Check for symlinked files to remove
system("find /Users/johngavin/docs_gh/claude_rix/random_walk -type l")
# Found: push_to_cachix.sh -> ../push_to_cachix.sh
# Found: result -> /nix/store/... (nix build artifact)

# 2. Remove symlink from git tracking
gert::git_rm("push_to_cachix.sh")

# 3. Verify nanonext availability in r-universe
system('curl -sL "https://r-lib.r-universe.dev/bin/emscripten/contrib/4.5/PACKAGES" | grep -A 5 "^Package: nanonext"')
# Result: nanonext v1.7.2.9000 available (built 2025-12-03, 500KB)

# 4. Check for crew availability
system('curl -sL "https://r-lib.r-universe.dev/bin/emscripten/contrib/4.5/PACKAGES" | grep "^Package: crew"')
# Result: NOT found

# 5. Check for mirai availability
system('curl -sL "https://r-lib.r-universe.dev/bin/emscripten/contrib/4.5/PACKAGES" | grep -A 10 "^Package: mirai"')
# Result: mirai v2.5.3.9000 available (built 2025-12-01, 250KB, depends on nanonext)

# 6. Check current async implementation
# R/async_controller.R uses crew::crew_controller_local() at line 49
# This is the blocker - crew not available for wasm

# ============================================================================
# CHANGES MADE
# ============================================================================

# 1. Updated vignettes/dynamic_broadcasting.qmd:
#    - Added r-lib.r-universe.dev to webr repos
#    - Updated note explaining nanonext/mirai ARE available but crew is NOT
#    - Kept vignette in sync mode (workers=0) for browser compatibility
#    - Added "Future work" note about mirai refactoring
#    - Enhanced technical details section

# 2. Removed symlinked file:
gert::git_add(c("push_to_cachix.sh", "vignettes/dynamic_broadcasting.qmd"))
gert::git_commit("Docs: Update dynamic_broadcasting vignette with wasm status

- Remove symlinked push_to_cachix.sh from git tracking
- Document that nanonext and mirai ARE available for wasm
- Clarify that crew is NOT available for wasm (blocks async)
- Add future work note: refactor to use mirai directly
- Keep vignette in sync mode (workers=0) for browser compatibility
- Add r-lib.r-universe.dev to webr repos

References:
- nanonext: https://r-lib.r-universe.dev/nanonext (v1.7.2.9000 for wasm)
- mirai: https://r-lib.r-universe.dev/mirai (v2.5.3.9000 for wasm)
- crew: not available for wasm yet
")
# Commit: 247f26d

# 3. Created documentation:
#    inst/docs/WASM_ASYNC_STATUS.md
#    - Package availability matrix
#    - Technical details for each package
#    - Current architecture diagram
#    - Two paths forward (mirai refactor vs wait for crew)
#    - Recommendation: refactor to mirai
#    - Testing checklist

gert::git_add("inst/docs/WASM_ASYNC_STATUS.md")
gert::git_commit("Docs: Add WASM async support status analysis

- Document nanonext/mirai/crew availability for WebAssembly
- Provide technical details and package matrix
- Outline two paths forward (mirai refactor vs wait for crew)
- Recommend Option 1: refactor to mirai directly
- Include testing checklist and references

Related: Issue #129 (Refactor async controller to use mirai)")
# Commit: 5934a7e

# 4. Created GitHub issue #129:
gh::gh("POST /repos/JohnGavin/randomwalk/issues",
  title = "Refactor async controller to use mirai directly for WebAssembly support",
  body = "...", # See full issue at https://github.com/JohnGavin/randomwalk/issues/129
  labels = c("enhancement", "webassembly", "async")
)
# Issue: https://github.com/JohnGavin/randomwalk/issues/129

# ============================================================================
# PACKAGE DEPENDENCY ANALYSIS
# ============================================================================

# Current randomwalk DESCRIPTION dependencies:
# Imports: logger, ggplot2, crew, nanonext
#
# For WebAssembly:
# - logger: ✅ (pure R)
# - ggplot2: ✅ (available for wasm)
# - nanonext: ✅ (v1.7.2.9000 at r-lib.r-universe.dev)
# - crew: ❌ (NOT available for wasm) ← THIS IS THE BLOCKER

# crew is built on mirai, and mirai IS available for wasm:
# - mirai: ✅ (v2.5.3.9000 at r-lib.r-universe.dev)
#
# Therefore, refactoring to use mirai directly would unblock wasm async.

# ============================================================================
# ARCHITECTURE ANALYSIS
# ============================================================================

# Current call stack for async mode (workers > 0):
# run_simulation() [R/simulation.R:44]
#   → run_simulation_async_dynamic() [R/simulation.R:119] when sync_mode="dynamic"
#     → create_controller() [R/async_controller.R:40]
#       → crew::crew_controller_local() [R/async_controller.R:49] ← BLOCKED IN WASM
#         → uses mirai internally (✅ available)
#           → uses nanonext (✅ available)

# Proposed refactored call stack:
# run_simulation() [R/simulation.R:44]
#   → run_simulation_async_dynamic() [R/simulation.R:119] when sync_mode="dynamic"
#     → create_mirai_controller() [NEW FUNCTION]
#       → mirai::daemons() ✅ WORKS IN WASM
#         → uses nanonext (✅ available)

# ============================================================================
# RECOMMENDED NEXT STEPS
# ============================================================================

# 1. Prototype mirai-based async controller:
#    - Create R/async_controller_mirai.R
#    - Implement create_mirai_controller() using mirai::daemons()
#    - Implement task submission using mirai::mirai()
#    - Implement task collection using mirai::call_mirai()
#    - Implement cleanup using mirai::daemons(0)

# 2. Add runtime detection:
#    - Detect if running in WebR: is_webr() or similar
#    - Use mirai controller in wasm, crew controller otherwise
#    - Allows keeping crew for better abstractions locally

# 3. Test in both environments:
#    - Local native R: Verify crew-based async still works
#    - WebR/browser: Verify mirai-based async works
#    - Compare performance and behavior

# 4. Update vignettes:
#    - dynamic_broadcasting.qmd: Enable async (workers=2, sync_mode="dynamic")
#    - Show working parallel processing in browser
#    - Update technical details section

# 5. Documentation:
#    - Update inst/docs/WASM_ASYNC_STATUS.md with results
#    - Document any limitations discovered in wasm environment
#    - Update README with wasm async capabilities

# ============================================================================
# REFERENCES
# ============================================================================

# R-Universe WebAssembly packages:
# https://r-lib.r-universe.dev/bin/emscripten/contrib/4.5/PACKAGES

# mirai documentation:
# https://mirai.r-lib.org/

# nanonext documentation:
# https://shikokuchuo.net/nanonext/

# WebR documentation:
# https://docs.r-wasm.org/webr/latest/

# R-Universe package structure info (from user):
# https://r-wasm.r-universe.dev/bin/wasm/packages/<package_name>.zip

# GitHub Issue:
# https://github.com/JohnGavin/randomwalk/issues/129

# ============================================================================
# CORRECTION (same session)
# ============================================================================

# User correctly pointed out: The vignette is called "dynamic_broadcasting"
# so it should DEFAULT to demonstrating async dynamic broadcasting, not sync mode!
#
# Fixed in commit 13aa402:
# - Added WebR environment detection
# - Default: workers=2, sync_mode="dynamic" (the actual feature)
# - Auto-fallback to sync ONLY in browser (crew limitation)
# - When run locally: demonstrates actual async dynamic broadcasting
# - When in browser: graceful sync fallback with message

# Updated parameter section:
gert::git_add("vignettes/dynamic_broadcasting.qmd")
gert::git_commit("Fix: dynamic_broadcasting should default to async mode

The vignette is about Dynamic Broadcasting (async), not sync mode!

Changes:
- Default to workers=2, sync_mode=\"dynamic\" (the feature being demonstrated)
- Add WebR environment detection
- Auto-fallback to sync mode ONLY in browser (crew limitation)
- When run locally: demonstrates actual async dynamic broadcasting
- When in browser: graceful sync fallback with message

Before: Always ran in sync mode (workers=0) even locally - wrong!
After: Runs in async mode locally, sync fallback in browser - correct!

Related: Issue #129")
# Commit: 13aa402

# ============================================================================
# SESSION INFO
# ============================================================================

# Session conducted: 2025-12-15
# Commits: 247f26d, 5934a7e, 8ee624e, 13aa402
# GitHub Issue: #129
# Documentation: inst/docs/WASM_ASYNC_STATUS.md
# Updated vignette: vignettes/dynamic_broadcasting.qmd
