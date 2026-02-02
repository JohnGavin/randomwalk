# Dashboard Issues to Fix and Clarifications
# Date: 2026-02-01
# Author: Claude

# Summary of Issues Found:
# ------------------------

# 1. TIMER REQUIREMENT UPDATED ✅
#    - Added to CLAUDE.md: ALL r-shinylive dashboards must use elapsed timers, not spinners
#    - Timer shows MM:SS format with states: Ready/Running/Completed/Error
#    - Updates every second using reactiveTimer(1000)

# 2. R VERSION CLARIFICATION:
#    - Nix config (default.nix): Uses R 4.5.2 with date "2025-11-03"
#    - Debug page shows: R.version.string (WebR's R 4.4.1)
#    - This is CORRECT: WebR bundle has R 4.4.1, not the Nix environment's 4.5.2
#    - The debug page shows the actual R version running IN THE BROWSER

# 3. DASHBOARD LIMITS ARE CORRECT IN SOURCE:
#    - Grid size: max = 400 ✅ (line 134 in dashboard_comprehensive.qmd)
#    - Max steps: max = 10000, default = 5000 ✅ (line 149)
#    - The issue is the DEPLOYED VERSION on GitHub Pages is outdated

# 4. WALKER PATHS CLARIFICATION:
#    termination_reason types in the code:
#    - "touched_black" - Walker lands directly ON a black pixel
#    - "black_neighbor" - Walker has black neighbor but NOT on black itself
#    - "hit_boundary" - Walker hits edge (terminate mode)
#    - "max_steps" - Walker exceeds step limit
#
#    In plotting.R, "End (black)" legend groups BOTH:
#    - Walkers that touched black (landed on black pixel)
#    - Walkers with black neighbors (terminated next to black)
#    These are visually identical in the plot (both marked with squares)

# ACTION NEEDED:
# -------------
# 1. Deploy updated dashboard to GitHub Pages (has old version with 200/2000 limits)
# 2. Consider splitting "End (black)" into two categories in legend:
#    - "End (touched black)" - actually landed on black
#    - "End (black neighbor)" - terminated next to black

# Files to Deploy:
# ----------------
# vignettes/articles/dashboard_comprehensive.html - needs GitHub Pages update
# The source .qmd is correct but the deployed HTML is outdated

print("Issues identified:")
print("1. Timer requirement added to CLAUDE.md ✅")
print("2. R version difference is EXPECTED (WebR 4.4.1 vs Nix 4.5.2)")
print("3. Dashboard limits ARE correct in source (400/10000)")
print("4. GitHub Pages has OLD version - needs deployment")
print("5. Walker paths: 'End (black)' groups both touched AND neighbor terminations")