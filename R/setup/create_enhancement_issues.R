# Create GitHub Issues for Dashboard Enhancements and Nix Optimization
# Date: 2025-11-20
# Purpose: Convert markdown enhancement lists into tracked GitHub issues

library(gh)

# Issue 1: Dashboard UI Improvements
# ----------------------------------
cat("Creating issue for dashboard UI improvements...\n")

issue1_body <- "## Overview

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
- `Active`: Dropdown with [\"Yes\", \"No\"]
- `Reason`: Dropdown with termination reasons

## Parameter Range Expansions

### 4. Grid Size - Increase Range

**Current**: min=5, max=50, step=1
**Proposed**:
```r
sliderInput(\"grid_size\", \"Grid Size:\",
  min = 20,    # Increase minimum
  max = 400,   # Increase maximum
  value = 50,  # Update default
  step = 20    # Larger step size
)
```

### 5. Number of Workers - Increase Range

**Current**: min=0, max=4, step=1
**Proposed**:
```r
sliderInput(\"workers\", \"Number of Workers:\",
  min = 0,     # Keep 0 for sync mode
  max = 12,    # Increase maximum
  value = 4,   # Update default
  step = 1
)
```

### 6. Number of Walkers - Dynamic Maximum

**Current**: min=1, max=20
**Proposed**: Make max walkers reactive to grid size (70% of grid pixels)

```r
observe({
  max_walkers <- floor(0.7 * input$grid_size^2)
  updateSliderInput(session, \"n_walkers\",
    min = 1,
    max = max_walkers,
    value = min(input$n_walkers, max_walkers)
  )
})
```

## Implementation Notes

### Files to Modify
- `inst/shiny/dashboard_async/app.R` - Main dashboard code

### Testing Checklist
- [ ] End Y column displays correct termination coordinates
- [ ] Table filters work and are positioned at top
- [ ] Dropdown filters show correct values for Active and Reason
- [ ] Grid size slider works with new range (20-400, step 20)
- [ ] Workers slider works with new range (0-12)
- [ ] Walkers maximum updates dynamically based on grid size
- [ ] Large simulations complete successfully
- [ ] Performance metrics display correctly with 12 workers

## Expected Benefits
- ✅ Better data visibility (End Y column fixed)
- ✅ Improved UX (filters at top, dropdowns for factors)
- ✅ More flexible testing (larger grids, more workers)
- ✅ Dynamic constraints (walkers scale with grid size)

## Priority
**Medium** - Dashboard is functional; these are UX/usability improvements"

issue1 <- gh::gh(
  "POST /repos/JohnGavin/randomwalk/issues",
  title = "Improve async dashboard UI and parameter ranges",
  body = issue1_body,
  labels = list("enhancement", "ui", "dashboard")
)

cat("✅ Created issue #", issue1$number, ": ", issue1$title, "\n", sep = "")
cat("   URL: ", issue1$html_url, "\n\n", sep = "")


# Issue 2: Nix Optimization
# --------------------------
cat("Creating issue for Nix optimization...\n")

issue2_body <- "## Overview

GitHub Actions workflows are taking 10-12 minutes to complete, significantly slowing down the development cycle. The root cause is that `.github/workflows/` use the same `default.nix` as the local development environment, which contains ~100+ R packages needed for MacBook development but not required for CI/CD.

## Current Performance Issue

**Observed**: Workflows taking 10-12 minutes each
**Expected**: Should be much faster with proper caching
**Root Cause**: Bloated nix environment with unnecessary development packages

## Proposed Solution

Create a minimal `default-ci.nix` file specifically for GitHub Actions workflows that includes only the packages actually used in this project.

### Implementation Steps

1. **Audit Package Usage**
   - Scan all R code for `library()` calls
   - Scan all R code for `::` namespace calls
   - Create comprehensive list of actually-used packages

2. **Create Minimal Package List**
   - Start with packages found in step 1
   - Let Nix resolve dependencies automatically
   - Include only essential categories:
     - Core package functionality (randomwalk dependencies)
     - Testing (testthat)
     - Documentation (roxygen2, pkgdown)
     - CI essentials (devtools, rcmdcheck)
     - Shinylive export (shinylive, shiny)

3. **Create `default-ci.nix`**
   - Use `rix::rix()` to generate minimal environment
   - Example structure:
     ```r
     rix::rix(
       r_ver = \"latest\",
       r_pkgs = c(
         # Only packages actually used in project
         \"shiny\", \"ggplot2\", \"crew\", \"targets\",
         # CI essentials
         \"devtools\", \"testthat\", \"pkgdown\", \"shinylive\",
         # Let Nix handle dependencies
       ),
       ide = \"other\",
       project_path = \".\",
       overwrite = TRUE,
       print = TRUE
     )
     ```

4. **Update Workflows**
   Update `.github/workflows/*.yaml` to use `default-ci.nix`:
   - `pkgdown.yaml`
   - `nix-builder.yaml`
   - `R-tests-via-nix.yaml`

   Change from:
   ```yaml
   - uses: cachix/install-nix-action@v20
   - run: nix-shell default.nix --run \"...\"
   ```

   To:
   ```yaml
   - uses: cachix/install-nix-action@v20
   - run: nix-shell default-ci.nix --run \"...\"
   ```

5. **Keep Development Environment**
   - Keep current `default.nix` for local MacBook development
   - Document which file is for which purpose in README

### Expected Benefits

- ✅ **Faster builds**: Smaller nix environment = faster initialization
- ✅ **Better caching**: Cachix will cache minimal set more efficiently
- ✅ **Quicker iterations**: Faster workflows = faster development cycle
- ✅ **Lower resource usage**: Less network bandwidth, less disk space
- ✅ **Clearer separation**: Explicit distinction between dev and CI environments

### Verification Steps

After implementing:

1. **Measure Performance**
   - Record workflow times before changes
   - Record workflow times after changes
   - Target: <5 minutes for most workflows

2. **Verify Completeness**
   - Ensure all workflows pass
   - Check that all required packages are available
   - Verify pkgdown site builds correctly
   - Confirm shinylive exports work

3. **Monitor Cachix**
   - Check that rstats-on-nix cache is being used
   - Verify subsequent runs are faster (using cached builds)

## Package Categories

### Currently in default.nix (~100+ packages)
- Development tools (only needed locally)
- Data analysis packages (only needed for vignettes)
- IDE support packages (only needed on MacBook)
- Experimental packages (only needed for exploration)

### Should be in default-ci.nix (~15-25 packages)
- Core dependencies: `shiny`, `ggplot2`, `crew`, `targets`
- Testing: `testthat`, `covr`
- Documentation: `roxygen2`, `pkgdown`, `knitr`, `rmarkdown`
- CI tools: `devtools`, `rcmdcheck`
- Deployment: `shinylive`
- Nix dependencies auto-resolved by Nix

## Success Criteria

- [ ] Created `default-ci.nix` with minimal package list
- [ ] Audited all package usage in project
- [ ] Updated all three workflows to use `default-ci.nix`
- [ ] All workflows pass with new environment
- [ ] Workflow execution time reduced by >50%
- [ ] Cachix properly caching minimal environment
- [ ] Documentation updated explaining dev vs CI environments

## Priority

**High** - Directly impacts development velocity and CI/CD costs

## References

- [rix package documentation](https://github.com/ropensci/rix)
- [Cachix rstats-on-nix cache](https://app.cachix.org/cache/rstats-on-nix)"

issue2 <- gh::gh(
  "POST /repos/JohnGavin/randomwalk/issues",
  title = "Optimize Nix environment for CI/CD workflows",
  body = issue2_body,
  labels = list("performance", "ci-cd", "infrastructure")
)

cat("✅ Created issue #", issue2$number, ": ", issue2$title, "\n", sep = "")
cat("   URL: ", issue2$html_url, "\n\n", sep = "")


# Summary
# -------
cat("\n=== SUMMARY ===\n\n")
cat("Created 2 GitHub issues:\n\n")
cat("1. Issue #", issue1$number, " - Dashboard UI Improvements\n", sep = "")
cat("   Priority: Medium\n")
cat("   Labels: enhancement, ui, dashboard\n")
cat("   URL: ", issue1$html_url, "\n\n", sep = "")

cat("2. Issue #", issue2$number, " - Nix Optimization\n", sep = "")
cat("   Priority: High\n")
cat("   Labels: performance, ci-cd, infrastructure\n")
cat("   URL: ", issue2$html_url, "\n\n", sep = "")

cat("Next steps:\n")
cat("- Archive github_issue_*.md files to archive/\n")
cat("- Decide which issue to work on first\n")
cat("- Follow 8-step workflow: pr_init() → changes → test → pr_push() → merge\n")
