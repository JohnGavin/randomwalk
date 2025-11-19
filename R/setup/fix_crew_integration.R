# Fix Crew Integration Issues
# Date: 2025-11-19
# Purpose: Fix crew API integration bugs in Phase 1 async implementation
# Issue: #21 - v2.0.0 Phase 1: Minimal Async Implementation
# PR: #29 - Phase 1: Async Simulation Framework

# Problem Description:
# ===================
# The async implementation had 17 failing tests due to crew API integration issues.
# Error: "attempt to select less than one element in OneIndex" at R/simulation.R:270
#
# Root Causes:
# 1. Command parameter in controller$push() used named arguments instead of positional
#    - crew expects command to reference variable names from the data list
#    - Named arguments cause immediate evaluation in main process
#
# 2. Result extraction assumed wrong structure
#    - crew returns a data frame where result$result[[1]] contains the return value
#    - Original code used result$result directly
#
# 3. Walker ID indexing issue
#    - Using walker$id directly as list index could fail
#    - Should convert to character for safe indexing

# Fixes Applied:
# ==============

# Fix 1: Updated R/simulation.R lines 240-241
# Changed FROM:
#   command = randomwalk::worker_run_walker(
#     walker = walker,
#     grid_state = grid_state,
#     pub_address = pub_address,
#     neighborhood = neighborhood,
#     boundary = boundary,
#     max_steps = max_steps
#   ),
#
# Changed TO:
#   command = randomwalk::worker_run_walker(
#     walker, grid_state, pub_address, neighborhood, boundary, max_steps
#   ),

# Fix 2: Updated R/simulation.R lines 266-278
# Changed FROM:
#   if (!is.null(result) && !is.null(result$result)) {
#     walker <- result$result
#     completed_walkers[[walker$id]] <- walker
#
# Changed TO:
#   if (!is.null(result) && nrow(result) > 0) {
#     walker <- result$result[[1]]
#
#     # Validate walker structure
#     if (is.null(walker) || is.null(walker$id)) {
#       logger::log_error("Invalid walker structure returned from crew worker")
#       logger::log_debug("Result structure: {paste(capture.output(str(result)), collapse = '; ')}")
#       next
#     }
#
#     completed_walkers[[as.character(walker$id)]] <- walker

# Fix 3: Updated default.nix to include crew package
# Added 'crew' to the rpkgs list in default.nix line 21

# Expected Outcome:
# ================
# These fixes should resolve the crew integration issues:
# - Commands will be evaluated in worker processes (not main process)
# - Results will be extracted correctly from crew's data frame structure
# - Walker indexing will be safe and consistent
# - All 17 failing async tests should pass

# Testing Plan:
# =============
# Once crew is available in the nix environment:
#
# 1. Rebuild nix shell with updated default.nix:
#    nix-shell
#
# 2. Run specific async tests:
#    devtools::test_active_file("tests/testthat/test-async.R")
#
# 3. Run all tests:
#    devtools::test()
#
# 4. Run benchmarks:
#    source("benchmarks/benchmark_async.R")
#
# 5. Verify expected speedup (1.5-1.8x with 2 workers)

# Files Modified:
# ==============
# - R/simulation.R (2 fixes)
# - default.nix (added crew to rpkgs)
# - R/setup/fix_crew_integration.R (this file)

# Next Steps:
# ===========
# 1. Commit these fixes
# 2. Push to async-v2-phase1 branch
# 3. Rebuild nix environment with crew
# 4. Run tests to verify fixes
# 5. If tests pass, run benchmarks
# 6. Update PR #29 to "Ready for Review"
# 7. Merge to main and close issue #21

# References:
# ===========
# - crew documentation: https://wlandau.github.io/crew/
# - Issue #21: https://github.com/JohnGavin/randomwalk/issues/21
# - PR #29: https://github.com/JohnGavin/randomwalk/pull/29
# - PHASE1_STATUS.md: Detailed status and debugging roadmap
