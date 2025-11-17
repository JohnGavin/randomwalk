# Claude Context - Random Walk Project

**Last Updated**: November 17, 2024
**Project Status**: ✅ Production Ready - v1.0.0
**Last Session**: Dashboard deployment completed and project cleaned up

## Project Overview

This is an R package implementing parallel random walk simulations with a fully functional browser-based Shinylive dashboard. The dashboard runs entirely in the browser using WebAssembly (webR) - no R installation required by users.

## Key Achievements

### v1.0.0 Milestone (November 17, 2024)
- ✅ Fully functional Shinylive dashboard deployed
- ✅ 7 deployment issues identified and resolved
- ✅ Complete documentation of the deployment journey
- ✅ Project cleaned and organized
- ✅ Comprehensive backup created

## Important URLs

- **Live Dashboard**: https://johngavin.github.io/randomwalk/articles/dashboard/
- **GitHub Repository**: https://github.com/JohnGavin/randomwalk
- **Latest Release**: https://github.com/JohnGavin/randomwalk/releases/tag/v1.0.0
- **GitHub Actions**: https://github.com/JohnGavin/randomwalk/actions

## Project Structure

```
/Users/johngavin/docs_gh/claude_rix/random_walk/
├── R/                          # R package source code
│   ├── setup/                  # Development workflow scripts (logged commands)
│   └── *.R                     # Package functions
├── inst/
│   └── shiny/dashboard/        # Shinylive dashboard app
│       └── app.R              # Main dashboard (deploys to GitHub Pages)
├── tests/                      # Test suite
├── vignettes/                  # Package vignettes
├── man/                        # Documentation
├── .github/workflows/          # CI/CD workflows
│   ├── pkgdown.yaml           # Builds site + dashboard, deploys to GitHub Pages
│   └── wasm-release.yaml      # Builds WebAssembly library on release
├── PROJECT_INFO.md            # Quick reference (URLs, restore instructions)
├── DASHBOARD_COMPLETE.md      # Complete dashboard deployment journey (7 issues)
├── CLEANUP_SUMMARY.md         # Cleanup details and restore procedures
├── CLAUDE_CONTEXT.md          # This file - context for future Claude sessions
└── DESCRIPTION                # Package metadata (Version: 1.0.0)
```

## Critical Files to Read First

When resuming work, read these files in order:

1. **PROJECT_INFO.md** - Quick overview, URLs, basic commands
2. **DASHBOARD_COMPLETE.md** - Complete deployment journey, all 7 issues resolved
3. **CLEANUP_SUMMARY.md** - What was cleaned, what can be rebuilt
4. **This file (CLAUDE_CONTEXT.md)** - Current context and next steps

## The 7 Dashboard Deployment Issues (All Resolved)

These are documented in detail in `DASHBOARD_COMPLETE.md`:

1. **404 Errors** - Fixed Shinylive asset folder structure (commit b9aced8)
2. **CORS Error** - Serve wasm files from same origin (commit 090d95d)
3. **Missing munsell** - Added to DESCRIPTION Suggests (commit 82eeaf9)
4. **Parameter Display Bug** - Fixed field access (commit 82eeaf9)
5. **Install Permission Error** - Use /tmp/webr-libs (commit 7041819)
6. **Missing ggplot2 Dependencies** - Explicit dependency list (commit 6b531b2)
7. **Shinylive Export Caching** - Clean before export (commit 1a6caaf)

## Key Technical Decisions

### Dashboard Architecture
- **Deployment**: GitHub Pages (johngavin.github.io/randomwalk)
- **Runtime**: webR (R in browser via WebAssembly)
- **Package Loading**: webr::mount() from same-origin wasm files
- **Dependencies**: Explicit webr::install() list to avoid resolution failures
- **No External Services**: No R-Universe needed, just GitHub

