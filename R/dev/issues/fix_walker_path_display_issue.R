# Fix: Walker Path Display Shows Wrong Walkers
# Date: 2026-02-03
# Author: Claude
# Issue: Dashboard shows walkers 1-20 by ID, not first 20 to terminate

# PROBLEM IDENTIFIED:
# ==================
# The user correctly identified that the "First N paths" display is misleading.
#
# Current behavior:
# - Shows walkers with IDs 1-20 (arbitrary assignment at start)
# - These are NOT the first 20 walkers to terminate chronologically
#
# Why this matters:
# - In DLA fractal growth, the FIRST walker to terminate hits the center pixel
# - The SECOND walker to terminate hits either center or walker 1's pixel
# - By the 20th termination, all pixels should be clustered near center
# - But we're showing random walkers that may terminate much later
#
# THE SIMULATION FLOW:
# ====================
# run_simulation() in simulation.R (sync mode):
# 1. Creates n_walkers with IDs 1 to n_walkers
# 2. ALL walkers move simultaneously each step:
#    while (active_walkers > 0):
#      - ALL active walkers take 1 step
#      - ALL active walkers check termination
#      - Terminated walkers turn their pixel black
# 3. Result: walker ID has NO relation to termination order
#
# Example with 100 walkers:
# - Walker #73 might be first to hit center and terminate
# - Walker #15 might be second to terminate
# - Walker #1 might be 50th to terminate
# - Current display shows #1-20, missing the actual first terminators!

# SOLUTION OPTIONS:
# =================

# Option 1: Track termination order
modify_simulation <- function() {
  # Add termination_order field to each walker
  # When walker terminates, assign next sequence number
  # In dashboard, sort by termination_order, not ID

  # Pseudocode for simulation.R:
  # termination_counter <- 0
  # if (!walker$active && is.null(walker$termination_order)) {
  #   termination_counter <- termination_counter + 1
  #   walker$termination_order <- termination_counter
  # }
}

# Option 2: Change UI labels
fix_ui_labels <- function() {
  # Current: "First N paths" (misleading - suggests chronological)
  # Better: "Walker IDs 1-N" (accurate but less meaningful)
  # Or: "Random sample of N paths" (if we randomize selection)
}

# Option 3: Implement true chronological tracking
track_chronological <- function() {
  # Maintain separate list of walkers in termination order
  # completed_walkers_ordered <- list()
  # When walker terminates, append to this list
  # Dashboard uses this list instead of original walkers list
}

# EVIDENCE FROM CODE:
# ==================

# simulation.R lines 240-269 (sync mode):
# while (length(active_indices) > 0) {
#   for (i in active_indices) {          # <-- Processes ALL active walkers
#     walker <- walkers[[i]]
#     walker <- step_walker(walker, ...)  # <-- Each takes ONE step
#     walker <- check_termination(...)    # <-- Check if should stop
#   }
# }

# dashboard_comprehensive.qmd lines 518-520:
# walker_ids <- unique(c(
#   if(first_n > 0) 1:first_n else NULL,  # <-- Selects by ID, not termination order!
#   if(last_n > 0) (n_walkers - last_n + 1):n_walkers else NULL
# ))

# WHY USER SAW FAR-FROM-CENTER PATHS:
# ===================================
# 1. Simulation runs 100+ walkers simultaneously
# 2. Many walkers terminate near center early
# 3. Fractal grows outward with more black pixels
# 4. Walker #1-20 (by ID) might terminate late, far from center
# 5. Dashboard shows these late-terminating walkers as "First 20"
# 6. User correctly notices they're too far from center for early walkers

print("Issue identified: Walker display shows IDs 1-20, not first 20 to terminate")
print("This explains why 'first' walkers appear far from center")
print("Solution: Track and display by termination order, not walker ID")