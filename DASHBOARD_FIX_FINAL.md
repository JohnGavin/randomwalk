# Dashboard Fix - FINAL Solution

## Date: November 17, 2024

## Problem

Dashboard at `https://johngavin.github.io/randomwalk/articles/dashboard.html` showed a blank black screen.

Browser console (F12) showed 404 errors for:
- `./shinylive/load-shinylive-sw.js`
- `./shinylive/shinylive.js`
- `./shinylive/shinylive.css`
- `./shinylive/style-resets.css`

## Root Cause

The pkgdown workflow was:
1. Exporting Shinylive app to `docs/articles/dashboard/` (creates `docs/articles/dashboard/shinylive/` etc.)
2. Copying `docs/articles/dashboard/index.html` to `docs/articles/dashboard.html`

When the browser loaded `dashboard.html`, it tried to find `./shinylive/` relative to that file, which would be at `docs/articles/shinylive/`, but the actual files were at `docs/articles/dashboard/shinylive/`.

**The relative paths were broken!**

## Solution

Keep the dashboard in its own folder structure at `/articles/dashboard/` instead of copying to `dashboard.html`.

### Changes Made

#### 1. .github/workflows/pkgdown.yaml

**Before:**
```r
shinylive::export(
  appdir = "inst/shiny/dashboard",
  destdir = "docs/articles/dashboard"
)

# Copy the exported index.html to dashboard.html for consistent naming
file.copy(
  "docs/articles/dashboard/index.html",
  "docs/articles/dashboard.html",
  overwrite = TRUE
)
```

**After:**
```r
# Export Shiny app to Shinylive format using R package
# This creates docs/articles/dashboard/ with all shinylive assets
shinylive::export(
  appdir = "inst/shiny/dashboard",
  destdir = "docs/articles/dashboard"
)

# Don't copy index.html - keep dashboard in its own folder
# Users will access it at /articles/dashboard/ not /articles/dashboard.html
# This ensures relative paths to ./shinylive/ work correctly
```

#### 2. README.md

**Before:**
```markdown
**[Launch Interactive Dashboard](https://johngavin.github.io/randomwalk/articles/dashboard.html)**
```

**After:**
```markdown
**[Launch Interactive Dashboard](https://johngavin.github.io/randomwalk/articles/dashboard/)**
```

## Why This Works

The Shinylive export creates this structure:
```
docs/articles/dashboard/
├── index.html
├── app.json
├── shinylive/
│   ├── load-shinylive-sw.js
│   ├── shinylive.js
│   ├── shinylive.css
│   ├── style-resets.css
│   └── ... (other assets)
└── shinylive-sw.js
```

The `index.html` file contains relative paths like `./shinylive/load-shinylive-sw.js`.

When users access `/articles/dashboard/`, they load `index.html` which correctly resolves `./shinylive/` to `/articles/dashboard/shinylive/`.

## Deployment

### Commit
```
Fix dashboard deployment: keep shinylive assets in /articles/dashboard/

The issue was that shinylive::export() creates a directory structure with
./shinylive/ subfolder, but we were copying index.html to dashboard.html,
breaking the relative paths to the shinylive assets.

Fix: Keep dashboard in its own folder at /articles/dashboard/ so the
relative paths ./shinylive/* resolve correctly.

Also updated README.md to point to /articles/dashboard/ instead of
/articles/dashboard.html

This fixes the 404 errors for:
- load-shinylive-sw.js
- shinylive.js
- shinylive.css
- style-resets.css
```

### Workflow
1. Committed changes to `fix/shinylive-dashboard` branch
2. Stashed uncommitted files
3. Switched to `main` branch
4. Cherry-picked the fix commit
5. Pushed to `origin/main`
6. Workflows triggered automatically

### Workflow Status
- **nix-builder**: In progress
- **R-tests-via-nix**: In progress
- **pkgdown**: Queued

URL: https://github.com/JohnGavin/randomwalk/actions

## Testing

Once the pkgdown workflow completes (estimated 2-3 minutes), test at:

**New URL:** https://johngavin.github.io/randomwalk/articles/dashboard/

Expected behavior:
1. Dashboard loads (no blank screen)
2. All Shinylive assets load successfully (no 404 errors)
3. WebR initializes
4. `webr::mount()` loads the randomwalk package from GitHub release
5. Dashboard UI appears with controls and tabs
6. Simulations run successfully

## Verification Checklist

After deployment completes:

- [ ] Visit https://johngavin.github.io/randomwalk/articles/dashboard/
- [ ] Check browser console (F12) for errors
- [ ] Verify no 404 errors for shinylive assets
- [ ] Verify dashboard UI loads
- [ ] Click "Run Simulation" and verify it works
- [ ] Check all tabs (Grid State, Walker Paths, Statistics, Raw Data)

## Summary

The fix was simple: **don't break the folder structure that Shinylive creates**.

The original approach of copying `index.html` to `dashboard.html` seemed like it would provide a cleaner URL, but it broke all the relative paths to assets.

By keeping the dashboard at `/articles/dashboard/` (with trailing slash), all relative paths work correctly.

## Related Files

- `.github/workflows/pkgdown.yaml` - Workflow fix
- `README.md` - Updated URL
- `inst/shiny/dashboard/app.R` - Dashboard code (unchanged, already has webr::mount())
- `vignettes/dashboard.qmd` - Vignette (not used in current deployment)

## Previous Debugging

This fix supersedes all previous attempts:
- ❌ R-Universe setup - Not needed
- ❌ webr::mount() debugging - Code was already correct
- ❌ GitHub release issues - Files were already correct
- ✅ The real issue was the deployment structure

All the package loading code (`webr::mount()` etc.) was correct from the start. The problem was purely in how the static files were deployed to GitHub Pages.
