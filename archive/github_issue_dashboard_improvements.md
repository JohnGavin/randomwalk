# GitHub Issue: Async Dashboard UI Improvements

**Title**: Improve async dashboard UI and parameter ranges

**Labels**: `enhancement`, `ui`, `dashboard`

**Body**:

## Overview

The async dashboard at https://johngavin.github.io/randomwalk/articles/dashboard_async/ is working well but needs several UI improvements and expanded parameter ranges.

## Issues to Fix

### 1. Raw Data Tab - End Y Column Empty

**Current**: End Y column shows no data
**Expected**: Should show the Y coordinate where each walker terminated
**Location**: Raw Data tab → walker data table

**Possible Cause**:
```r
End_Y = sapply(walkers, function(w) tail(w$path[[1]], 1)[2])
```
May need to access the path data structure differently.

### 2. Table Filtering - Move to Top

**Current**: DataTable filters appear below column headers
**Expected**: Move filters to top of table for better UX

**Implementation**: Update DataTable options in `renderDataTable()`:
```r
options = list(
  pageLength = 10,
  scrollX = TRUE,
  dom = 'ftip',  # Add 'f' for filter at top
  search = list(
    search = '',
    smart = TRUE,
    regex = FALSE,
    caseInsensitive = TRUE
  )
)
```

### 3. Factor Columns - Dropdown Filters

**Current**: Text filters for Active and Reason columns
**Expected**: Dropdown filters showing only available values

**Columns to update**:
- `Active`: Dropdown with ["Yes", "No"]
- `Reason`: Dropdown with termination reasons

**Implementation**: Use DataTables column filters or create custom selectInput filters above table

## Parameter Range Expansions

### 4. Grid Size - Increase Range

**Current**: min=5, max=50, step=1
**Proposed**:
```r
sliderInput("grid_size", "Grid Size:",
  min = 20,    # Increase minimum
  max = 400,   # Increase maximum
  value = 50,  # Update default
  step = 20    # Larger step size
)
```

**Rationale**: Enable testing larger simulations for performance benchmarking

### 5. Number of Workers - Increase Range

**Current**: min=0, max=4, step=1
**Proposed**:
```r
sliderInput("workers", "Number of Workers:",
  min = 1,     # Change from 0 to 1 (keep 0 for sync mode)
  max = 12,    # Increase maximum
  value = 4,   # Update default
  step = 1
)
```

**Note**: Keep 0 as option for sync mode comparison. Range becomes 0-12.

### 6. Number of Walkers - Dynamic Maximum

**Current**: min=1, max=20
**Proposed**:
```r
# Make max walkers reactive to grid size
observe({
  max_walkers <- floor(0.7 * input$grid_size^2)
  updateSliderInput(session, "n_walkers",
    min = 1,
    max = max_walkers,
    value = min(input$n_walkers, max_walkers)
  )
})

sliderInput("n_walkers", "Number of Walkers:",
  min = 1,
  max = 20,  # Initial max, will update dynamically
  value = 6,
  step = 1
)
```

**Rationale**: Maximum walkers should be 70% of grid pixels to avoid overcrowding

## Implementation Notes

### Files to Modify

- `inst/shiny/dashboard_async/app.R` - Main dashboard code
- Test changes locally before deploying
- Ensure validation still works with new ranges

### Testing Checklist

- [ ] End Y column displays correct termination coordinates
- [ ] Table filters work and are positioned at top
- [ ] Dropdown filters show correct values for Active and Reason
- [ ] Grid size slider works with new range (20-400, step 20)
- [ ] Workers slider works with new range (0-12)
- [ ] Walkers maximum updates dynamically based on grid size
- [ ] Validation prevents too many walkers (maintains 70% rule)
- [ ] Large simulations (e.g., 400x400 grid) complete successfully
- [ ] Performance metrics display correctly with 12 workers

## Expected Benefits

- ✅ Better data visibility (End Y column fixed)
- ✅ Improved UX (filters at top, dropdowns for factors)
- ✅ More flexible testing (larger grids, more workers)
- ✅ Dynamic constraints (walkers scale with grid size)
- ✅ Better performance testing (up to 12 workers)

## Priority

**Medium** - Dashboard is functional; these are UX/usability improvements

---

*Note: After implementing, update both sync and async dashboards if changes apply to both.*
