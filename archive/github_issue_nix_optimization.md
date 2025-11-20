# GitHub Issue: Optimize Nix Environment for CI/CD Workflows

**Title**: Create minimal default.nix for CI/CD to improve workflow performance

**Labels**: `performance`, `ci-cd`, `infrastructure`

**Body**:

## Overview

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
   - Example tools:
     ```r
     # Find all library() calls
     library_calls <- grep("library\\(", readLines("R/*.R"), value = TRUE)

     # Find all namespace calls
     namespace_calls <- grep("::", readLines("R/*.R"), value = TRUE)
     ```

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
       r_ver = "latest",
       r_pkgs = c(
         # Only packages actually used in project
         "shiny", "ggplot2", "crew", "targets",
         # CI essentials
         "devtools", "testthat", "pkgdown", "shinylive",
         # Let Nix handle dependencies
       ),
       ide = "other",
       project_path = ".",
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
   - run: nix-shell default.nix --run "..."
   ```

   To:
   ```yaml
   - uses: cachix/install-nix-action@v20
   - run: nix-shell default-ci.nix --run "..."
   ```

5. **Keep Development Environment**
   - Keep current `default.nix` for local MacBook development
   - Rename to `default-dev.nix` if needed for clarity
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

## Related Files

- `default.nix` - Current bloated environment
- `.github/workflows/pkgdown.yaml` - Workflow to update
- `.github/workflows/nix-builder.yaml` - Workflow to update
- `.github/workflows/R-tests-via-nix.yaml` - Workflow to update

## References

- [rix package documentation](https://github.com/ropensci/rix)
- [Cachix rstats-on-nix cache](https://app.cachix.org/cache/rstats-on-nix)
- [GitHub Actions optimization guide](https://docs.github.com/en/actions/using-workflows/caching-dependencies-to-speed-up-workflows)

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

---

*Note: Keep `default.nix` for local development. This issue is about creating a separate, minimal environment specifically for CI/CD.*
