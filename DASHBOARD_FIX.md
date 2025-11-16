# Dashboard Fix - November 16, 2024

## Problem

The dashboard at https://johngavin.github.io/randomwalk/articles/dashboard.html was displaying only a blank black page with no visible text or Shiny app widgets.

## Root Cause

The Shinylive dashboard app in `inst/shiny/dashboard/app.R` was missing the package loading mechanism needed to load the `randomwalk` package in the browser via WebAssembly.

When the dashboard runs in WebAssembly:
1. Browser loads the Shinylive HTML/JS
2. WebR initializes in the browser
3. App tries to load `library(randomwalk)`
4. **FAILS** because the package isn't available in the browser environment
5. Blank page displayed (JavaScript error in browser console)

## Correct Solution: Load from GitHub Release

The project already has a `.github/workflows/wasm-release.yaml` workflow that:
1. Builds a WebAssembly file system image containing the randomwalk package
2. Attaches this as `library.data` (and related files) to GitHub releases

The dashboard should **mount this file system directly from GitHub**, not use R-Universe.

### Why NOT R-Universe?

While R-Universe provides WebAssembly packages, this project already builds its own WebAssembly files via `wasm-release.yaml`. Using the GitHub-hosted files is:
- ✅ Simpler - files are already being built
- ✅ Faster - no intermediary service needed
- ✅ More direct - GitHub release → Browser
- ✅ Version-controlled - tied to specific releases

### Files Modified

#### 1. inst/shiny/dashboard/app.R

**Correct approach:**
```r
# Mount WebAssembly file system from GitHub release
# The wasm-release.yaml workflow builds library.data and attaches to releases
webr::mount(
  mountpoint = "/randomwalk-lib",
  source = "https://github.com/JohnGavin/randomwalk/releases/latest/download/library.data"
)

# Add mounted library to library paths
.libPaths(c("/randomwalk-lib", .libPaths()))

# Load required packages
library(shiny)

# Load randomwalk from mounted library
library(randomwalk)
```

#### 2. vignettes/dashboard.qmd

Same approach applied to the Quarto vignette version.

## How It Works Now

### Deployment Flow

```
1. Code push to GitHub
   ↓
2. wasm-release.yaml workflow (on release publish)
   ↓
3. Builds WebAssembly file system image with randomwalk package
   ↓
4. Attaches library.data to GitHub release as asset
   ↓
5. pkgdown.yaml workflow
   ↓
6. shinylive::export() converts app.R to HTML/JS
   ↓
7. Static HTML/JS deployed to GitHub Pages
   ↓
8. User's Browser loads dashboard from GitHub Pages
   ↓
9. Dashboard executes: webr::mount() to load library.data from GitHub release
   ↓
10. Browser downloads and mounts WebAssembly file system
   ↓
11. Dashboard loads randomwalk package from mounted library ✓
```

### WebAssembly File System

The `r-wasm/actions` workflow creates a file system image that includes:
- The randomwalk package (compiled to WebAssembly)
- All package dependencies
- Package metadata and documentation

This is packaged as `library.data` and attached to the GitHub release.

## Testing After Fix

Once changes are pushed and workflows complete:

1. **First**: Publish a new release to trigger `wasm-release.yaml`
   - This builds fresh `library.data` with latest code

2. **Second**: Wait for `pkgdown.yaml` workflow to complete
   - This rebuilds dashboard using the fixed app.R

3. **Third**: Visit dashboard at: https://johngavin.github.io/randomwalk/articles/dashboard.html

4. **First load**: May take 10-30 seconds to download and mount library.data

5. Should see:
   - "Random Walk Simulation Dashboard" title
   - Sidebar with parameter controls
   - Main panel with tabs
   - "Run Simulation" button

## Browser Console

If issues persist, check browser console (F12):

**Should see:**
```
Mounting file system from GitHub release...
Loading randomwalk package...
Package randomwalk loaded successfully
```

**Errors to watch for:**
```
Failed to fetch library.data - check if release has the file
```

## GitHub Workflows

### wasm-release.yaml
Triggered on release publish:
```yaml
on:
  release:
    types: [ published ]

jobs:
  release-file-system-image:
    uses: r-wasm/actions/.github/workflows/release-file-system-image.yml@v2
```

Creates `library.data` and attaches to release.

### pkgdown.yaml
Triggered on push to main:
```r
shinylive::export(
  appdir = "inst/shiny/dashboard",
  destdir = "docs/articles/dashboard"
)
```

Converts app.R (which now has webr::mount()) to standalone HTML.

## Next Steps

1. Amend the previous commit with corrected approach:
   ```bash
   git add inst/shiny/dashboard/app.R vignettes/dashboard.qmd DASHBOARD_FIX.md
   git commit --amend -m "Fix dashboard blank page: load from GitHub release via webr::mount()

   - Add webr::mount() to inst/shiny/dashboard/app.R
   - Mount library.data from GitHub release (latest)
   - Load randomwalk package from mounted file system
   - Update vignettes/dashboard.qmd with same approach
   - Dashboard loads WebAssembly directly from GitHub (not R-Universe)

   The wasm-release.yaml workflow builds library.data on each release.
   Dashboard mounts this directly - no intermediary service needed.

   Fixes blank page issue at johngavin.github.io/randomwalk/articles/dashboard.html"
   ```

2. Push to GitHub:
   ```bash
   git push origin fix/shinylive-dashboard --force
   ```

3. **Publish a new release** to trigger wasm-release.yaml:
   - This is necessary to rebuild library.data with latest package code
   - Create release v0.1.1 or similar

4. Wait for both workflows to complete

5. Verify dashboard works

## Why This Approach?

### webr::mount() from GitHub Release

**Advantages:**
- Files already being built by existing workflow
- Direct download from GitHub (no middleman)
- Tied to specific releases (versioned)
- Full control over what's included

**Flow:**
```
GitHub source → wasm-release workflow → library.data on GitHub release → webr::mount() in browser
```

### Alternative: R-Universe (not used)

This would require:
- Separate R-Universe repository configuration
- Additional GitHub App installation
- Package uploaded to R-Universe
- R-Universe builds WebAssembly
- Browser downloads from R-Universe

More steps, more complexity, less direct control.

## Related Documentation

- **r-wasm actions**: https://github.com/r-wasm/actions
- **webR mounting**: https://docs.r-wasm.org/webr/latest/mounting.html
- **Shinylive docs**: https://posit-dev.github.io/r-shinylive/

## Summary

The fix uses `webr::mount()` to load the WebAssembly file system directly from GitHub releases, where it's already being built by the `wasm-release.yaml` workflow.

This is simpler and more direct than using R-Universe, leveraging the existing build infrastructure without adding external dependencies.
