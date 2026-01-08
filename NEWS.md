# randomwalk (development version)

## Changes

* Archived `dynamic_broadcasting.qmd` vignette - consolidated into `dashboard_comprehensive.qmd` which has all the same features plus better organization.

* Simplified `dashboard_comprehensive.qmd` - moved documentation into Notes tab, removed redundant sections.

* Updated telemetry vignette to handle missing coverage data gracefully.

# randomwalk 2.1.0

## Breaking Changes

* `sync_mode = "dynamic"` and `sync_mode = "mirai_dynamic"` are now **DEPRECATED**. These modes silently fall back to static behavior because nanonext sockets cannot be created inside crew/mirai subprocesses (NNG fork boundary limitation). Use `sync_mode = "chunked"` instead for best collision detection (~15%).

* Removed unused `duckdb` dependency from DESCRIPTION and all Nix files.

## New Features

* Added `sync_mode = "chunked"` - processes walkers in batches of 10 with grid updates between batches. This is now the **recommended mode** for parallel simulations with collision detection.

* New `shell.nix` for end users - uses `builtins.fetchGit` to install randomwalk directly from GitHub without requiring sha256 hashes.

* Added R-universe badge to README for package availability status.

## Bug Fixes

* Fixed `plot_grid()` collision count display - now correctly checks `collisions_detected` field used by async modes, with fallback to multiple termination reason key names.

* Fixed S3 `plot()` method signature to use `x` and `...` to match the generic.

* Fixed validation to properly respect `boundary` parameter using `match.arg()`.

* Fixed chunked mode to use numeric `1` instead of string for black pixels.

## Documentation

* Updated README sync_mode table with deprecation warnings for dynamic modes.

* Updated `dynamic_broadcasting_algorithm.md` with explanation of why the socket-based approach failed.

* Updated pkgdown home page title and navigation labels.

* Fixed R-CMD-check badge URL (lowercase filename).

# randomwalk 2.0.0

## Major Changes

* Complete rewrite with async parallel processing support via crew backend.

* Added comprehensive statistics tracking with percentiles and formatting.

* Added S3 plot methods - `plot(result)` works directly.

* Added WebR/browser support via Shinylive dashboards.

* Added multiple sync modes: `static`, `chunked`, `dynamic`, `mirai_dynamic`.

## New Features

* `run_simulation()` - main entry point with full parameter control.

* `plot_grid()` - visualize final grid state with statistics.

* `plot_walker_paths()` - visualize walker trajectories.

* `run_dashboard()` - launch interactive Shiny dashboard (native R only).

* `format_statistics()` - format simulation results for display.

## Documentation

* Added comprehensive vignettes: defensive programming, step distribution analysis, telemetry.

* Added browser-based Shinylive dashboards for interactive demos.

* Added pkgdown site at https://johngavin.github.io/randomwalk/

# randomwalk 1.0.0

* Initial release with basic random walk simulation.
