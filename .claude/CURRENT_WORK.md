# Current Focus: Dashboard Improvements & CI Issues

## Active Branch
main

## Session Status: Dashboard fixes committed (2025-02-15)

Latest changes pushed to main:
- Fixed fractal plot caption display
- Removed fake chunking simulation
- Verified walker path color stability

---

## Current Open Issues (5 total)

### High Priority - CI Issues
1. **#187** - BUG: Tests fail in Code Coverage CI environment
   - Coverage generation fails due to test failures in CI
   - Needs investigation of test environment differences

2. **#177** - CI: Re-enable R-universe test workflow when quota allows
   - R-universe workflow disabled due to quota limits
   - Monitor and re-enable when quota resets

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

### Quick Wins
1. **#177** - Check R-universe quota status and re-enable if possible

### Investigation Needed
2. **#187** - Debug CI test failures in coverage workflow
   - Compare local vs CI test environments
   - Check for environment-specific issues

### Medium-Term
3. **#68** - Plan three dashboard version support
4. **#60** - Design validation visibility improvements
5. **#56** - Implement survival curve visualization

---

## Key Files Modified Recently

### Dashboard
- `R/plot_grid_enhanced.R` - Caption now returned as attribute
- `vignettes/articles/dashboard_comprehensive.qmd` - Removed chunking, added caption display

### Test Suite
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

**Last Updated**: 2025-02-15
**Current Status**: Dashboard fixes committed, CI issues need investigation
**Next Action**: Investigate #187 (CI test failures) or check #177 (R-universe quota)
