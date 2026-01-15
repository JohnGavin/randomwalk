# ==============================================================================
# Fix Issue #172: WebR dashboard simulation extremely slow (400 steps/sec)
# Date: 2026-01-15
# ==============================================================================
#
# Problem:
# - Browser-based simulations in WebR are extremely slow (~400 steps/sec)
# - Original defaults: 2000 walkers × 5000 steps = 10M potential steps
# - At 400 steps/sec = potentially 7+ hours for worst case!
#
# Root Cause:
# - WebR/WASM has inherent overhead compared to native R
# - Matrix operations and R loops are slower in WASM
# - No parallel processing available in browser
#
# Solution:
# 1. Reduced default parameters for WebR-friendly experience:
#    - Grid size: max 400 → 200, default 100 → 80
#    - Walkers: max 5000 → 1000, default 2000 → 200
#    - Max steps: max 10000 → 2000, default 5000 → 500
#
# 2. Added runtime estimate display:
#    - Shows estimated time based on 400 steps/sec
#    - Color-coded: green (<1min), orange (1-5min), red (>5min)
#    - Displays total steps calculation
#
# 3. Updated limitations section with recommendations:
#    - Explicit ~400 steps/sec performance note
#    - Recommended parameters for browser use
#    - Suggestion to use native R for larger simulations
#
# Files Modified:
# - vignettes/articles/dashboard_comprehensive.qmd
# - DESCRIPTION (version bump 2.1.0 → 2.1.1)
#
# Testing:
# - Default params (200 walkers × 500 steps = 100K steps)
# - At 400 steps/sec = ~4 minutes (reasonable for demo)
#
# Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
