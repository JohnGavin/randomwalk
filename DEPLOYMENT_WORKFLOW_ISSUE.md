# Deployment Workflow Issue Analysis

**Date**: 2025-11-24
**Issue**: Debug Logs tab not appearing at https://johngavin.github.io/randomwalk/articles/dashboard_async/

## Root Cause

The GitHub Pages deployment only occurs from commits on the `main` branch, but our Debug Logs changes were committed to the `fix-issue-37-enable-shinylive-export` branch.

## Detailed Timeline

1. **Commit 1da0b2e** (14:17 UTC): "Add Debug Logs tab to async dashboard for troubleshooting"
   - Branch: `fix-issue-37-enable-shinylive-export`
   - Status: Successfully committed and pushed
   - Contains: New Debug Logs tab in `inst/shiny/dashboard_async/app.R`

2. **Latest main branch commit c1bdead** (13:31 UTC): "Fix: Re-enable Shinylive export for async dashboard (#37) (#38)"
   - Branch: `main`
   - Status: Deployed to GitHub Pages
   - Does NOT contain: Debug Logs tab changes

3. **GitHub Actions workflow**: `.github/workflows/pkgdown.yaml`
   - Trigger conditions (lines 4-11):
     ```yaml
     on:
       push:
         branches: [main, master]
       pull_request:
         branches: [main, master]
       release:
         types: [published]
       workflow_dispatch:
     ```
   - Deployment step (lines 109-115): Only runs if NOT a pull_request
     ```yaml
     - name: Deploy to GitHub pages
       if: github.event_name != 'pull_request'
       uses: JamesIves/github-pages-deploy-action@v4.4.1
     ```

## Why This Happened

1. **PR builds don't deploy**: When commits are pushed to the feature branch `fix-issue-37-enable-shinylive-export`, GitHub Actions:
   - ✅ Builds the pkgdown site (for validation)
   - ✅ Exports the Shinylive async dashboard
   - ❌ **DOES NOT deploy to gh-pages** (blocked by `if: github.event_name != 'pull_request'`)

2. **Only main branch deploys**: Deployment to https://johngavin.github.io/randomwalk/ only happens when:
   - Commits are pushed directly to `main`, OR
   - A PR is merged into `main`

## Current State

- **Branch `fix-issue-37-enable-shinylive-export`**: Has Debug Logs tab (commit 1da0b2e)
- **Branch `main`**: Missing Debug Logs tab (latest: commit c1bdead)
- **Deployed site**: Reflects `main` branch (no Debug Logs tab)

## How the Sync Dashboard Works

The sync dashboard at https://johngavin.github.io/randomwalk/articles/dashboard/ works because:

1. It was properly merged to `main` before deployment
2. The pkgdown workflow built it from `main` and deployed it
3. The Shinylive export step correctly processed `inst/shiny/dashboard/app.R`

## Solution Options

### Option A: Merge to Main (Recommended)
Merge the `fix-issue-37-enable-shinylive-export` branch into `main`:

```bash
# Option A1: Via Pull Request (preferred - follows workflow)
gh pr create --base main --head fix-issue-37-enable-shinylive-export \
  --title "Add Debug Logs tab to async dashboard" \
  --body "Adds comprehensive debug logging to diagnose button click issues"
# Then merge via GitHub UI or: gh pr merge --merge

# Option A2: Direct merge (if no review needed)
git checkout main
git merge fix-issue-37-enable-shinylive-export
git push origin main
```

### Option B: Manual Trigger from Branch
Use workflow_dispatch to manually trigger deployment:

```bash
gh workflow run pkgdown.yaml --ref fix-issue-37-enable-shinylive-export
```

**Note**: This may still not deploy due to the `if: github.event_name != 'pull_request'` condition.

### Option C: Cherry-pick to Main
Apply just the Debug Logs commit to main:

```bash
git checkout main
git cherry-pick 1da0b2e
git push origin main
```

## Verification Steps

After merging to main:

1. **Check GitHub Actions**:
   ```bash
   gh run list --repo JohnGavin/randomwalk --workflow=pkgdown --limit 3
   ```

2. **Wait for deployment** (2-3 minutes)

3. **Verify on site**:
   - Visit: https://johngavin.github.io/randomwalk/articles/dashboard_async/
   - Check for "Debug Logs" tab in the navigation
   - Click tab to verify logging functionality

4. **Test logging**:
   - Click "Run Simulation" → Check Event Log for entries
   - Click "Reset to Defaults" → Check Event Log for reset messages
   - Check "Current State" section for parameter values

## Lessons Learned

1. **Branch-based development requires merging**: Changes on feature branches don't automatically deploy
2. **Workflow conditions matter**: The `if: github.event_name != 'pull_request'` prevents PR deployments
3. **Always check branch context**: Verify which branch is deployed vs. which has your changes
4. **Follow the workflow**: The CLAUDE.md workflow specifies:
   - Create branch for changes
   - Push to remote
   - **Merge via PR to main** ← This step was pending
   - Only then does deployment occur

## Next Steps

1. Create PR or merge branch to main
2. Wait for GitHub Actions to complete
3. Verify Debug Logs tab appears on deployed site
4. Use logs to diagnose the original button click issue
