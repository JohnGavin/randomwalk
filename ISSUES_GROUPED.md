# Open Issues Grouped by Similarity
## Ordered by Difficulty (Hardest First, Easiest Last)

Last Updated: 2025-11-28

---

## GROUP 1: Advanced Features - Real-time State Broadcasting
**Difficulty: ⭐⭐⭐⭐⭐ VERY HARD**
**Estimated Effort: 2-3 days**

### Issues
- **#51**: Feature: Dynamic grid state broadcasting with nanonext/mirai

### Description
Implement real-time grid state synchronization for async workers using nanonext pub/sub or mirai. This is the most complex issue requiring deep knowledge of:
- nanonext socket programming
- Parallel communication patterns
- Race condition handling
- Memory management in distributed systems

### Why It's Hard
- Requires implementing pub/sub socket infrastructure
- Must handle serialization/deserialization efficiently
- Complex debugging (parallel processes)
- Performance critical (can't slow down simulation)
- Previous attempts had serialization issues with crew

### Prerequisites
- Understanding of nanonext/mirai architecture
- Proficiency with R parallel programming
- Experience debugging distributed systems

### Related Code
- `R/async_worker.R` - Worker functions (currently use static snapshots)
- `R/simulation.R:241-426` - Async simulation loop
- Archive files show previous nanonext implementation attempts

---

## GROUP 2: Documentation & Visualization - Advanced Vignettes
**Difficulty: ⭐⭐⭐⭐ HARD**
**Estimated Effort: 1-2 days**

### Issues
- **#50**: Vignette: Create targets pipeline example with nested parallelism
- **#48**: Wiki: Show fractal similarity between workers=0 (sync) and workers=1 (async)

### Description
Create comprehensive vignettes demonstrating advanced package features:
1. **#50**: Targets pipeline with nested parallelism (crew + future)
2. **#48**: Fractal analysis comparing sync/async modes

### Why It's Hard
- Requires deep understanding of targets + crew integration
- Need to design reproducible examples with nested parallelism
- Fractal analysis requires statistical/mathematical visualization
- Must explain complex concepts clearly
- Performance profiling and comparison needed

### Prerequisites
- Expertise with targets package
- Understanding of nested parallelism patterns
- Statistical visualization skills (fractal dimension analysis)
- Knowledge of simulation reproducibility

### Related Code
- `R/tar_plans/` - Targets plans
- `vignettes/telemetry.qmd` - Existing telemetry vignette as template
- `R/simulation.R` - Sync vs async implementations

### Implementation Notes
**#50 (Targets + Nested Parallelism)**
```r
# Example structure needed:
tar_plan(
  # Outer layer: Use crew for walker parallelism
  tar_target(
    simulation_results,
    run_simulation(workers = 4), # crew workers
    pattern = map(parameters)    # targets parallelism
  )
)
```

**#48 (Fractal Similarity)**
- Run identical grids with workers=0 vs workers=1
- Compute fractal dimension of final grid patterns
- Statistical tests for similarity
- Visualizations showing overlay comparisons

---

## GROUP 3: Dashboard Enhancements - Statistics & Monitoring
**Difficulty: ⭐⭐⭐ MEDIUM**
**Estimated Effort: 4-6 hours**

### Issues
- **#57**: Non-blocking event should display latest statistics as soon as computed
- **#56**: Page for survival curve for number of steps to event (end state)
- **#60**: Enhancement: Improve validation visibility and control in dashboard

### Description
Enhance dashboard with real-time statistics, survival analysis, and validation controls:
1. **#57**: Update stats display as walkers complete (non-blocking)
2. **#56**: Add survival curve visualization (Kaplan-Meier style)
3. **#60**: Add validation controls and visibility

### Why It's Medium Difficulty
- Requires Shiny reactive programming
- Need to handle async updates without blocking UI
- Statistical visualization (survival curves)
- UI/UX design decisions

### Prerequisites
- Shiny reactive programming knowledge
- Understanding of survival analysis
- Dashboard UI/UX skills
- WebR compatibility considerations

### Related Code
- `inst/shiny/dashboard_async/app.R` - Dashboard Shiny app
- `R/simulation.R:370-374` - Progress logging (every 5 completed walkers)
- `R/walker.R` - Walker statistics

### Implementation Notes

**#57 (Non-blocking Statistics)**
```r
# In dashboard, use observeEvent on progress
observeEvent(simulation_progress(), {
  # Update stats reactively as walkers complete
  output$current_stats <- renderText({
    sprintf("Completed: %d/%d, Black pixels: %d",
            n_completed, n_total, black_count)
  })
})
```

**#56 (Survival Curve)**
```r
# Kaplan-Meier style survival curve
library(ggplot2)
plot_survival_curve <- function(walkers) {
  steps_to_event <- sapply(walkers, function(w) w$steps)

  # Survival function: P(steps > t)
  ggplot(data.frame(steps = steps_to_event)) +
    stat_ecdf(aes(x = steps, y = 1 - after_stat(y))) +
    labs(title = "Survival Curve: Steps to Termination",
         x = "Steps", y = "P(Steps > t)")
}
```

**#60 (Validation Controls)**
- Add checkbox: "Enable strict validation" (validate_strict)
- Add slider: "Validation frequency %" (validate_percent)
- Display validation warnings in debug log tab
- See PRs #61 and #62 for proposed solutions

---

## GROUP 4: Bug Fixes - Critical Simulation Logic
**Difficulty: ⭐⭐ EASY-MEDIUM** *(Already Fixed - Just Needs Merge)*
**Estimated Effort: 0 hours (PR ready)**

### Issues
- **#63**: CRITICAL: Simulation produces isolated black pixels violating random walk rules

### Description
Async simulation creates isolated black pixels due to stale worker caches. This violates random walk rules where pixels should only appear in connected paths.

### Status
✅ **FIXED** - PR #64 ready to merge
- Root cause identified (stale worker snapshots)
- Fix implemented (validate_termination_position)
- All tests passing (44 passed, 1 skipped)

### Why It's Easy Now
- Complete root cause analysis done
- Fix implemented and tested
- Just needs PR merge + GitHub Actions verification

### Implementation
See PR #64: https://github.com/JohnGavin/randomwalk/pull/64

---

## GROUP 5: Configuration & Documentation - Simple Fixes
**Difficulty: ⭐ VERY EASY**
**Estimated Effort: 15-30 minutes**

### Issues
- **#44**: Bug: Broken vignette links on Articles index page

### Description
Dashboard links on the Articles index page return 404 errors. Root cause is inconsistent link format in `_pkgdown.yml`.

### Why It's Very Easy
- Root cause already identified (see issue #44 comments from 2025-11-27)
- Simple configuration fix in one file
- No code changes needed
- Quick to test and verify

### Fix Required
Update `_pkgdown.yml`:

```yaml
# BEFORE (broken - directory paths):
navbar:
  components:
    articles:
      text: Dashboards
      menu:
      - text: Interactive Dashboard
        href: articles/dashboard/        # ❌ 404
      - text: Async Dashboard
        href: articles/dashboard_async/  # ❌ 404

# AFTER (fixed - .html files):
navbar:
  components:
    articles:
      text: Dashboards
      menu:
      - text: Interactive Dashboard
        href: articles/dashboard.html        # ✅ Works
      - text: Async Dashboard
        href: articles/dashboard_async.html  # ✅ Works
```

### Testing After Fix
Verify these URLs work:
- https://johngavin.github.io/randomwalk/articles/dashboard.html
- https://johngavin.github.io/randomwalk/articles/dashboard_async.html
- https://johngavin.github.io/randomwalk/articles/telemetry.html

### Implementation Steps
1. Edit `_pkgdown.yml`
2. Commit to development branch
3. Push and verify GitHub Pages deployment
4. Close #44

---

## Summary by Difficulty

| Difficulty | Issues | Estimated Time | Priority |
|------------|--------|----------------|----------|
| ⭐⭐⭐⭐⭐ Very Hard | #51 | 2-3 days | Medium |
| ⭐⭐⭐⭐ Hard | #50, #48 | 1-2 days | Low |
| ⭐⭐⭐ Medium | #57, #56, #60 | 4-6 hours | High |
| ⭐⭐ Easy-Medium | #63 | 0 hours (PR ready) | **CRITICAL** |
| ⭐ Very Easy | #44 | 15-30 minutes | High |

## Recommended Order of Attack

1. **#63** (CRITICAL) - Merge PR #64 immediately ✅ *Already in progress*
2. **#44** (Very Easy) - Fix broken links, quick win 📝 *30 minutes*
3. **#57, #56, #60** (Medium) - Dashboard enhancements together 🎨 *Half day*
4. **#48** (Hard) - Fractal analysis vignette 📊 *1 day*
5. **#50** (Hard) - Targets nested parallelism vignette 📚 *1 day*
6. **#51** (Very Hard) - Real-time broadcasting (optional enhancement) 🚀 *2-3 days*

## Quick Wins (Do First)
1. Merge PR #64 for #63
2. Fix #44 (broken links)
3. Add #57 (real-time stats display)

These three can be completed in < 2 hours and provide immediate value.

## Long-term Enhancements (Optional)
- #51 (broadcasting) - Nice to have but not critical
- #48, #50 (vignettes) - Valuable for documentation but not urgent
