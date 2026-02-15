# Current Focus: Dashboard Improvements & CI Issues

## Active Branch
main

## Session Status: CI issues fixed (2026-02-15)

Latest changes pushed to main:
- Fixed fractal plot caption display
- Removed fake chunking simulation
- Verified walker path color stability
- **Fixed #187**: Changed test-plotting.R to use sync mode (workers=0)
- **Fixed #177**: Re-enabled R-universe workflow

---

## Current Open Issues (3 total)

### Enhancement Issues

### Enhancement Issues
3. **#68** - Support three dashboard versions (sync, async-pre-nanonext, async-nanonext)
   - Multi-version dashboard support
   - Medium-term enhancement

4. **#60** - Improve validation visibility and control in dashboard
   - Better validation feedback for users
   - Dashboard UX improvement

5. **#56** - Page for survival curve for number of steps to event
   - New visualization feature
   - Statistical analysis enhancement

---

## Recently Completed

### CI Fixes (2026-02-15)
- ✅ #187 - Fixed CI test failures: test-plotting.R now uses sync mode (workers=0)
  - Root cause: tests used async mode but crew/nanonext not installed in CI
  - Fix: Change workers=1 to workers=0 (plotting tests don't need async)
- ✅ #177 - Re-enabled R-universe test workflow

### Dashboard Fixes (2025-02-15)
- ✅ Fixed fractal plot caption (now displays below plot, not in footer)
- ✅ Removed fake chunking (was showing misleading 0-95% progress)
- ✅ Verified walker path color stability (all 23 tests passing)
- ✅ Pushed changes to GitHub

### Previously Closed Issues
- ✅ #118 - Shinylive App Not Running (CLOSED)
- ✅ #103 - Restore embedded Shinylive app (CLOSED)
- ✅ #102 - Fix 404 on dashboard_async URL (CLOSED)
- ✅ #92 - Fix cachix push strategy (CLOSED)
- ✅ #111 - Add R CMD check to CI (CLOSED)
- ✅ #115 - Rationalize open PRs (CLOSED)

---

## Next Session Priorities

### Medium-Term
1. **#68** - Plan three dashboard version support
2. **#60** - Design validation visibility improvements
3. **#56** - Implement survival curve visualization

---

## Key Files Modified Recently

### Dashboard
- `R/plot_grid_enhanced.R` - Caption now returned as attribute
- `vignettes/articles/dashboard_comprehensive.qmd` - Removed chunking, added caption display

### Test Suite
- `tests/testthat/test-plotting.R` - Changed workers=1 to workers=0 (fix #187)
- `R/dev/issues/test_walker_color_stability.R` - New color stability test

---

## Cachix Strategy (Reminder)

```
┌────────────────────────────────────────────────────┐
│ Cache Priority Order:                              │
├────────────────────────────────────────────────────┤
│ 1. rstats-on-nix (READ-ONLY)  - All R packages    │
│ 2. johngavin      (READ-WRITE) - ONLY randomwalk  │
└────────────────────────────────────────────────────┘
```

---

**Last Updated**: 2026-02-15
**Current Status**: CI issues fixed (#177, #187), all workflows running
**Next Action**: Monitor CI to confirm fix, then work on enhancement issues (#68, #60, #56)
