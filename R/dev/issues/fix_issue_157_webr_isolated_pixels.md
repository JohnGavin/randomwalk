# WebR Isolated Pixels Analysis - Issue #157

## Summary

Dashboard_comprehensive.html shows isolated pixels in WebR/browser environment, despite using identical code to dynamic_broadcasting.html and native R showing NO isolated pixels.

## Key Findings

### 1. Code Comparison
- **dashboard_comprehensive.qmd** and **dynamic_broadcasting.qmd** use IDENTICAL simulation code
- Both call `run_simulation()` with same parameters
- Both use `sync_mode = "static"`
- Both use `plot_grid()` for rendering

### 2. Native R Testing Results  
From debug logs (`/tmp/randomwalk_run.log`, `/tmp/randomwalk_worker_debug_*.txt`):
- 300 walkers with 6 workers
- 27 black_neighbor terminations  
- Final grid: **5 connected pixels** (center + 4 neighbors in 4-hood)
- **NO isolated pixels**
- All terminations at 4 valid positions: (49,50), (50,49), (50,51), (51,50)
- `validate_termination_position()` working correctly

### 3. Issue #63 Background
Previous isolated pixels bug was fixed by adding `validate_termination_position()`:
- Checks if position has at least one black neighbor before allowing termination
- Prevents isolated pixels caused by stale worker caches in async mode
- Fix confirmed working in native R

### 4. Root Cause Hypothesis
Since identical code produces different results in WebR vs native R:

**Likely Causes:**
1. **Shiny Reactive Timing**: `sim_result()` reactive value might be read before grid fully updated
2. **WebR Event Loop**: Browser async execution different from native R  
3. **Plot Rendering Race**: `renderPlot()` executes before grid state synchronized
4. **mirai/WebR Integration**: Worker state management differs in WebAssembly environment

**Less Likely:**
- Code differences (ruled out - files identical)
- Validation logic (works in native R)
- Core simulation algorithm (produces correct results natively)

## Recommended Fixes

### Fix 1: Add Defensive Validation to Shiny Plot Rendering

Add to `dashboard_comprehensive.qmd` (line 327):

```r
output$fractal_plot <- renderPlot({
  req(sim_result())
  result <- sim_result()
  
  # Defensive checks for WebR environment
  req(!is.null(result$grid))
  req(nrow(result$grid) > 0)
  req(sum(result$grid == 1) > 0)  # Ensure has black pixels
  
  # CRITICAL: Validate grid connectivity before plotting
  # This catches any isolated pixels that slip through
  isolated <- randomwalk:::find_isolated_pixels(result$grid, "4-hood")
  
  if (length(isolated) > 0) {
    logger::log_warn("WebR: Found {length(isolated)} isolated pixels in grid!")
    # Still plot but add warning to title
    plot_grid(
      result, 
      main = paste0("WARNING: ", length(isolated), " isolated pixels detected")
    )
  } else {
    plot_grid(result, main = "Fractal Pattern - Black Pixels on Grid")
  }
})
```

### Fix 2: Force Reactive Value Synchronization

Add to `dashboard_comprehensive.qmd` after simulation (line 296):

```r
sim_result(result)

# Force immediate reactive value update (WebR compatibility)
isolate({
  temp <- sim_result()
  req(!is.null(temp))
})
```

### Fix 3: Add Grid Validation Helper

Export `find_isolated_pixels()` from package (currently in `R/setup/fix_issue_63_isolated_pixels.R:131-161`):

```r
#' Find Isolated Pixels in Grid
#'
#' @param grid Numeric matrix representing grid state
#' @param neighborhood "4-hood" or "8-hood"
#' @return List of isolated pixel positions
#' @export
find_isolated_pixels <- function(grid, neighborhood = "4-hood") {
  black_positions <- which(grid == 1, arr.ind = TRUE)
  
  if (nrow(black_positions) <= 1) {
    return(list())
  }
  
  isolated <- list()
  n <- nrow(grid)
  
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
```

### Fix 4: Add Browser Console Logging

Add to `dashboard_comprehensive.qmd` to help diagnose WebR-specific issues:

```r
# After simulation completes (line 296)
sim_result(result)

# Log to browser console for debugging
message(sprintf("Simulation complete: %d black pixels", sum(result$grid == 1)))
isolated_check <- find_isolated_pixels(result$grid, "4-hood")
if (length(isolated_check) > 0) {
  message(sprintf("WARNING: Found %d isolated pixels!", length(isolated_check)))
  message("Isolated positions:", paste(sapply(isolated_check, 
    function(p) sprintf("(%d,%d)", p[1], p[2])), collapse=", "))
}
```

## Testing Protocol

1. **Test Both Dashboards in Browser:**
   - https://johngavin.github.io/randomwalk/articles/dashboard_comprehensive.html
   - https://johngavin.github.io/randomwalk/articles/dynamic_broadcasting.html
   - Run multiple simulations with default parameters (200 walkers, workers=0)
   - Check browser console (F12) for warnings

2. **Look For:**
   - Grid plots showing disconnected black pixels
   - Console messages about isolated pixels
   - Different results between the two dashboards

3. **Expected Results:**
   - If BOTH show isolated pixels: WebR mirai integration issue
   - If ONLY dashboard_comprehensive shows isolated pixels: Shiny reactive complexity issue
   - If NEITHER shows isolated pixels: User report may be stale (issue already fixed)

## Next Steps

1. ✅ GitHub issue #157 created documenting the problem
2. ⏳ Test both dashboards in browser to confirm issue
3. ⏳ Apply Fix 1 (defensive validation) to dashboard_comprehensive.qmd
4. ⏳ Export `find_isolated_pixels()` as public function
5. ⏳ Add browser console logging for diagnostics
6. ⏳ Re-test after fixes applied
7. ⏳ Update issue #157 with findings and resolution

## Implementation Plan

### Phase 1: Diagnostic (No Code Changes)
1. Test dashboard_comprehensive.html in browser
2. Test dynamic_broadcasting.html in browser  
3. Check browser console for errors
4. Take screenshots of any isolated pixels
5. Document exact reproduction steps

### Phase 2: Apply Fixes
1. Add `find_isolated_pixels()` to R/grid.R and export
2. Update dashboard_comprehensive.qmd with defensive validation
3. Add browser console logging
4. Rebuild site: `quarto render`
5. Test locally before deploying

### Phase 3: Verify
1. Test fixed dashboard in browser
2. Run multiple simulations (different parameters)
3. Confirm no isolated pixels appear
4. Update issue #157 with resolution

## Conclusion

The isolated pixels issue is WebR-specific, not a core algorithm bug:
- Native R produces correct results (validated with debug logs)
- Issue #63 fix (`validate_termination_position()`) works correctly
- Problem likely reactive value timing or WebR event loop differences
- Defensive validation and better logging will help diagnose and prevent
