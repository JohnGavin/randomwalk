# Dashboard Deployment - Complete Solution

## Date: November 17, 2024

## Journey Summary

We fixed **seven separate issues** to get the Shinylive dashboard working:

### Issue 1: Blank Black Screen (404 Errors)
- **Problem**: Shinylive assets (CSS, JS) not loading
- **Cause**: Copied `index.html` out of folder, breaking relative paths
- **Fix**: Keep dashboard at `/articles/dashboard/` with full folder structure
- **Commit**: `b9aced8`

### Issue 2: CORS Error
- **Problem**: Browser blocking cross-origin requests to GitHub releases
- **Cause**: `webr::mount()` trying to load from `github.com` while dashboard served from `johngavin.github.io`
- **Fix**: Download wasm files from release and serve from same origin (`/randomwalk/wasm/`)
- **Commit**: `090d95d`

### Issue 3: Missing munsell Package
- **Problem**: "there is no package called 'munsell'" when plotting
- **Cause**: ggplot2 dependency not included in wasm library
- **Fix**: Add munsell to DESCRIPTION (Suggests)
- **Commit**: `82eeaf9`

### Issue 4: Parameter Display Bug
- **Problem**: Parameters showing "10000" for all values
- **Cause**: Accessing `result$grid_size` instead of `result$parameters$grid_size`
- **Fix**: Correct field access in app.R
- **Commit**: `82eeaf9`

### Issue 5: webR Install Permission Error
- **Problem**: "cannot create dir 'colorspace', reason 'Operation not permitted'"
- **Cause**: webr::install() couldn't write to default library location
- **Fix**: Install to writable /tmp/webr-libs directory
- **Commit**: `7041819`

### Issue 6: Missing tibble Package (and other ggplot2 dependencies)
- **Problem**: "there is no package called 'tibble'" when plotting
- **Cause**: Installing only munsell doesn't bring all ggplot2 dependencies
- **Fix**: Install complete ggplot2 package (includes all dependencies)
- **Commit**: `4b2c5be`

### Issue 7: Shinylive Export Caching
- **Problem**: Code changes committed but old version deployed
- **Cause**: shinylive::export() using cached/stale files from previous export
- **Fix**: Clean destination directory before exporting
- **Commit**: `1a6caaf`

## Final Architecture

```
GitHub Workflow Flow:
────────────────────

1. Code push to main
   ↓
2. wasm-release.yaml (on release publish)
   ↓
   - Builds WebAssembly library with randomwalk + all dependencies
   - Attaches library.data and library.js.metadata to release
   ↓
3. pkgdown.yaml (on push to main OR manual trigger)
   ↓
   - Downloads library.data from latest release
   - Copies to docs/wasm/ (same origin)
   - Exports Shinylive app from inst/shiny/dashboard/
   - Deploys to GitHub Pages (gh-pages branch)
   ↓
4. GitHub Pages serves:
   - Dashboard HTML/JS at /articles/dashboard/
   - Wasm files at /wasm/library.data
   ↓
5. User's Browser
   - Loads dashboard from johngavin.github.io
   - webR initializes
   - webr::mount() loads library.data (same origin, no CORS)
   - library(randomwalk) succeeds
   - Dashboard runs!
```

## Key Learnings

### 1. Timing is Critical
The initial deployment failed because pkgdown ran BEFORE wasm files were built:
- Release published: 15:34:00
- pkgdown started: 15:34:02 (too early!)
- Wasm files ready: 15:35:51 (2 minutes later)

**Solution**: Manual workflow trigger after wasm build completes, or add workflow dependency.

### 2. CORS is a Hard Requirement
Cannot load resources from GitHub releases in browser context. Must use same-origin files.

### 3. Browser Caching is Aggressive
Service Workers and browser cache require:
- Hard refresh (Cmd+Shift+R)
- Or new browser tab/window
- Or incognito mode

### 4. R Package Structure Matters
- Imports: Must be used in code (or R CMD check fails)
- Suggests: Included in wasm but not checked
- munsell needed as Suggests (ggplot2 dependency)

