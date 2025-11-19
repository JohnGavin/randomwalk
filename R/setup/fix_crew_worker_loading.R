# Fix Crew Worker Package Loading Issue
# Date: 2025-11-19
# Purpose: Fix crew workers not being able to load randomwalk package in nix environment
# Issue: Workers can't load installed package because nix is read-only
# Solution: Pass functions as globals instead of relying on package loading
#
# Related to: Issue #21, async-v2-phase1 branch
# Previous fixes: CREW_FIXES_SUMMARY.md

# Root cause analysis:
# The error "worker_run_walker' is not an exported object from 'namespace:randomwalk'"
# occurs because:
# 1. Crew workers run in separate R processes
# 2. They try to load randomwalk package via `packages = "randomwalk"`
# 3. In nix environment, package is not installed (nix store is read-only)
# 4. devtools::load_all() only affects main process, not workers

# Solution: Use globals parameter to pass the function directly
#
# From crew documentation, push() has these parameters:
# - globals: list of objects to export to worker environment
# - library: custom library paths
#
# We'll modify R/simulation.R to:
# 1. Remove randomwalk:: prefix from command
# 2. Pass worker_run_walker and helper functions as globals
# 3. Alternatively, use library parameter to point to nix package location

library(logger)

log_info("=== Fix 4: Crew Worker Package Loading ===")
log_info("Date: 2025-11-19")
log_info("Branch: async-v2-phase1")
log_info("")

# The fix will be applied to R/simulation.R around lines 236-252
log_info("Fix approach:")
log_info("1. Change command to not use randomwalk:: namespace prefix")
log_info("2. Pass worker_run_walker function via globals parameter")
log_info("3. Include all helper functions needed by worker_run_walker")
log_info("")

log_info("Required globals:")
log_info("- worker_run_walker (main function)")
log_info("- worker_init (initializes worker state)")
log_info("- worker_step_walker (steps walker)")
log_info("- check_termination_cached (checks termination)")
log_info("- get_neighbors (gets neighbor positions)")
log_info("- is_within_bounds (checks bounds)")
log_info("- wrap_position (wraps position for wrap boundary)")
log_info("- step_walker (moves walker)")
log_info("")

log_info("Fix will be applied manually to R/simulation.R")
log_info("Modified lines: 236-252")
log_info("")
log_info("Before:")
log_info('  command = randomwalk::worker_run_walker(...),')
log_info('  packages = "randomwalk"')
log_info("")
log_info("After:")
log_info('  command = worker_run_walker(...),')
log_info('  globals = list(')
log_info('    worker_run_walker = worker_run_walker,')
log_info('    worker_init = worker_init,')
log_info('    worker_step_walker = worker_step_walker,')
log_info('    ... (other helpers)')
log_info('  )')
log_info("")

log_info("This fix will allow crew workers to execute tasks without needing")
log_info("the randomwalk package installed in the nix environment.")
