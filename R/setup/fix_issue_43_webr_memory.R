# Fix for Issue #43: WebR Memory Allocation Error
# Date: 2025-11-26
# Issue: https://github.com/JohnGavin/randomwalk/issues/43

# Problem: Large simulations (grid=400, walkers=35,981) crash with:
# "ERROR in simulation: cannot allocate vector of size 1.2 Mb"
# Root cause: WebR browser memory limits (~1-2 GB) vs estimated ~5.7 GB needed

# Solution: Add memory validation BEFORE simulation starts to prevent
# users from wasting 35+ minutes on simulations that will fail

# Changes made to inst/shiny/dashboard_async/app.R:

# 1. Added memory estimate display in UI (before "Run Simulation" button)
#    - Shows estimated memory in MB
#    - Color-coded status: ✅ OK, ⚠️ Caution/High risk, ❌ Too high
#    - Displays WebR limit (~1 GB) as reference

# 2. Added memory validation in observeEvent(run_sim)
#    - Calculates path_mb + grid_mb + overhead_mb
#    - Blocks simulations > 1500 MB with error message
#    - Warns for simulations > 1000 MB
#    - Prevents 35-minute failed runs

# 3. Updated About tab with WebR memory documentation
#    - Explains browser memory limits
#    - Shows safe parameter table with examples
#    - Links to issue #43 for details
#    - Suggests local R/RStudio for large simulations

# Memory calculation formula:
# path_mb = (n_walkers * max_steps * 2 coords * 8 bytes) / (1024^2)
# grid_mb = (grid_size^2 * 8 bytes) / (1024^2)
# total_mb = path_mb + grid_mb + 50 (overhead)

# Safe limits:
# - < 700 MB: ✅ Safe
# - 700-1000 MB: ⚠️ Caution
# - 1000-1500 MB: ⚠️ High risk
# - > 1500 MB: ❌ Blocked

# Example memory estimates:
# grid=100, walkers=5,000, steps=10,000 → ~760 MB (Safe)
# grid=400, walkers=35,981, steps=10,000 → ~5,488 MB (Blocked)

# Testing:
# - Memory estimate updates reactively when sliders change
# - Validation blocks high-memory simulations before starting
# - Error messages are clear and actionable
# - About tab documents safe parameter ranges

# Expected user experience:
# Before: User sets grid=400, walkers=35,981 → waits 35 min → crash
# After: User sets grid=400, walkers=35,981 → immediate error + guidance

# Branch: fix-issue-43-webr-memory-limits
# Workflow: Following 8-step mandatory workflow from context_claude.md
# Next: devtools::check(), commit, push, create PR
