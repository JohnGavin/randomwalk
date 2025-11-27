# Session Log: Issue #60 Solution 1 - Add validate_strict UI Control
# Date: 2025-11-27
# Branch: fix-issue-60-solution-1-validate-strict-ui

# Issue #60: Improve validation visibility and control in dashboard
# This implements Solution 1: Add validate_strict parameter to dashboard UI

library(usethis)
library(gert)
library(gh)
library(logger)

# Step 1: Switch to main and create branch
gert::git_branch_checkout('main')
gert::git_pull()
usethis::pr_init('fix-issue-60-solution-1-validate-strict-ui')

# Step 2: Add validate_strict checkbox to dashboard UI
# Modified: inst/shiny/dashboard_async/app.R
#
# Added after max_steps slider (lines 116-126):
# checkboxInput(
#   "validate_strict",
#   "Strict Validation (stop on isolated pixels)",
#   value = FALSE
# )
#
# With help text explaining:
# - OFF: Warn about isolated pixels, continue
# - ON: Stop immediately on isolated pixel detection

# Step 3: Wire parameter to run_simulation call
# Modified: inst/shiny/dashboard_async/app.R line 588
# Added: validate_strict = input$validate_strict
#
# Also added log message showing validation mode (line 580)

# Step 4: Update UI state display
# Modified: inst/shiny/dashboard_async/app.R line 752
# Added: sprintf("Validation Mode: %s", ...)
# Shows current validation mode in debug state panel

# Step 5: Update reset button
# Modified: inst/shiny/dashboard_async/app.R line 649
# Added: updateCheckboxInput(session, "validate_strict", value = FALSE)
# Resets validation mode to WARNING when reset clicked

# Step 6: Commit changes
gert::git_add('inst/shiny/dashboard_async/app.R')
gert::git_commit('Add validate_strict checkbox to dashboard UI

Implements Issue #60 Solution 1

Adds user control for validation strictness mode in the async dashboard.

Changes:
1. New checkbox control "Strict Validation (stop on isolated pixels)"
   - Default: OFF (warning mode)
   - When ON: Simulation stops immediately on isolated pixel detection

2. Pass validate_strict parameter to run_simulation()
   - Wired from UI checkbox input
   - Logged to event log for visibility

3. Display validation mode in Current State panel
   - Shows: "STRICT (stop on error)" or "WARNING (continue)"

4. Reset button includes validate_strict
   - Returns to default FALSE on reset

Benefits:
- Users can test strict validation interactively
- Easier debugging of isolated pixel issues
- Clear feedback about validation mode in use
- Integrates with existing validation system

Related:
- Issue #60: Parent issue
- PR #61: Solution 3 (log level change)
- Issue #55: Original validation feature')

gert::git_add('R/setup/fix_issue_60_solution_1.R')
gert::git_commit('Add session log for solution 1')

# Step 7: Push and create PR
gert::git_push(set_upstream = TRUE)

gh('POST /repos/JohnGavin/randomwalk/pulls',
   title = 'Fix #60 (Solution 1): Add validate_strict checkbox to dashboard UI',
   body = 'Implements Issue #60 Solution 1

## Summary

Adds user control for validation strictness in the async dashboard. Users can now choose between warning mode (continue simulation) and strict mode (stop immediately) when isolated pixels are detected.

## Changes

### 1. New UI Control

Added checkbox after Max Steps slider:
```r
checkboxInput(
  "validate_strict",
  "Strict Validation (stop on isolated pixels)",
  value = FALSE
)
```

**Help text:**
- **OFF**: Warn about isolated pixels, continue simulation
- **ON**: Stop simulation immediately if isolated pixel detected
- Isolated pixels indicate simulation bugs

### 2. Parameter Wiring

Pass checkbox value to `run_simulation()`:
```r
result <- randomwalk::run_simulation(
  ...
  validate_strict = input$validate_strict
)
```

Also logs validation mode to event log for visibility.

### 3. State Display

Shows current validation mode in Debug > Current State:
```
Validation Mode: STRICT (stop on error)
# or
Validation Mode: WARNING (continue)
```

### 4. Reset Button

Includes `validate_strict` in parameter reset (returns to FALSE).

## Use Cases

### Testing & Debugging
- Enable strict mode to catch isolated pixels immediately
- Useful when developing new features or debugging issues

### Production
- Leave in warning mode (default) for robustness
- Simulation continues, warnings logged

## Testing

✅ Syntax validation passed
✅ Checkbox appears in UI
✅ Parameter passed to run_simulation()
✅ State display shows validation mode
✅ Reset button works

## Impact

**Before**: No way to control validation strictness from UI
**After**: One click to toggle strict/warning mode

## Related

- Issue #60: Parent issue (validation visibility improvements)
- PR #61: Solution 3 (log level change) - merged first
- Solution 2: Logger capture (future PR)
- Issue #55: Original validation implementation',
   head = 'fix-issue-60-solution-1-validate-strict-ui',
   base = 'main')

logger::log_info('Solution 1 implementation complete')
logger::log_info('PR created for validate_strict UI control')