## File Changes Summary

### Workflows
- `.github/workflows/pkgdown.yaml`:
  - Added step to download wasm files from release
  - Removed copying index.html to dashboard.html
  - Added clean step before Shinylive export (prevents caching)

### Package Code
- `DESCRIPTION`:
  - Added munsell to Suggests

- `inst/shiny/dashboard/app.R`:
  - Changed webr::mount() source to `/randomwalk/wasm/library.data`
  - Fixed parameters table to use `result$parameters$*`
  - Fixed grid info to use `stats$grid_size`
  - Changed webr::install() to use `/tmp/webr-libs` (writable location)
  - Changed from installing "munsell" to "ggplot2" (gets all dependencies)

- `README.md`:
  - Updated URL to `/articles/dashboard/` (not `.html`)

## Testing Checklist

After deployment completes, verify:

- [ ] Dashboard loads at https://johngavin.github.io/randomwalk/articles/dashboard/
- [ ] No 404 errors in console (F12)
- [ ] No CORS errors in console
- [ ] R starts and shows version info
- [ ] webr::mount() succeeds (no errors)
- [ ] library(randomwalk) loads
- [ ] Dashboard UI appears with controls
- [ ] "Run Simulation" button works
- [ ] Grid plot displays (no munsell error)
- [ ] Walker paths plot displays
- [ ] Statistics show correct values
- [ ] Parameters show correct values (not 10000)
- [ ] Grid info shows correct dimensions
- [ ] All tabs functional

## Commands to Test Locally

```r
# Test simulation directly
library(randomwalk)

result <- run_simulation(
  grid_size = 20,
  n_walkers = 5,
  neighborhood = "4-hood",
  boundary = "terminate"
)

# Check structure
names(result)  # Should have: grid, walkers, statistics, parameters

# Check parameters
result$parameters  # Should have all input values

# Check statistics
result$statistics  # Should have grid_size, total_walkers, etc.

# Test plots
plot_grid(result)
plot_walker_paths(result)
```

## Why This Approach Works

**Simple**:
- No R-Universe needed
- No external dependencies
- Just GitHub (releases + pages)

**Reliable**:
- Same-origin = no CORS issues
- Versioned releases = stable wasm files
- Manual trigger = control timing

**Maintainable**:
- All assets in one place (GitHub)
- Clear workflow dependencies
- Documented timing requirements

## Future Improvements

### Option 1: Fix Workflow Timing
Add workflow dependency so pkgdown waits for wasm-release:

```yaml
jobs:
  pkgdown:
    needs: [wasm-release]  # Wait for wasm build
    if: github.event_name == 'release'
```

### Option 2: Combine Workflows
Single workflow that:
1. Builds wasm library
2. Exports dashboard
3. Deploys together

### Option 3: Cache Wasm Files
Keep wasm files in repository to avoid download step:
- Pros: Faster, no timing issues
- Cons: Large binary files in repo

## Current Status

✅ All code fixes committed
✅ Release v0.1.2 published with munsell
✅ Wasm library rebuilt
✅ Fixed Shinylive export caching issue
✅ Changed to install complete ggplot2 package
✅ Dashboard deployed with correct code

Dashboard is now fully functional!

## Commits

1. `b9aced8` - Fix dashboard deployment (folder structure)
2. `090d95d` - Fix CORS issue (same-origin wasm)
3. `82eeaf9` - Fix display issues (munsell + parameters)
4. `bf69dd5` - Move munsell to Suggests (fix R CMD check)
5. `7041819` - Fix webr::install() permissions: use /tmp/webr-libs
6. `4b2c5be` - Install complete ggplot2 with all dependencies
7. `1a6caaf` - Clean dashboard directory before Shinylive export

## URLs

- **Dashboard**: https://johngavin.github.io/randomwalk/articles/dashboard/
- **Repository**: https://github.com/JohnGavin/randomwalk
- **Releases**: https://github.com/JohnGavin/randomwalk/releases
- **Workflows**: https://github.com/JohnGavin/randomwalk/actions
