# Deploying Shinylive Dashboards to GitHub Pages

This guide covers the complete deployment process for Shinylive dashboards within R packages, based on lessons learned from the randomwalk dashboard deployment.

## Architecture Overview

```
GitHub Workflow Flow:
────────────────────

1. Code push to main
   ↓
2. wasm-release.yaml (on release publish)
   ↓
   - Builds WebAssembly library with package + all dependencies
   - Attaches library.data and library.js.metadata to release
   ↓
3. pkgdown.yaml (on push OR manual trigger)
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
   - Loads dashboard from yourusername.github.io
   - webR initializes
   - webr::mount() loads library.data (same origin, no CORS)
   - library(yourpackage) succeeds
   - Dashboard runs!
```

## Common Issues and Solutions

During deployment, you may encounter these issues. Here's how to solve them:

### Issue 1: Blank Black Screen (404 Errors)

**Problem**: Shinylive assets (CSS, JS) not loading

**Cause**: Incorrect folder structure or broken relative paths

**Solution**:
- Keep dashboard at `/articles/dashboard/` with full folder structure
- Don't copy `index.html` out of its directory
- Maintain the complete Shinylive export structure

**How to fix:**
```yaml
# In .github/workflows/pkgdown.yaml
# Keep the full directory structure
- name: Export Shinylive app
  run: |
    # Export to articles/dashboard/ (not a single HTML file)
    Rscript -e 'shinylive::export("inst/shiny/dashboard", "docs/articles/dashboard")'
```

### Issue 2: CORS Errors

**Problem**: Browser blocking cross-origin requests to GitHub releases

**Cause**: Trying to load wasm files from `github.com` while dashboard served from `yourusername.github.io`

**Solution**:
- Download wasm files from release
- Serve from same origin as dashboard

**How to fix:**
```yaml
# In .github/workflows/pkgdown.yaml
- name: Download wasm library from latest release
  run: |
    gh release download latest --pattern "library.data" \
      --repo ${{ github.repository }} --dir wasm_temp
    mkdir -p docs/wasm
    mv wasm_temp/library.data docs/wasm/
```

**Update your app:**
```r
# In inst/shiny/dashboard/app.R
# Change from:
webr::mount(source = "https://github.com/user/repo/releases/download/v0.1.0/library.data")

# To:
webr::mount(source = "/repo-name/wasm/library.data")
```

### Issue 3: Missing Package Dependencies

**Problem**: "there is no package called 'X'" when running dashboard

**Cause**: Package dependencies not included in wasm library or not installed

**Solution Option 1**: Add to DESCRIPTION
```r
# In DESCRIPTION file
Suggests:
    munsell,  # ggplot2 dependency
    tibble,   # another common dependency
    ...
```

**Solution Option 2**: Install at runtime
```r
# In app.R, use writable directory
install_dir <- "/tmp/webr-libs"
dir.create(install_dir, showWarnings = FALSE, recursive = TRUE)
.libPaths(c(install_dir, .libPaths()))

# Install complete package (gets all dependencies)
webr::install("ggplot2")  # Better than installing individual deps
```

### Issue 4: Parameter/Data Display Bugs

**Problem**: UI showing wrong values or "undefined"

**Cause**: Incorrect field access in reactive expressions

**Solution**:
- Check exact structure of result objects
- Use correct nested field access

**Example fix:**
```r
# Wrong:
result$grid_size

# Right:
result$parameters$grid_size

# Or for statistics:
result$statistics$grid_size
```

### Issue 5: webR Install Permission Errors

**Problem**: "cannot create dir, reason 'Operation not permitted'"

**Cause**: Default library location not writable in browser environment

**Solution**: Install to `/tmp` directory
```r
# Create writable directory
install_dir <- "/tmp/webr-libs"
dir.create(install_dir, showWarnings = FALSE, recursive = TRUE)

# Add to library paths BEFORE installing
.libPaths(c(install_dir, .libPaths()))

# Now install works
webr::install("ggplot2")
```

### Issue 6: Shinylive Export Caching

**Problem**: Code changes committed but old version deployed

**Cause**: shinylive::export() using cached/stale files