### Why Explicit ggplot2 Dependencies?
The key fix (issue #6) was installing all ggplot2 dependencies explicitly:
```r
webr::install(c("munsell", "colorspace", "farver", "labeling", "viridisLite",
                 "RColorBrewer", "scales", "tibble", "ggplot2"),
               lib = "/tmp/webr-libs")
```

Installing just `ggplot2` failed due to webR dependency resolution issues.

### Workflow Timing
- `wasm-release.yaml` runs on release publish (builds wasm library)
- `pkgdown.yaml` runs on push to main (downloads wasm, exports dashboard, deploys)
- Manual trigger recommended after release to ensure wasm files are ready

## Development Workflow

### Standard Git Workflow (Logged in R/setup/)
All development commands are logged in `R/setup/` for reproducibility:
1. Create GitHub issue
2. Create branch: `usethis::pr_init("fix-issue-123")`
3. Make changes
4. Commit: `gert::git_add("."); gert::git_commit("message")`
5. Test locally: `devtools::test()`, `devtools::check()`
6. Push: `usethis::pr_push()` (triggers workflows)
7. Wait for all workflows to pass
8. Merge PR: `usethis::pr_merge_main(); usethis::pr_finish()`

### Key Commands
```r
# Documentation
devtools::document()

# Testing
devtools::test()

# Package check
devtools::check()

# Build site locally
pkgdown::build_site()

# Rebuild targets
targets::tar_make()
```

### Creating Releases
```bash
# 1. Update version in DESCRIPTION
# 2. Commit and push
git add DESCRIPTION
git commit -m "Bump version to X.Y.Z"
git push origin main

# 3. Create release (triggers wasm-release.yaml)
gh release create vX.Y.Z --title "vX.Y.Z - Title" --notes "Release notes"

# 4. Wait for wasm-release to complete (~2-3 minutes)
# 5. Manually trigger pkgdown workflow or push to main
```

## Backup Information

**Location**: `/Users/johngavin/docs_gh/claude_rix/randomwalk_backup_v1.0.0_2025-11-17.tar.gz`
**Size**: 192MB
**Contents**: Complete snapshot (source, git history, generated files)

**Restore from backup**:
```bash
cd /Users/johngavin/docs_gh/claude_rix/
tar -xzf randomwalk_backup_v1.0.0_2025-11-17.tar.gz
```

**Restore from GitHub** (recommended):
```bash
cd /Users/johngavin/docs_gh/claude_rix/
rm -rf random_walk  # optional
git clone https://github.com/JohnGavin/randomwalk.git random_walk
cd random_walk
```

## What Was Deleted (Can Be Rebuilt)

These directories were removed during cleanup and are NOT in GitHub:
- `docs/` (5.5MB) - Rebuild with `pkgdown::build_site()`
- `_targets/` (1.4MB) - Rebuild with `targets::tar_make()`
- `inst/doc/` - Rebuild with `devtools::build_vignettes()`
- `.Rproj.user/` - RStudio temp files

## Current State

**Directory Size**: 164MB (cleaned from 231MB)
**Git Status**: Clean (all changes committed)
**Latest Commit**: 3a4c9fd - Add cleanup summary
**Branch**: main
**Files in Git**: 351 files

## Common Next Steps

### To Resume Development
```bash
cd /Users/johngavin/docs_gh/claude_rix/random_walk
git pull
git status
```

### To Start New Feature
```r
# 1. Create issue on GitHub first
# 2. Create branch
usethis::pr_init("feature-name")

# 3. Make changes, test, commit
devtools::test()
devtools::check()
gert::git_add(".")
gert::git_commit("Descriptive message")

# 4. Push and create PR
usethis::pr_push()
```

### To Update Dashboard
1. Edit `inst/shiny/dashboard/app.R`
2. Test locally if possible
3. Commit and push to main
4. pkgdown workflow will automatically redeploy

### To Debug Dashboard Issues
1. Check browser console (F12) for errors
2. Look for CORS errors, missing packages, or 404s
3. Review `DASHBOARD_COMPLETE.md` for similar issues
4. Check workflow runs: https://github.com/JohnGavin/randomwalk/actions
5. Verify wasm files exist at: https://johngavin.github.io/randomwalk/wasm/library.data

## Environment Setup

This project uses a Nix environment (see `/Users/johngavin/docs_gh/rix.setup/`):
- All R packages pre-installed in Nix shell
- Reproducible across sessions
- `default.nix` in project root defines environment

**Important**: Run all R commands inside the Nix shell.

## Troubleshooting Dashboard

### Dashboard Doesn't Load
- Check workflow completed: https://github.com/JohnGavin/randomwalk/actions
- Verify URL: https://johngavin.github.io/randomwalk/articles/dashboard/
- Try incognito window (cache issues)

### Missing Package Errors
- webR packages install from webR repository, not CRAN
- Some packages may not be available in webR
- If adding dependencies, test in browser first

### Deployment Timing Issues
- wasm-release must complete before pkgdown runs
- Manual trigger recommended after release
- Check workflow run times in Actions tab

## Key Learnings

1. **Shinylive Export Caching**: Always clean destination directory first
2. **webR Dependency Resolution**: Install dependencies explicitly, don't rely on automatic resolution
3. **CORS is Critical**: All resources must be same-origin in browser context
4. **Browser Caching**: Aggressive - use incognito for testing
5. **Workflow Timing**: wasm files must exist before pkgdown export

## References

**Shinylive**:
- https://posit-dev.github.io/r-shinylive/
- https://quarto-ext.github.io/shinylive/

**webR**:
- https://docs.r-wasm.org/webr/latest/

**Our Documentation**:
- All .md files in project root
- R/setup/ for command logs

## Notes for Claude

- **Always check git status first** when resuming
- **Read PROJECT_INFO.md** for quick context
- **Development workflow is logged** in R/setup/ for reproducibility
- **Dashboard is WORKING** - don't "fix" unless actually broken
- **All 7 deployment issues are resolved** - see DASHBOARD_COMPLETE.md
- **Explicit dependency installation** is intentional (issue #6 fix)
- **Use R packages for git**: gert, gh, usethis (commands in R/setup/)
- **Backup exists** if something goes wrong

## Session Summary (November 17, 2024)

This was a successful debugging and deployment session that:
1. Fixed the final missing package issue (tibble)
2. Resolved Shinylive export caching problem
3. Created v1.0.0 release
4. Cleaned and organized the project
5. Created comprehensive documentation

The dashboard is now production-ready and fully functional. Future work can focus on features or improvements rather than deployment issues.
