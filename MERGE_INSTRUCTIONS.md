# Manual Steps to Deploy Dashboard Fix

## Current Status

✅ Dashboard fix is complete and pushed to `fix/shinylive-dashboard` branch
✅ All tests passed
✅ PR #19 is ready to merge

❌ **Dashboard NOT deployed yet** because PR hasn't been merged to main

## Why Dashboard Still Shows Blank Page

The pkgdown workflow has this condition:

```yaml
- name: Deploy to GitHub pages
  if: github.event_name != 'pull_request'  # Only deploys on main branch
```

Our fix is on the PR branch, but deployment only happens when code is on **main**.

## Steps to Deploy (MANUAL)

### Step 1: Merge PR #19

**Option A: Via GitHub Web Interface**
1. Go to: https://github.com/JohnGavin/randomwalk/pull/19
2. Click "Squash and merge"
3. Confirm merge

**Option B: Via Command Line**
```bash
cd /Users/johngavin/docs_gh/claude_rix/random_walk

# Checkout main
git checkout main
git pull origin main

# Merge fix branch
git merge fix/shinylive-dashboard

# Push to main
git push origin main
```

**Option C: Via GitHub CLI**
```bash
gh pr merge 19 --squash --delete-branch
```

### Step 2: Wait for Workflows

After merging to main, three workflows will run:
1. **nix-builder** - Building with Nix (~2-3 min)
2. **R-tests-via-nix** - Running tests (~2-3 min)
3. **pkgdown** - Building and deploying site (~2-3 min)

Monitor at: https://github.com/JohnGavin/randomwalk/actions

**THIS TIME IT WILL DEPLOY** because `github.event_name` will be "push" not "pull_request"

### Step 3: Publish New Release (IMPORTANT!)

The dashboard uses `webr::mount()` to load from:
```r
source = "https://github.com/JohnGavin/randomwalk/releases/latest/download/library.data"
```

**You must publish a new release** to trigger the `wasm-release.yaml` workflow that builds `library.data`:

1. Go to: https://github.com/JohnGavin/randomwalk/releases/new
2. Tag version: `v0.1.1` (or next version)
3. Release title: `v0.1.1 - Dashboard Fix`
4. Description:
   ```
   ## What's Fixed

   - ✅ Dashboard loads randomwalk package from GitHub release via webr::mount()
   - ✅ No more blank black page
   - ✅ Self-contained Shinylive app

   ## Changes

   - Fixed dashboard to use webr::mount() instead of R-Universe
   - Simplified pkgdown workflow (skip targets for now)
   - Dashboard now fully functional in browser
   ```
5. Click "Publish release"

This triggers `wasm-release.yaml` which:
- Builds WebAssembly file system image
- Attaches `library.data` to the release
- Makes it available at the URL the dashboard expects

### Step 4: Verify Dashboard Works

After both workflows complete (~5 minutes total):

1. Visit: https://johngavin.github.io/randomwalk/articles/dashboard.html
2. First load may take 10-30 seconds (downloading library.data)
3. Should see:
   - ✅ Dashboard UI with controls
   - ✅ "Random Walk Simulation Dashboard" title
   - ✅ Parameter sliders
   - ✅ Run Simulation button works

4. Check browser console (F12) for:
   ```
   Mounting file system from GitHub release...
   Loading randomwalk package...
   Package randomwalk loaded successfully
   ```

## What Gets Deployed

### On Main Branch (after PR merge):

File: `inst/shiny/dashboard/app.R`
```r
# Mount WebAssembly file system from GitHub release
webr::mount(
  mountpoint = "/randomwalk-lib",
  source = "https://github.com/JohnGavin/randomwalk/releases/latest/download/library.data"
)

.libPaths(c("/randomwalk-lib", .libPaths()))
library(randomwalk)
# ... rest of app
```

### On Release (after publishing v0.1.1):

The `wasm-release.yaml` workflow creates:
- `library.data` - WebAssembly file system image
- Attached to release as downloadable asset
- Dashboard loads this in the browser

## Why This Approach

✅ **Simple** - No external services (R-Universe not needed)
✅ **Direct** - GitHub release → Browser
✅ **Versioned** - Each release has its own library.data
✅ **Fast** - Everything already set up, just need to merge + release

## Troubleshooting

### If dashboard still blank after deployment:

1. **Check if pkgdown deployed:**
   - Look for "pages build and deployment" workflow at: https://github.com/JohnGavin/randomwalk/actions
   - Should show "success" after pkgdown completes

2. **Check if library.data exists:**
   - Go to: https://github.com/JohnGavin/randomwalk/releases/latest
   - Should see `library.data` in Assets

3. **Check browser console:**
   - Press F12
   - Look for errors loading library.data

4. **Clear browser cache:**
   - Hard refresh: Cmd+Shift+R (Mac) or Ctrl+Shift+R (Windows)

## Summary

| Step | Action | Time | URL |
|------|--------|------|-----|
| 1 | Merge PR #19 | 1 min | https://github.com/JohnGavin/randomwalk/pull/19 |
| 2 | Wait for workflows | 3 min | https://github.com/JohnGavin/randomwalk/actions |
| 3 | Publish release v0.1.1 | 1 min | https://github.com/JohnGavin/randomwalk/releases/new |
| 4 | Wait for wasm-release | 2 min | https://github.com/JohnGavin/randomwalk/actions |
| 5 | Verify dashboard | 1 min | https://johngavin.github.io/randomwalk/articles/dashboard.html |

**Total time: ~8 minutes**

Then the dashboard will work! 🎉
