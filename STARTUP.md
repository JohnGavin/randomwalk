# Detailed Implementation Plan: Fix Website Rebuild & Deployment

**Context:**
The deployed website (`https://johngavin.github.io/randomwalk/`) has several critical regressions despite recent fixes being merged.
1.  **Sync Dashboard** (`dashboard.html`): The embedded Shinylive app is missing.
2.  **Async Dashboard** (`dashboard_async.html`): The link works, but content might be outdated.
3.  **Dynamic Dashboard** (`dynamic_broadcasting.html`): Still shows placeholder documentation instead of the newly created app.

**Root Cause:**
The `pkgdown` GitHub Actions workflow *skips* `pkgdown::build_articles()` to save time (due to expensive vignettes). It relies on pre-built HTML files in `vignettes/` being committed to the repo. The recent fixes updated the source (`.qmd`) files but *failed to commit the re-rendered HTML artifacts*. Thus, the deployment copied the old, broken HTML files to the site.

**Objective:**
Re-render all dashboards locally to generate fresh HTML artifacts, commit them, and deploy.

---

## Phase 1: Local Setup & Rendering

1.  **Create Branch**: `fix-website-rebuild-v2`
    *   *Command*: `usethis::pr_init("fix-website-rebuild-v2")`

2.  **Configure Targets for Vignette Building**:
    *   **Action**: Modify `random_walk/_targets.R`.
    *   **Goal**: Ensure `dashboard.qmd`, `dashboard_async.qmd`, and `dynamic_broadcasting.qmd` are defined as targets using `tarchetypes::tar_quarto()`. This ensures reproducible builds and proper dependency management.
    *   **Critical**: Add `devtools::load_all()` at the top of `_targets.R` or within the target definition to ensure the `randomwalk` package functions are available to Quarto during rendering (since we cannot install to the read-only Nix store).

3.  **Run Targets Pipeline**:
    *   **Action**: Execute `targets::tar_make()` in the R console (Nix environment).
    *   **Expected Outcome**: This should successfully build:
        *   `vignettes/dashboard.html` (+ `dashboard_files/`)
        *   `vignettes/dashboard_async.html` (+ `dashboard_async_files/`)
        *   `vignettes/dynamic_broadcasting.html` (+ `dynamic_broadcasting_files/`)
    *   **Verification**: Manually verify these files exist and have recent timestamps.

## Phase 2: Local Verification (Mandatory 9-Step Workflow)

4.  **Document**: Run `devtools::document()` to ensure documentation is current.
5.  **Test**: Run `devtools::test()` to catch any regressions in package logic.
6.  **Check**: Run `devtools::check()` to ensure package integrity. Fix any Errors/Warnings/Notes.
7.  **Build Site Locally**: Run `pkgdown::build_site()` to simulate the full site build and verify links locally in `docs/`.

## Phase 3: Commit & Deploy

8.  **Commit Artifacts (The Missing Step)**:
    *   **Action**: Use `gert::git_add()` to stage:
        *   Updated `_targets.R`
        *   Updated `.qmd` files (if any tweaks needed)
        *   **CRITICAL**: The generated `.html` files in `vignettes/`
        *   **CRITICAL**: The generated `*_files/` directories in `vignettes/` (containing Shinylive assets)
    *   **Command**: `gert::git_commit("Fix: Re-render and commit all dashboard vignettes for deployment")`

9.  **Push to Cachix (Mandatory)**:
    *   **Action**: Run `../push_to_cachix.sh` from `random_walk/`.
    *   **Reason**: Populate the binary cache to speed up CI.

10. **Push to GitHub**:
    *   **Action**: `usethis::pr_push()`.
    *   **Result**: Creates PR.

11. **Merge**:
    *   **Action**: Monitor CI. Once passed, merge to `main`.

## Phase 4: Verification

12. **Live Site Check**: Verify `https://johngavin.github.io/randomwalk/` shows the correct apps on all three pages.
