# Random Walk Project - Quick Reference

## Project Information

**Project Name**: randomwalk
**Current Version**: v1.0.0
**Status**: ✅ Production Ready - Fully Functional
**Last Updated**: November 17, 2024

## GitHub Repository

**URL**: https://github.com/JohnGavin/randomwalk
**Clone Command**:
```bash
git clone https://github.com/JohnGavin/randomwalk.git
cd randomwalk
```

## Live Dashboard

**URL**: https://johngavin.github.io/randomwalk/articles/dashboard/
**Type**: Shinylive R dashboard (runs in browser, no installation needed)

## Quick Start

### Restore Full Project
```bash
# From /Users/johngavin/docs_gh/claude_rix/
git clone https://github.com/JohnGavin/randomwalk.git random_walk
cd random_walk
```

### Key Files and Locations

**Documentation**:
- `DASHBOARD_COMPLETE.md` - Complete dashboard deployment journey (7 issues fixed)
- `CORS_FIX.md` - CORS issue details and solution
- `README.md` - Package documentation
- `R/setup/` - Development workflow scripts for reproducibility

**Package Structure**:
- `R/` - Core R package functions
- `inst/shiny/dashboard/` - Shinylive dashboard app
- `.github/workflows/` - CI/CD workflows (pkgdown, wasm-release)
- `tests/` - Test suite

**Key Workflows**:
- `pkgdown.yaml` - Builds and deploys documentation + dashboard
- `wasm-release.yaml` - Builds WebAssembly library for browser

## Important Links

- **Repository**: https://github.com/JohnGavin/randomwalk
- **Dashboard**: https://johngavin.github.io/randomwalk/articles/dashboard/
- **Releases**: https://github.com/JohnGavin/randomwalk/releases
- **Workflows**: https://github.com/JohnGavin/randomwalk/actions
- **Latest Release**: https://github.com/JohnGavin/randomwalk/releases/tag/v1.0.0

## Project Achievements (v1.0.0)

✅ Fully functional Shinylive dashboard
✅ Browser-based interactive simulations (no R installation required)
✅ Complete ggplot2 plotting support in browser
✅ Automated deployment via GitHub Actions
✅ Comprehensive documentation
✅ All 7 deployment issues resolved

## Development Commands

### Setup Environment
```bash
# Assumes nix environment is already configured
# See /Users/johngavin/docs_gh/rix.setup/default.nix
```

### Common Tasks
```r
# Build documentation
devtools::document()

# Run tests
devtools::test()

# Check package
devtools::check()

# Build site locally
pkgdown::build_site()
```

### Create New Release
```bash
# Bump version in DESCRIPTION
# Commit changes
git add DESCRIPTION
git commit -m "Bump version to X.Y.Z"
git push origin main

# Create release
gh release create vX.Y.Z --title "vX.Y.Z - Title" --notes "Release notes"
```

## Backup Information

**Backup Location**: `/Users/johngavin/docs_gh/claude_rix/`
**Backup Format**: `randomwalk_backup_v1.0.0_YYYY-MM-DD.zip`

## Restore Instructions

### Full Restore
```bash
cd /Users/johngavin/docs_gh/claude_rix/
git clone https://github.com/JohnGavin/randomwalk.git random_walk
cd random_walk
```

### Verify Restore
```bash
git status
git log --oneline -5
ls -la
```

## Contact & Attribution

**Author**: John Gavin
**License**: MIT + file LICENSE

## Notes for Claude

When resuming work on this project:
1. Change to `/Users/johngavin/docs_gh/claude_rix/random_walk`
2. Run `git status` to check current state
3. Run `git pull` to get latest changes
4. Read `DASHBOARD_COMPLETE.md` for complete deployment history
5. All development workflow scripts are in `R/setup/` for reference
6. Dashboard is live and working at the URL above