**Solution**: Clean destination before exporting
```yaml
# In .github/workflows/pkgdown.yaml
- name: Export Shinylive app
  run: |
    # Clean old export
    rm -rf docs/articles/dashboard

    # Export fresh
    Rscript -e 'shinylive::export("inst/shiny/dashboard", "docs/articles/dashboard")'
```

### Issue 7: Workflow Timing Problems

**Problem**: pkgdown runs before wasm files are ready

**Cause**: Workflows triggered simultaneously, pkgdown starts too early

**Solution Option 1**: Manual trigger after wasm build
- Let wasm-release.yaml complete
- Then manually trigger pkgdown workflow

**Solution Option 2**: Add workflow dependency
```yaml
# In .github/workflows/pkgdown.yaml
jobs:
  pkgdown:
    needs: [wasm-release]  # Wait for wasm build
    if: github.event_name == 'release'
```

## Complete Setup Checklist

### Repository Setup

- [ ] Enable GitHub Pages (Settings → Pages → Source: gh-pages branch)
- [ ] Enable GitHub Actions workflows

### Workflow Files

**`.github/workflows/wasm-release.yaml`**:
```yaml
name: Build WebAssembly Release

on:
  release:
    types: [published]

jobs:
  build-wasm:
    runs-on: ubuntu-latest
    steps:
      - uses: r-lib/actions/setup-r@v2
      - name: Build wasm library
        run: |
          # Build WebAssembly version with all dependencies
          # Attach library.data to release
```

**`.github/workflows/pkgdown.yaml`**:
```yaml
- name: Download wasm files
  run: |
    gh release download latest --pattern "library.data"
    mkdir -p docs/wasm
    mv library.data docs/wasm/

- name: Clean and export Shinylive
  run: |
    rm -rf docs/articles/dashboard
    Rscript -e 'shinylive::export("inst/shiny/dashboard", "docs/articles/dashboard")'
```

### Package Code

**`inst/shiny/dashboard/app.R`**:
```r
# Mount wasm library (same origin, no CORS)
webr::mount(
  mountpoint = "/package-lib",
  source = "/repo-name/wasm/library.data"
)

.libPaths(c("/package-lib", .libPaths()))

# Install additional dependencies if needed
install_dir <- "/tmp/webr-libs"
dir.create(install_dir, showWarnings = FALSE, recursive = TRUE)
.libPaths(c(install_dir, .libPaths()))

webr::install("ggplot2")  # Installs with all dependencies

# Load your package
library(yourpackage)
```

## Testing Checklist

After deployment completes, verify:

- [ ] Dashboard loads at `https://username.github.io/repo/articles/dashboard/`
- [ ] No 404 errors in browser console (F12)
- [ ] No CORS errors in console
- [ ] R starts and shows version info
- [ ] `webr::mount()` succeeds (no errors)
- [ ] `library(yourpackage)` loads
- [ ] Dashboard UI appears with all controls
- [ ] Interactive features work (buttons, inputs)
- [ ] Plots render correctly
- [ ] All tabs functional
- [ ] Data displays correctly

## Browser Debugging Tips

**Open browser console** (F12) to check for:

1. **404 errors**: Missing files, check paths
2. **CORS errors**: Files from wrong origin
3. **JavaScript errors**: Code issues
4. **Network tab**: See what files are loading

**Hard refresh** to bypass cache:
- Mac: Cmd+Shift+R
- Windows/Linux: Ctrl+Shift+R
- Or use incognito/private mode

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
- Documented requirements

## Future Improvements

### Option 1: Automatic Workflow Dependencies
```yaml
jobs:
  pkgdown:
    needs: [wasm-release]
    # Waits for wasm build automatically
```

### Option 2: Combine Workflows
Single workflow that builds, exports, and deploys together

### Option 3: Cache Wasm Files
Keep wasm files in repository
- Pros: Faster, no timing issues
- Cons: Large binary files in repo

## Related Resources

- **r-shinylive**: https://posit-dev.github.io/r-shinylive/
- **Quarto Shinylive**: https://quarto-ext.github.io/shinylive/
- **webR Documentation**: https://r-wasm.github.io/quarto-live/
- **Example Demo**: https://github.com/coatless-quarto/r-shinylive-demo

## Related Wiki Pages

- See [[Troubleshooting Nix Environment]] for local development environment
- See [[Working with Claude Across Sessions]] for managing development workflow
