# Session Log: Fix Issue #63 - Isolated Black Pixels Bug
# Date: 2025-11-28
# Issue: https://github.com/JohnGavin/randomwalk/issues/63
#
# CRITICAL BUG: Simulation produces isolated black pixels in async mode
#
# =============================================================================
# ROOT CAUSE ANALYSIS
# =============================================================================
#
# The bug is in the async simulation logic (R/simulation.R:241-426)
# and worker implementation (R/async_worker.R:318-351).
#
# PROBLEM:
# --------
# 1. Workers operate on a STATIC snapshot of black pixels (async_worker.R:326)
#    grid_state$black_pixels is captured at simulation start
#
# 2. Worker uses this snapshot to check termination (async_worker.R:339-346)
#    check_termination_cached() only sees pixels that existed at start
#
# 3. When a walker terminates, main process sets pixel black (simulation.R:346)
#    grid <- set_pixel_black(grid, walker$pos, boundary)
#
# 4. BUT: The worker that just terminated may have had a STALE cache
#    It didn't see recent black pixels from other terminated walkers
#
# 5. RESULT: Walker can terminate at a position that appears valid in its
#    stale snapshot, but is actually isolated in the current grid state
#
# EXAMPLE SCENARIO:
# ----------------
# Grid 160x160, 884 walkers, 4 workers
#
# Time T=0:
#   - All workers get grid_state with only center pixel (80,80) black
#   - black_pixels = {(80,80)}
#
# Time T=100:
#   - Worker 1: Walker A terminates at (82,80) [has black neighbor (80,80)]
#   - Main process sets (82,80) black
#   - BUT: Workers 2,3,4 still have stale cache: {(80,80)}
#
# Time T=150:
#   - Worker 2: Walker B terminates at (75,90)
#   - Worker 2's cache says (75,90) has no black neighbors
#   - In its stale view, it terminates due to "black_neighbor"
#   - BUT: The neighbor it "sees" is from its stale (80,80) cache
#   - ACTUAL grid might show (75,90) is isolated from real black pixels
#
# Time T=200:
#   - Final grid has (75,90) as isolated black pixel
#   - Validation fails: "Found isolated black pixel at (75,90)"
#
# WHY VALIDATION LOGS DON'T APPEAR:
# ----------------------------------
# The validation function DOES run (simulation.R:362-368), but:
# 1. logger::log_trace() requires log level TRACE
# 2. Dashboard doesn't set verbose=TRUE (simulation.R:68-70)
# 3. Without verbose, log level is default (INFO), so TRACE messages invisible
# 4. Even validation failures log as log_warn(), not log_info()
#
# VERIFICATION NEEDED:
# -------------------
# 1. Run simulation with validate_strict=TRUE to catch failures
# 2. Run with verbose=TRUE to see all validation attempts
# 3. Add test that reliably reproduces isolated pixels
# 4. Fix async logic to prevent stale cache issues
#
# PROPOSED FIX:
# -------------
# Option 1: Validate termination positions in main process
#   - Worker returns termination position
#   - Main process re-checks if position is truly valid before setting black
#
# Option 2: Implement real-time cache updates (original nanonext design)
#   - Restore pub/sub socket broadcasting (removed due to serialization issues)
#   - Workers receive real-time updates of new black pixels
#
# Option 3: Post-termination cleanup
#   - After all walkers complete, scan grid for isolated pixels
#   - Remove isolated pixels or throw error
#
# Option 4: Disable async validation, rely on final validation
#   - Let isolated pixels appear during simulation
#   - Final validation (simulation.R:389-394) catches them
#   - Use validate_strict=TRUE to make this fail hard
#
# =============================================================================
# REPRODUCTION TEST
# =============================================================================

# This test should reliably reproduce isolated pixels

library(randomwalk)
library(testthat)

