# 🚨 CRITICAL: Deployment Workflow Requirements 🚨

**THIS DOCUMENT MUST BE READ BEFORE MAKING ANY CODE CHANGES**

## ⚠️ The Problem That Keeps Happening

Claude Code repeatedly forgets that **changes on feature branches DO NOT automatically deploy to the live website**. This has caused multiple deployment issues where:

1. Changes are committed to a feature branch
2. GitHub Actions builds and validates successfully ✅
3. Developer thinks changes are deployed ❌
4. Live site remains unchanged because deployment only happens from `main` branch

## 🔴 CRITICAL RULE: Only Main Branch Deploys

**The GitHub Pages website at https://johngavin.github.io/randomwalk/ ONLY deploys from the `main` branch.**

### Why This Happens

See `.github/workflows/pkgdown.yaml` lines 109-115:

```yaml
- name: Deploy to GitHub pages
  if: github.event_name != 'pull_request'  # ← THIS LINE
  uses: JamesIves/github-pages-deploy-action@v4.4.1
  with:
    clean: false
    branch: gh-pages
    folder: docs
```

The `if: github.event_name != 'pull_request'` condition means:
- ✅ **Push to `main`**: Builds AND deploys
- ❌ **Feature branch PR**: Builds but DOES NOT deploy
- ✅ **Merge PR to `main`**: Builds AND deploys

## 📋 MANDATORY Deployment Checklist

Before assuming changes are live, verify EVERY TIME:

### Step 1: Check Current Branch
```bash
git branch --show-current
```

If you're NOT on `main`, changes will NOT deploy.

### Step 2: Check Deployment Branch
```bash
git log origin/main --oneline -1
```

Does the latest commit on `main` include your changes? If not, they're not deployed.

### Step 3: Verify GitHub Actions Context
```bash
gh run list --repo JohnGavin/randomwalk --workflow=pkgdown --limit 3
```

Look for:
- ✅ Branch: `main`
- ✅ Event: `push` (not `pull_request`)
- ✅ Status: `completed` and `success`

### Step 4: Check GitHub Pages Deployment
```bash
gh run list --repo JohnGavin/randomwalk --workflow="pages-build-deployment" --limit 2
```

Latest run should be AFTER your pkgdown run and show `success`.

## 🔄 CORRECT Workflow (Follow Every Time)

### Option A: Feature Branch → PR → Merge (RECOMMENDED)

```bash
# 1. Create feature branch
git checkout -b fix-issue-123-description

# 2. Make changes and commit
git add file.R
git commit -m "Fix: description"

# 3. Push branch
git push -u origin fix-issue-123-description

# 4. Create PR
gh pr create --base main --head fix-issue-123-description \
  --title "Fix: description" \
  --body "Description of changes"

# 5. Wait for CI checks to pass
gh pr checks

# 6. ⚠️ CRITICAL STEP: Merge to main
gh pr merge --merge --delete-branch

# 7. Wait for deployment
sleep 30
gh run list --workflow=pkgdown --limit 1

# 8. Verify deployment completed
gh run list --workflow="pages-build-deployment" --limit 1
```

### Option B: Direct to Main (Only for Hotfixes)

```bash
# 1. Switch to main
git checkout main
git pull origin main

# 2. Make changes and commit
git add file.R
git commit -m "Hotfix: description"

# 3. Push to main
git push origin main

# 4. Monitor deployment
gh run watch $(gh run list --workflow=pkgdown --limit 1 --json databaseId --jq '.[0].databaseId')
```

## ❌ WRONG Workflows (Do NOT Do This)

### Wrong: Commit to Branch and Assume It's Deployed

```bash
git checkout -b my-feature
git commit -am "My changes"
git push
# ❌ WRONG: Changes are NOT deployed!
```

### Wrong: Merge Locally Without Pushing to Main

```bash
git checkout main
git merge my-feature
# ❌ WRONG: Local merge, not pushed to origin/main
```

### Wrong: PR Without Merging

```bash
gh pr create ...
# ❌ WRONG: PR created but not merged to main
```

## 🎯 Verification: How to Know Changes Are ACTUALLY Deployed

After following the correct workflow:

### 1. Check Git
```bash
# Verify commit is on main
git log origin/main --oneline -3

# Should show your commit at or near the top
```

### 2. Check GitHub Actions
```bash
# Get latest main push workflow
gh run list --repo JohnGavin/randomwalk \
  --branch main \
  --event push \
  --workflow=pkgdown \
  --limit 1

# Status should be "completed" and "success"
```

### 3. Check GitHub Pages
```bash
# Get latest pages deployment
gh run list --repo JohnGavin/randomwalk \
  --workflow="pages-build-deployment" \
  --limit 1

# Should be AFTER your pkgdown run
```

### 4. Check Deployed Files (Optional)
```bash
# Check what's actually on gh-pages branch
git fetch origin gh-pages
git show origin/gh-pages:articles/dashboard_async/index.html | grep "Debug Logs"

# Should find "Debug Logs" if that's your change
```

### 5. Clear Browser Cache and Test
```
Visit: https://johngavin.github.io/randomwalk/articles/dashboard_async/
Hard refresh: Cmd+Shift+R (Mac) or Ctrl+Shift+R (Windows)
Check: Does the page show your changes?
```

## 📝 Logging Deployment Actions

**EVERY deployment must be logged in `R/setup/deployment_log.R`:**

```r
# Log format
cat("
=== DEPLOYMENT LOG ===
Date: ", Sys.time(), "
Branch: main
Commit: ", system('git rev-parse HEAD', intern=TRUE), "
Changes: [Brief description]
PR: #[number]
Deployed: [YES/NO]
Verified: [YES/NO]
Notes: [Any issues or observations]
========================
", file = "R/setup/deployment_log.R", append = TRUE)
```

## 🔍 Common Deployment Issues

### Issue 1: "I pushed but site didn't update"
**Solution**: Check if you pushed to `main` or a feature branch

### Issue 2: "GitHub Actions shows success but site is old"
**Solution**: Check if workflow was `pull_request` event (doesn't deploy)

### Issue 3: "Changes work locally but not on site"
**Solution**: Verify changes are actually on `main` branch

### Issue 4: "Site shows old version after merge"
**Solution**: Wait 2-3 minutes for GitHub Pages, then hard refresh browser

## 🎓 Learning Points

1. **Feature branches are for development, not deployment**
2. **Only `main` triggers deployment to GitHub Pages**
3. **Always verify deployment, don't assume it worked**
4. **Document all deployments in deployment log**
5. **When in doubt, check `git log origin/main`**

## 📚 Related Documentation

- Full workflow analysis: `DEPLOYMENT_WORKFLOW_ISSUE.md`
- GitHub Actions config: `.github/workflows/pkgdown.yaml`
- Workflow guide in CLAUDE.md: Section on "Git Best Practices"

---

**Remember: If you're not on `main`, you're not deploying!**
