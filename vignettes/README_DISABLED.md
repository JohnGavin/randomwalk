# Disabled Vignettes

Three vignettes are temporarily disabled (renamed to `.qmd.disabled`):

- **dashboard.qmd.disabled** - Service Worker errors, requires Shinylive/webR update
- **dashboard_async.qmd.disabled** - Same Service Worker issues as dashboard
- **telemetry.qmd.disabled** - Missing target definitions in _targets.R pipeline

## Why Disabled?

See [Issue #132](https://github.com/JohnGavin/randomwalk/issues/132) for full details.

These vignettes had persistent errors despite rollback attempts:
- Service Worker registration failures in browser
- Still using old webR 4.4.1 instead of 4.5.1
- Missing pipeline targets (plot_pipeline_timing, etc.)

## Active Vignettes

- **dynamic_broadcasting.qmd** ✅ - Async parallel demo using WebR 4.5.1 + mirai

## Re-enabling

To re-enable a vignette:
1. Fix the underlying issues (see Issue #132)
2. Rename `.qmd.disabled` → `.qmd`
3. Uncomment the vignette in `_targets.R`
4. Uncomment the vignette in `_pkgdown.yml`
5. Update README.md
6. Run `targets::tar_make()` to build
7. Test locally before committing
