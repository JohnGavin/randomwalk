## Summary

This PR reorganizes vignettes to follow standard R package conventions and updates the Shinylive dashboard vignette with full WebAssembly support.

## Changes

### Vignette Reorganization
- ✅ Moved `telemetry.qmd` from `inst/qmd/` to `vignettes/` (standard R package location)
- ✅ Removed old `dashboard.qmd` from `inst/qmd/` (non-standard location)
- ✅ Updated `dashboard.qmd` in `vignettes/` with complete Shinylive implementation

### Dashboard Features
- Complete browser-based interactive Shiny application
- Parameter controls: grid size, walkers, neighborhood, boundary behavior
- Multiple output views: grid state, paths, statistics, raw data
- Runs entirely client-side using WebAssembly - no R server required
- Loads randomwalk package from mounted filesystem image
- Comprehensive documentation and usage examples

### Technical Details
- Uses Quarto shinylive extension for WebAssembly compilation
- Includes webR runtime and R package binaries (ggplot2, shiny, etc.)
- Vignettes now in standard `vignettes/` folder for pkgdown integration
- Dashboard will appear as article on GitHub Pages website

## Files Changed

- **vignettes/telemetry.qmd**: Moved from inst/qmd/
- **vignettes/dashboard.qmd**: Updated with full dashboard implementation
- **vignettes/dashboard.html**: Rendered output with embedded WebAssembly
- **vignettes/dashboard_files/**: Supporting assets (webR, libraries, fonts) - 229 files
- **inst/qmd/dashboard.qmd**: Removed (relocated to vignettes/)

## Statistics

- Total changes: **118,467 insertions**, **779 deletions**
- Files changed: **229 files**
- Dashboard HTML size: **50KB**

## Testing

### Local Testing
- [x] Rendered dashboard.qmd successfully with Quarto
- [x] Verified WebAssembly assets are included
- [x] Updated docs/articles/index.html with dashboard link
- [x] Updated docs/index.html navigation

### GitHub Pages Testing
- [ ] Dashboard accessible at `/articles/dashboard.html`
- [ ] WebAssembly loads correctly in browser
- [ ] Shinylive app runs without errors
- [ ] All navigation links work

## Deployment

Once merged, the dashboard will be available at:
https://johngavin.github.io/randomwalk/articles/dashboard.html

## Related Issues

Follows standard R package structure guidelines from `context.md`:
- Section 3.1: Use Quarto (.qmd) files for vignettes
- Section 3.3: Vignettes belong in vignettes/ folder
- Section 11: pkgdown website generation

🤖 Generated with [Claude Code](https://claude.com/claude-code)