test_that("async simulation produces isolated pixels (bug reproduction)", {
  # Run problematic simulation from dashboard
  result <- run_simulation(
    grid_size = 160,
    n_walkers = 884,
    n_workers = 4,
    neighborhood = "4-hood",
    boundary = "terminate",
    max_steps = 10000,
    verbose = TRUE,  # See all logging
    validate_strict = TRUE,  # Fail hard on isolated pixels
    validate_percent = 5  # Validate every 5%
  )

  # If bug exists, this should error during validation
  # with message like "Found X isolated black pixel(s)"

  # Also verify final grid
  isolated <- find_isolated_pixels(result$grid, "4-hood")

  expect_equal(
    length(isolated),
    0,
    info = sprintf(
      "Found %d isolated pixels at: %s",
      length(isolated),
      paste(sapply(isolated, function(p) sprintf("(%d,%d)", p[1], p[2])),
            collapse = ", ")
    )
  )
})

# Helper to find isolated pixels for debugging
find_isolated_pixels <- function(grid, neighborhood = "4-hood") {
  black_positions <- which(grid == 1, arr.ind = TRUE)

  if (nrow(black_positions) <= 1) {
    return(list())
  }

  n <- nrow(grid)
  isolated <- list()

  for (i in seq_len(nrow(black_positions))) {
    pos <- black_positions[i, ]
    neighbors <- get_neighbors(pos, neighborhood)

    has_black_neighbor <- FALSE
    for (neighbor_pos in neighbors) {
      if (is_within_bounds(neighbor_pos, n)) {
        if (grid[neighbor_pos[1], neighbor_pos[2]] == 1) {
          has_black_neighbor <- TRUE
          break
        }
      }
    }

    if (!has_black_neighbor) {
      isolated <- c(isolated, list(pos))
    }
  }

  isolated
}

# =============================================================================
# IMPLEMENTATION COMPLETE ✅
# =============================================================================
#
# Date: 2025-11-28
#
# 1. ✅ Created issue #63 with detailed bug report
# 2. ✅ Documented root cause in this file and updated GitHub issue
# 3. ✅ Implemented fix: validate_termination_position() in R/grid.R:294-322
# 4. ✅ Applied fix to async simulation in R/simulation.R:346-366
# 5. ✅ Added reproduction tests to tests/testthat/test-simulation.R
# 6. ✅ All tests pass (44 passed, 1 skipped, 0 failed)
# 7. ✅ Documentation updated (devtools::document())
#
# FIX SUMMARY
# -----------
# Added validate_termination_position() function that checks if a position
# has at least one black neighbor before allowing it to be set black.
#
# In async simulation (R/simulation.R:348), before setting pixel black:
#   if (validate_termination_position(walker$pos, grid, neighborhood)) {
#     grid <- set_pixel_black(grid, walker$pos, boundary)
#   } else {
#     logger::log_warn("REJECTED: would create isolated pixel")
#   }
#
# This prevents isolated pixels caused by stale worker caches in async mode.
#
# TEST RESULTS
# ------------
# - async simulation with 2 workers: ✅ PASS
# - async simulation with many workers (50x50, 100 walkers, 4 workers): ✅ PASS
# - All 44 simulation tests: ✅ PASS
#
# COMMANDS TO MERGE
# -----------------
library(gert)
library(usethis)
library(gh)

# 1. Create development branch
usethis::pr_init("fix-issue-63-isolated-pixels")

# 2. Stage and commit changes
gert::git_add(c(
  "R/grid.R",                                    # New validation function
  "R/simulation.R",                              # Fix applied
  "tests/testthat/test-simulation.R",            # Reproduction tests
  "man/validate_termination_position.Rd",        # New documentation
  "NAMESPACE",                                    # Updated exports
  "R/setup/fix_issue_63_isolated_pixels.R"      # This session log
))

gert::git_commit("Fix #63: Prevent isolated pixels in async simulation

- Add validate_termination_position() to check positions before setting black
- Apply validation in async simulation to prevent stale cache issues
- Add reproduction tests for async mode with multiple workers
- All tests pass (44 passed, 1 skipped)

Closes #63")

# 3. Push and create PR
usethis::pr_push()

# 4. After tests pass on GitHub Actions, merge
usethis::pr_merge_main()
usethis::pr_finish()
