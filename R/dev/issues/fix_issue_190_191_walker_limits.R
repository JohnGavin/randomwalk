# Fix for Issues #190 and #191: Walker Limits and WebR UI Improvements
# Date: 2026-02-01
# Author: Claude

# Issue #190: Increase maximum walker limit (using dynamic 70% of grid pixels)
# Issue #191: Remove confusing workers slider in WebR dashboard

# Summary of Changes:
# -----------------
# 1. Fixed walker limit to consistently use 70% of grid pixels across all dashboards
# 2. WebR dashboard already had no worker slider (correct implementation)

# Files Modified:
# --------------
# 1. inst/shiny/dashboard/app.R
#    - Changed walker limit from 30% to 70% of grid pixels
#    - Line 159: Changed from 0.3 to 0.7
#    - For 400x400 grid: max walkers = floor(0.7 * 160000) = 112,000

# 2. vignettes/articles/dashboard_comprehensive.qmd
#    - Added helpText showing "Max: 70% of grid pixels"
#    - Added observe block for dynamic walker limit updates
#    - Added validation to prevent exceeding 70% limit

# Testing Verification:
# --------------------
# Grid Size | Max Walkers (70%)
# ----------|------------------
# 20x20     | 280
# 50x50     | 1,750
# 100x100   | 7,000
# 200x200   | 28,000
# 400x400   | 112,000

# Code Changes:
# ------------

# 1. dashboard/app.R (line 159)
# Before:
# max_walkers <- floor(input$grid_size * input$grid_size * 0.3)
# After:
# max_walkers <- floor(0.7 * input$grid_size^2)

# 2. dashboard_comprehensive.qmd
# Added after line 116:
# helpText(HTML("Number of walkers to simulate<br><em>Max: 70% of grid pixels (updates automatically)</em>"))

# Added after line 239 (in server function):
# observe({
#   max_walkers <- floor(0.7 * input$grid_size^2)
#   updateSliderInput(
#     session,
#     "n_walkers",
#     max = max_walkers,
#     value = min(input$n_walkers, max_walkers)
#   )
# })

# Added validation before run_simulation():
# max_allowed <- floor(0.7 * input$grid_size^2)
# if (input$n_walkers > max_allowed) {
#   stop(sprintf("Too many walkers (%d) for grid size %dx%d. Maximum allowed: %d (70%% of grid pixels)",
#                input$n_walkers, input$grid_size, input$grid_size, max_allowed))
# }

# Note on WebR Worker Slider (Issue #191):
# ----------------------------------------
# The dashboard_comprehensive.qmd (WebR dashboard) already correctly
# has NO worker slider. It's hard-coded to use workers=0 because
# WebR doesn't support parallel processing (mirai/nanonext not available
# in WebAssembly). The dashboard correctly shows this limitation.

# Other dashboards that were already correct:
# -------------------------------------------
# - inst/shiny/dashboard_dynamic/app.R (already uses 70%)
# - inst/shiny/dashboard_async/app.R (already uses 70%)

print("Walker limit fixes completed for issues #190 and #191")
print("All dashboards now consistently use 70% of grid pixels as maximum walker limit")
print("For 400x400 grid: maximum 112,000 walkers supported")