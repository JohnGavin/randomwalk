# Random Walk Package Development Workflow

**Last Updated**: 2025-11-25
**Nix Environment**: `/Users/johngavin/docs_gh/rix.setup/default.nix`

## TL;DR - Quick Reference

**Inside running R session** (most common):
```r
devtools::load_all(".")  # ← Use this 99% of the time!
```

**For major changes** (NAMESPACE/DESCRIPTION):
```r
detach("package:randomwalk", unload = TRUE)
devtools::install()
library(randomwalk)
```

**From command line**:
```bash
R -e 'devtools::load_all("."); simulate_walk(steps = 100)'
```

---

## Table of Contents

1. [Critical Setup](#critical-setup)
2. [The 8-Step Mandatory Workflow](#the-8-step-mandatory-workflow)
3. [Fast Iteration with devtools::load_all()](#fast-iteration-with-devtoolsload_all)
4. [Complete Development Cycle](#complete-development-cycle)
5. [Scenario-Specific Guides](#scenario-specific-guides)
6. [Troubleshooting](#troubleshooting)
7. [Best Practices](#best-practices)
8. [Key Commands Reference](#key-commands-reference)

---

## Critical Setup

### ⚠️ MANDATORY: Always Use Nix Environment

**ALL development MUST happen inside the persistent nix shell:**

```bash
# Start the nix environment
caffeinate -i ~/docs_gh/rix.setup/default.sh
```

**Inside the nix shell, verify environment:**
```r
# Check you're in the right place
getwd()  # Should be: /Users/johngavin/docs_gh/claude_rix/random_walk

# Verify randomwalk can be loaded
library(devtools)
library(testthat)
```

### Why Nix Environment is Critical

The nix shell loads the randomwalk package from **GitHub** (frozen commit), not your local working directory!

```r
# This loads the GITHUB version (frozen commit):
library(randomwalk)

# This loads your LOCAL working directory:
devtools::load_all(".")
```

**They are different packages!**

---

## The 8-Step Mandatory Workflow

**⚠️ NO EXCEPTIONS. NO SHORTCUTS. ALL CHANGES MUST FOLLOW THIS WORKFLOW ⚠️**

### Step 1: Create GitHub Issue First

```r
# Use gh R package (NOT gh CLI)
gh::gh(
  'POST /repos/JohnGavin/randomwalk/issues',
  title = "Fix: Description of the bug/feature",
  body = "Detailed explanation of what needs to be done and why."
)
```

Get the issue number (e.g., #123)

### Step 2: Create Development Branch

```r
# NEVER commit directly to main
usethis::pr_init("fix-issue-123-short-description")
```

### Step 3: Make Changes on Dev Branch

```r
# Edit code in R/ directory
# Example: Edit R/simulate_walk.R

# Load changes immediately
devtools::load_all(".")

# Test interactively
result <- simulate_walk(steps = 100, walkers = 5)
plot(result)
```

### Step 4: Log All Commands

Create/update file in `R/setup/` to log every R command:

```r
# R/setup/fix_issue_123.R

# Load libraries
library(devtools)
library(gert)

# Make changes
# ... (your edits) ...

# Reload and test
load_all(".")
result <- simulate_walk(steps = 100)

# Stage and commit
gert::git_add(c("R/simulate_walk.R", "R/setup/fix_issue_123.R"))
gert::git_commit("Fix: Issue #123 - description of fix")
```

### Step 5: Run All Checks Locally

```r
# Update documentation
devtools::document()

# Run tests
devtools::test()

# R CMD check (must pass with 0 errors/warnings/notes)
devtools::check()

# Build pkgdown site
pkgdown::build_site()
```

**Fix ALL errors, warnings, notes before proceeding!**

### Step 6: Push via PR (Triggers GitHub Actions)

```r
# Push to remote and create PR
usethis::pr_push()
```

This will:
- Push your branch to GitHub
- Create a Pull Request
- Trigger all GitHub Actions workflows

### Step 7: Wait for GitHub Actions

Monitor workflows (all must pass ✅):
- R-tests-via-nix
- nix-builder
- pkgdown

```r
# Check workflow status
gh::gh('GET /repos/JohnGavin/randomwalk/actions/runs',
       .limit = 5)
```

### Step 8: Merge via PR

```r
# Merge PR to main
usethis::pr_merge_main()

# Clean up branch
usethis::pr_finish()
```

This will:
- Merge the PR
- Close the associated issue
- Delete the development branch

---

## Fast Iteration with devtools::load_all()

### Method 1: devtools::load_all() (FASTEST ⚡)

**Use this 99% of the time during development!**

```r
# In running R session
devtools::load_all(".")

# Test your changes immediately
result <- simulate_walk(steps = 100, walkers = 5)
walker_stats(result)
```

**What it does**:
- ✅ Sources all R files in `R/`
- ✅ Recompiles any C/C++ code
- ✅ Updates function definitions in memory
- ✅ Keeps R session running (no restart)
- ✅ FAST (seconds, not minutes)
- ❌ Doesn't update NAMESPACE or installed package

**When to use**:
- After editing any R file in `R/`
- After changing function code
- During iterative testing
- 99% of development time!

### Method 2: Full Reinstall (THOROUGH 🔄)

**Use when you need a clean slate**:

```r
# Unload current version
detach("package:randomwalk", unload = TRUE)

# Reinstall from current directory
devtools::install()

# Load fresh installation
library(randomwalk)
```

**When to use**:
- Changed `DESCRIPTION` file
- Changed `NAMESPACE` file
- Added/removed exported functions
- Something feels broken
- Before running R CMD check

---

## Complete Development Cycle

### Typical Day's Work

```r
# === SETUP (Once per session) ===
library(devtools)
library(testthat)
setwd("/Users/johngavin/docs_gh/claude_rix/random_walk")

# === ITERATE (Repeat many times) ===
# 1. Edit R/simulate_walk.R (or any R file)

# 2. Reload code (FAST!)
load_all(".")

# 3. Test interactively
grid <- create_grid(size = 10)
result <- simulate_walk(grid = grid, steps = 100, walkers = 5)
plot_walks(result)

# 4. If it works, repeat from step 1
# If it fails, fix and repeat from step 2

# === QUALITY CHECKS (Before committing) ===
# 5. Run tests
test()

# 6. Update documentation (if changed roxygen)
document()

# 7. Full package check
check()

# 8. Build site (if changed vignettes)
pkgdown::build_site()

# === COMMIT ===
# Now commit your changes using gert
gert::git_add(".")
gert::git_commit("Feature: description of changes")
```

### Recommended Iteration Ratio

- `load_all()`: 100 times ⚡
- `test()`: 10 times 🧪
- `document()`: 5 times 📝
- `check()`: 1-2 times ✅
- `install()`: Almost never 🚫

---

## Scenario-Specific Guides

### Scenario 1: Editing Function Code

```r
# 1. Open R/simulate_walk.R in editor
# 2. Make changes
# 3. In R:
devtools::load_all(".")

# 4. Test
result <- simulate_walk(steps = 100, walkers = 5)

# 5. Repeat until working
```

### Scenario 2: Adding New Function

```r
# 1. Create new function file
usethis::use_r("new_analysis")
# Edit R/new_analysis.R with roxygen comments

# 2. Load and test
devtools::load_all(".")
new_analysis(data)

# 3. Create test file
usethis::use_test("new_analysis")
# Edit tests/testthat/test-new_analysis.R

# 4. Run tests
devtools::test()

# 5. Update docs
devtools::document()

# 6. Full check before committing
devtools::check()
```

### Scenario 3: Testing Async Dashboard

```r
# 1. Edit inst/shiny/dashboard_async/app.R
# 2. Reload package code (if dashboard uses package functions)
devtools::load_all(".")

# 3. Launch dashboard
shiny::runApp("inst/shiny/dashboard_async")

# 4. Test in browser
# 5. Stop app, edit, repeat from step 2
```

### Scenario 4: Updating Vignettes

```r
# 1. Edit vignettes/introduction.Rmd
# 2. Reload package (if vignette uses package functions)
devtools::load_all(".")

# 3. Build single vignette
devtools::build_vignettes()

# 4. Or build entire site
pkgdown::build_site()

# 5. Preview in browser
browseURL("docs/articles/introduction.html")
```

### Scenario 5: Running Tests

```r
# Run all tests
devtools::test()

# Run specific test file
devtools::test_active_file("tests/testthat/test-simulate_walk.R")

# Run tests with coverage
covr::package_coverage()
covr::report()
```

### Scenario 6: Working with Targets Pipeline

```r
# 1. Edit _targets.R
# 2. Reload package
devtools::load_all(".")

# 3. Visualize pipeline
targets::tar_visnetwork()

# 4. Run pipeline (or specific targets)
targets::tar_make()
# Or: targets::tar_make(names = c("walks", "analysis"))

# 5. Load results
targets::tar_load(walks)
```

---

## Troubleshooting

### Problem: "Function not found" after load_all()

```r
# Solution 1: Clear namespace and retry
unloadNamespace("randomwalk")
devtools::load_all(".")

# Solution 2: Restart R
.rs.restartR()  # RStudio
# Or: quit() and restart manually

# Then reload
devtools::load_all(".")
```

### Problem: "Package is in use" error

```r
# Force detach
try(detach("package:randomwalk", unload = TRUE), silent = TRUE)
devtools::load_all(".")
```

### Problem: Changes not appearing

```r
# Check you're in the right directory
getwd()
# Should be: /Users/johngavin/docs_gh/claude_rix/random_walk

# Verify load_all is loading from current directory
devtools::load_all(".")
# Look for: "ℹ Loading randomwalk"

# If still not working, restart R
.rs.restartR()
```

### Problem: Nix shell using old version

```r
# The nix shell loads from GitHub, not local files
# Two solutions:

# Solution 1: Use devtools::load_all() during development
devtools::load_all(".")  # Always loads local code

# Solution 2: Update nix shell to use latest GitHub commit
# See NIX_PACKAGE_DEVELOPMENT.md in rix.setup folder
```

---

## Best Practices

### DO ✅

- Use `load_all()` for fast iteration
- Test frequently with interactive examples
- Run `test()` before committing
- Run `check()` before creating PR
- Document as you go (roxygen comments)
- Keep R session running during development
- Use version control for all changes
- Log all commands in `R/setup/` files
- Always work inside nix shell

### DON'T ❌

- Don't use `install()` for every change (too slow!)
- Don't skip `load_all()` and expect changes to appear
- Don't forget that nix shell uses GitHub version
- Don't edit NAMESPACE manually (use roxygen)
- Don't commit without running tests
- Don't push without running check
- Don't commit directly to main (always use branches)
- Don't use bash `git` commands (use gert R package)
- Don't use gh CLI (use gh R package)

### Optimal Workflow

```r
# Start of day:
library(devtools)
setwd("/Users/johngavin/docs_gh/claude_rix/random_walk")

# During development (repeat 100x):
# 1. Edit code
# 2. load_all(".")
# 3. Test interactively
# 4. Repeat

# Before lunch break:
test()  # Quick sanity check

# Before going home:
document()
test()
check()
# Commit if all pass
```

---

## Key Commands Reference

| Task | Command | Frequency | Speed |
|------|---------|-----------|-------|
| **Reload code** | `devtools::load_all(".")` | Every change | ⚡ Seconds |
| **Run tests** | `devtools::test()` | Before commit | 🧪 Fast |
| **Update docs** | `devtools::document()` | Changed roxygen | 📝 Fast |
| **Full check** | `devtools::check()` | Before PR | ✅ Slow |
| **Reinstall** | `devtools::install()` | Almost never | 🔄 Slow |
| **Build site** | `pkgdown::build_site()` | Changed vignettes | 🌐 Slow |
| **Launch dashboard** | `shiny::runApp("inst/shiny/dashboard_async")` | Testing UI | 🎨 Fast |
| **Run targets** | `targets::tar_make()` | Updated pipeline | 🎯 Variable |
| **View pipeline** | `targets::tar_visnetwork()` | Check dependencies | 👁️ Fast |

### Git/GitHub Commands (Use R Packages!)

| Task | R Command (✅ Use This) | Bash Command (❌ Don't Use) |
|------|------------------------|---------------------------|
| **Create issue** | `gh::gh('POST /repos/JohnGavin/randomwalk/issues', ...)` | `gh issue create` |
| **Create branch** | `usethis::pr_init("branch-name")` | `git checkout -b` |
| **Stage files** | `gert::git_add("file.R")` | `git add file.R` |
| **Commit** | `gert::git_commit("message")` | `git commit -m` |
| **Push** | `usethis::pr_push()` | `git push` |
| **Merge PR** | `usethis::pr_merge_main()` | `gh pr merge` |
| **Clean up** | `usethis::pr_finish()` | `git branch -d` |

---

## Integration with Targets Pipeline

The randomwalk package uses `targets` for reproducible pipelines:

```r
# View pipeline structure
targets::tar_visnetwork()

# Run entire pipeline
targets::tar_make()

# Run specific targets
targets::tar_make(names = c("walks", "analysis"))

# Load results in vignettes
targets::tar_load(walks)
targets::tar_read(walker_stats)

# Invalidate and rebuild specific targets
targets::tar_invalidate(walks)
targets::tar_make(names = "walks")
```

### Vignettes with Targets

Vignettes should primarily load pre-calculated objects:

```r
# In vignette .Rmd:
library(targets)
library(randomwalk)

# Load pre-calculated results
tar_load(walks)
tar_load(analysis)

# Display results
plot(walks)
summary(analysis)
```

**Don't run heavy computations in vignettes** - use targets to pre-calculate!

---

## References

- [devtools documentation](https://devtools.r-lib.org/)
- [R Packages book](https://r-pkgs.org/)
- [rix package](https://docs.ropensci.org/rix/)
- [targets package](https://docs.ropensci.org/targets/)
- Global context: `/Users/johngavin/docs_gh/claude_rix/context_claude.md`
- Nix setup: `/Users/johngavin/docs_gh/rix.setup/default.R`
- Nix package development: `/Users/johngavin/docs_gh/rix.setup/NIX_PACKAGE_DEVELOPMENT.md`

---

## Summary

**The Golden Rule**: Use `devtools::load_all(".")` for 99% of development.

**The workflow**:
1. Edit code
2. `load_all(".")`
3. Test interactively
4. Repeat

**Before committing**:
```r
devtools::test()
devtools::document()
devtools::check()
```

**Always work inside the nix shell for reproducibility!**

That's it! Fast, efficient, reproducible R package development for randomwalk.
