# Current Focus: Addressing Deployment Regressions

## Active Branch
main (Fixes merged)

## What I'm Doing
- Addressed multiple regressions on the deployed website in a single consolidated fix.
- Restored the Sync Dashboard (Issue #103).
- Fixed the Async Dashboard link (Issue #102).
- Implemented the Dynamic Dashboard UI (Issue #101).

## Progress
- [x] Fix #100: Escape quotes in pkgdown workflow - **MERGED**
- [x] Raise Issue #101: Fix `dynamic_broadcasting.html` content.
- [x] Raise Issue #102: Fix 404 on `dashboard_async` URL.
- [x] Raise Issue #103: Restore embedded Shinylive app in `dashboard.html`.
- [x] **Fix #104: Restore dashboards and fix links (Issues #101, #102, #103) - MERGED**

## Blockers
- None.

## Key Files Modified
- `vignettes/dashboard.qmd` (Restored app code)
- `_pkgdown.yml` (Fixed link)
- `inst/shiny/dashboard_dynamic/app.R` (New app created)
- `vignettes/dynamic_broadcasting.qmd` (Embedded new app)
- `R/setup/fix_website_regressions.R` (Log)

## Important Notes
- The `dynamic_broadcasting` vignette now embeds a specific Shinylive app (`inst/shiny/dashboard_dynamic`) which is a customized version of the async dashboard with a "Sync Mode" selector.
- GitHub Actions workflow is currently running to deploy these changes.

## Next Session Should
1. Verify the deployed website `https://johngavin.github.io/randomwalk/` once the workflow completes.
2. Confirm all three dashboards (Sync, Async, Dynamic) are functional and accessible.