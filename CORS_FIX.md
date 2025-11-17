# CORS Fix for Shinylive Dashboard

## Date: November 17, 2024

## Problem

After fixing the 404 errors for Shinylive assets, the dashboard still failed with CORS error:

```
Access to XMLHttpRequest at 'https://github.com/JohnGavin/randomwalk/releases/latest/download/library.js.metadata'
from origin 'https://johngavin.github.io' has been blocked by CORS policy:
No 'Access-Control-Allow-Origin' header is present on the requested resource.
```

## Root Cause

GitHub releases don't include CORS headers, so browsers block cross-origin requests from web pages trying to fetch release assets.

The dashboard code was trying to:
```r
webr::mount(
  mountpoint = "/randomwalk-lib",
  source = "https://github.com/JohnGavin/randomwalk/releases/latest/download/library.data"
)
```

This fails because:
- Dashboard is served from `johngavin.github.io` (origin 1)
- `library.data` is on `github.com` (origin 2)
- Different origins = CORS policy applies
- GitHub doesn't set `Access-Control-Allow-Origin` header
- Browser blocks the request

## Solution

Serve the WebAssembly files from the **same origin** as the dashboard.

### Changes

#### 1. .github/workflows/pkgdown.yaml

Added step to download wasm files from release and copy to docs folder:

```yaml
- name: Download WebAssembly library from latest release
  if: github.event_name != 'pull_request'
  run: |
    # Create directory for wasm files
    mkdir -p docs/wasm

    # Download library.data and library.js.metadata from latest release
    # These files will be served from the same origin as the dashboard
    # avoiding CORS issues
    gh release download --repo JohnGavin/randomwalk \
      --pattern "library.data" \
      --pattern "library.js.metadata" \
      --dir docs/wasm
  env:
    GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

#### 2. inst/shiny/dashboard/app.R

Changed source URL to relative path (same origin):

**Before:**
```r
webr::mount(
  mountpoint = "/randomwalk-lib",
  source = "https://github.com/JohnGavin/randomwalk/releases/latest/download/library.data"
)
```

**After:**
```r
webr::mount(
  mountpoint = "/randomwalk-lib",
  source = "/randomwalk/wasm/library.data"
)
```

## How It Works

1. **Build Phase** (wasm-release.yaml on release publish):
   - Builds WebAssembly file system image
   - Attaches `library.data` and `library.js.metadata` to GitHub release

2. **Deploy Phase** (pkgdown.yaml on push to main):
   - Downloads wasm files from latest release
   - Copies them to `docs/wasm/`
   - Exports Shinylive app to `docs/articles/dashboard/`
   - Deploys entire `docs/` folder to GitHub Pages

3. **Runtime** (in browser):
   - User visits `https://johngavin.github.io/randomwalk/articles/dashboard/`
   - Dashboard loads from `johngavin.github.io` (origin: johngavin.github.io)
   - `webr::mount()` requests `/randomwalk/wasm/library.data`
   - Browser resolves to `https://johngavin.github.io/randomwalk/wasm/library.data`
   - Same origin = no CORS check needed
   - Files load successfully ✓

## File Structure on GitHub Pages

```
johngavin.github.io/randomwalk/
├── index.html (package homepage)
├── articles/
│   └── dashboard/
│       ├── index.html (dashboard app)
│       ├── app.json
│       └── shinylive/ (CSS, JS assets)
└── wasm/
    ├── library.data (WebAssembly package binary)
    └── library.js.metadata (metadata file)
```

## Advantages of This Approach

✅ **No CORS issues** - Same origin for all resources
✅ **No external dependencies** - No R-Universe needed
✅ **Simple** - Just download and copy files
✅ **Reliable** - Uses existing GitHub infrastructure
✅ **Fast** - No cross-domain requests
✅ **Self-contained** - All assets on GitHub Pages

## Disadvantages Avoided

By NOT using R-Universe:
- ❌ No external account needed
- ❌ No waiting for R-Universe builds
- ❌ No monitoring two separate systems
- ❌ No additional configuration
- ❌ No dependency on third-party service

## Testing

Once workflows complete (~2-3 minutes), test at:

**Dashboard URL:** https://johngavin.github.io/randomwalk/articles/dashboard/

**Expected behavior:**
1. ✅ Dashboard loads (no blank screen)
2. ✅ Shinylive assets load (no 404 errors)
3. ✅ WebR initializes
4. ✅ No CORS errors in console
5. ✅ `webr::mount()` succeeds
6. ✅ `library(randomwalk)` loads successfully
7. ✅ Dashboard UI appears
8. ✅ Simulations run correctly

**Check in browser console (F12):**
```
✅ Service Worker registered
✅ R version 4.4.1 starts
✅ webr::mount() succeeds (no CORS error)
✅ library(randomwalk) loads
✅ Shiny app starts
```

## Workflow Status

Monitor at: https://github.com/JohnGavin/randomwalk/actions

Expected workflows:
- nix-builder (tests)
- R-tests-via-nix (tests)
- pkgdown (deployment) ← This one matters for dashboard

## Summary

The fix is elegant and simple:
1. Keep wasm files in GitHub releases (source of truth)
2. Copy them to GitHub Pages during deployment (avoid CORS)
3. Load from same origin in dashboard (no cross-origin request)

This solution:
- Uses only GitHub (releases + pages)
- No external services
- No CORS issues
- Self-contained and maintainable

## Related Commits

1. `b9aced8` - Fix dashboard deployment (folder structure)
2. `090d95d` - Fix CORS issue (same-origin wasm files)

## Files Modified

- `.github/workflows/pkgdown.yaml` - Added wasm download step
- `inst/shiny/dashboard/app.R` - Changed source URL to relative path
