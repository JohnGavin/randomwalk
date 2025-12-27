#!/bin/bash
# Create Pull Request for Vignette Reorganization
# Generated with Claude Code
# Date: 2025-11-16

# Setup logging
LOG_FILE="R/setup/create_vignette_pr.log"
echo "$(date): Starting PR creation for vignette reorganization" | tee -a "$LOG_FILE"

# Get current branch
CURRENT_BRANCH=$(git branch --show-current)
echo "$(date): Current branch: $CURRENT_BRANCH" | tee -a "$LOG_FILE"

# Get latest commit
LATEST_COMMIT=$(git log -1 --format="%H")
COMMIT_SHORT=$(git log -1 --format="%h")
echo "$(date): Latest commit: $COMMIT_SHORT" | tee -a "$LOG_FILE"

# PR title
PR_TITLE="Move vignettes to standard location and update Shinylive dashboard"

# PR body
read -r -d '' PR_BODY << 'EOF'
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
EOF

echo "$(date): Creating pull request" | tee -a "$LOG_FILE"
echo "$(date): PR title: $PR_TITLE" | tee -a "$LOG_FILE"

# Create PR using GitHub CLI
# Note: gh CLI must be installed and authenticated
if command -v gh &> /dev/null; then
    echo "$(date): Using gh CLI to create PR" | tee -a "$LOG_FILE"

    # Create the PR
    PR_URL=$(gh pr create \
        --title "$PR_TITLE" \
        --body "$PR_BODY" \
        --base main \
        --head "$CURRENT_BRANCH" 2>&1)

    if [ $? -eq 0 ]; then
        echo "$(date): Pull request created successfully" | tee -a "$LOG_FILE"
        echo "$(date): PR URL: $PR_URL" | tee -a "$LOG_FILE"

        echo ""
        echo "==========================================="
        echo "Pull Request Created Successfully!"
        echo "==========================================="
        echo "Title: $PR_TITLE"
        echo "URL: $PR_URL"
        echo "Branch: $CURRENT_BRANCH -> main"
        echo "Commit: $COMMIT_SHORT"
        echo "==========================================="
        echo ""

        # Save PR URL for reference
        echo "$PR_URL" > R/setup/pr_url.txt
        echo "$(date): PR URL saved to R/setup/pr_url.txt" | tee -a "$LOG_FILE"
    else
        echo "$(date): ERROR: Failed to create pull request" | tee -a "$LOG_FILE"
        echo "$(date): Error: $PR_URL" | tee -a "$LOG_FILE"
        exit 1
    fi
else
    echo "$(date): ERROR: gh CLI not found" | tee -a "$LOG_FILE"
    echo "Please install GitHub CLI: https://cli.github.com/" | tee -a "$LOG_FILE"
    echo ""
    echo "Alternative: Create PR manually at:"
    echo "https://github.com/JohnGavin/randomwalk/pull/new/$CURRENT_BRANCH"
    exit 1
fi

echo "$(date): PR creation script completed successfully" | tee -a "$LOG_FILE"
echo ""
echo "Log saved to: $LOG_FILE"
