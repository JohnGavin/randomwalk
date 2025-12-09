# Agent Development Guidelines

This document provides mandatory guidelines for AI agents working on this R package project.

## Critical Testing Requirements

### Local Testing Checklist

**BEFORE committing or pushing ANY changes, ALL of the following must be completed:**

1. **R Package Checks**
   ```r
   devtools::document()  # Update documentation
   devtools::test()      # Run all tests
   devtools::check()     # R CMD check (zero errors/warnings/notes)
   ```

2. **Website/Vignette Rendering**
   ```r
   pkgdown::build_site()  # Build complete website locally
   ```

3. **Shinylive Vignette Testing** ⚠️ **MANDATORY**

   For **EVERY** vignette that contains a Shinylive (r-shinylive) app:

   a. **Open in Browser**: Navigate to the locally built HTML file:
      - `docs/articles/dashboard.html`
      - `docs/articles/dashboard_async.html`
      - `docs/articles/dynamic_broadcasting.html`

   b. **Visual Verification**:
      - Wait for app to fully load (usually 10-30 seconds)
      - Verify the app interface appears
      - Test basic interactivity (buttons, sliders, inputs)

   c. **JavaScript Console Inspection** ⚠️ **CRITICAL**:
      - Open browser DevTools (F12 or Right-click → Inspect)
      - Navigate to "Console" tab
      - Check for errors (red text)
      - Document ALL errors, warnings, or failed network requests

   **Common Issues to Check:**
   - `404` errors for missing files
   - `Error fetching ../wasm/library.js.metadata`
   - `Requested package XXX not found in webR binary repo`
   - `Can't download Emscripten filesystem image metadata`
   - Service Worker registration failures
   - CORS or cross-origin errors

   d. **Package Loading Verification**:
      - Confirm the custom package (e.g., `randomwalk`) loads without errors
      - Check that all required R packages are available in WebR

   **DO NOT PROCEED if ANY errors appear in the JavaScript console**

### Why This Matters

**Historical Context**: Issue #125 (and previously #118, #103) occurred because Shinylive vignettes were committed and deployed WITHOUT testing in a browser. The apps appeared to load but failed silently with JavaScript errors that would have been immediately visible in the console.

**Impact of Skipping Console Checks**:
- Complete functionality broken on deployed website
- Users see loading spinner but app never starts
- Major showcase features non-functional
- Requires emergency fixes and redeployment
- Damages user trust and package reputation

### Automation Opportunities

Consider implementing:
1. **Pre-commit hooks**: Run `devtools::check()` automatically
2. **Shinylive validator**: Script to check WASM file paths
3. **CI headless browser tests**: Puppeteer/Selenium to detect JS errors
4. **Link checker**: Verify all WASM assets are accessible

## Workflow Requirements

All code changes must follow the 8-step workflow documented in `.claude/CLAUDE.md`:

1. Create GitHub Issue
2. Create dev branch (`usethis::pr_init()`)
3. Make changes
4. Run ALL checks locally (including Shinylive tests above)
5. Push via PR (`usethis::pr_push()`)
6. Wait for GitHub Actions
7. Merge PR (`usethis::pr_merge_main()`)
8. Log everything in `R/setup/`

**NEVER commit directly to main** - all changes must go through PR review and CI/CD validation.

## Documentation Standards

- Use R packages for all git/GitHub operations (`gert`, `gh`, `usethis`)
- Log all commands in `R/setup/` for reproducibility
- Include session logs IN the PR, not after merge
- Update documentation when adding/modifying features

## Nix Environment

- All development must occur inside the Nix shell
- Verify environment with `caffeinate -i ~/docs_gh/rix.setup/default.sh`
- Do not use `R CMD INSTALL` workarounds
- Build packages as proper Nix derivations

## Quality Gates

**Zero tolerance for**:
- Committing code that fails `devtools::check()`
- Deploying Shinylive apps without browser testing
- Skipping JavaScript console verification
- Pushing without running local tests

**Remember**: If it's not tested locally, it WILL break in production.

## Related Documentation

- **Workflow Details**: `.claude/CLAUDE.md`
- **Nix Setup**: `NIX_PACKAGE_DEVELOPMENT.md`
- **Troubleshooting**: `NIX_TROUBLESHOOTING.md`
- **Issue Tracking**: GitHub Issues

## Revision History

- 2025-12-09: Initial creation - Added mandatory Shinylive console testing (Issue #125)
