# Deployment Guide

**Complete guide for deploying R package changes to GitHub Pages**

---

## Overview

This guide covers the complete deployment workflow for the randomwalk R package, including:
- How deployment works (GitHub Actions → GitHub Pages)
- Step-by-step deployment process
- Verification methods
- Session management and recovery
- Version management with git tags
- Troubleshooting common issues

**Target audience**: Developers working on the randomwalk package

---

## Critical Rules

### 🚨 Rule 1: Only Main Branch Deploys

**The GitHub Pages website at https://johngavin.github.io/randomwalk/ ONLY deploys from the `main` branch.**

**Why**: See `.github/workflows/pkgdown.yaml` lines 109-115:

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

### 🚨 Rule 2: Push to Cachix BEFORE Git Push

**MANDATORY Step 5**: Push package to johngavin cachix BEFORE pushing to GitHub.

**Why**: GitHub Actions pulls from cachix instead of rebuilding (saves time, ensures consistency).

See: [CACHIX_WORKFLOW.md](CACHIX_WORKFLOW.md) for details.

### 🚨 Rule 3: Log Everything

**EVERY deployment must be logged** in `R/setup/deployment_log.R` for reproducibility.

---

## Deployment Workflow

### Prerequisites

**Environment**: Must be in nix shell
```bash
cd /Users/johngavin/docs_gh/claude_rix/random_walk
caffeinate -i ~/docs_gh/rix.setup/default.sh
```

**Verify environment**:
```bash
which R        # Should return /nix/store/... path
which Rscript  # Should return /nix/store/... path
which git      # Should return /nix/store/... path
```

### Option A: Feature Branch → PR → Merge (RECOMMENDED)

**Use this for all normal development**

**Step 1: Create GitHub Issue**
```r
library(gh)
gh::gh("POST /repos/JohnGavin/randomwalk/issues",
  title = "Fix: description",
  body = "Detailed description of change"
)
# Note issue number (e.g., #123)
```

**Step 2: Create Development Branch**
```r
library(usethis)
usethis::pr_init("fix-issue-123-description")
```

**Step 3: Make Changes**
- Edit code/docs
- Commit locally:
```r
library(gert)
gert::git_add("path/to/file.R")
gert::git_commit("Fix #123: description")
```

**Step 4: Run All Checks Locally**
```r
devtools::document()    # Update docs
devtools::test()        # Run tests
devtools::check()       # R CMD check
pkgdown::build_site()   # Build website
```
- Fix ALL errors/warnings/notes before proceeding

**Step 5: Push to Cachix (MANDATORY)**
```bash
# Exit R temporarily
exit

# Push to johngavin cachix
./push_to_cachix.sh

# Returns you to R when done
```

**Why mandatory**: GitHub Actions pulls from cachix (instant), avoiding rebuild.

**Step 6: Push to GitHub**
```r
# Back in R
usethis::pr_push()  # Creates PR automatically
```

**Step 7: Wait for GitHub Actions**

Monitor workflows:
```r
gh::gh("GET /repos/JohnGavin/randomwalk/actions/runs", .limit = 3)
```

Required workflows must pass:
- R-CMD-check via Nix ✅
- Check Package via Nix ✅
- Build and Deploy pkgdown Site ✅

**Step 8: Merge PR**
```r
# After all checks pass
usethis::pr_merge_main()  # Merges to main, triggers deployment
usethis::pr_finish()      # Cleans up branch
```

**Step 9: Log Deployment**
```r
# Log all commands used
cat("
=== DEPLOYMENT LOG ===
Date: ", Sys.time(), "
Branch: main
Commit: ", system('git rev-parse HEAD', intern=TRUE), "
Issue: #123
Changes: [Brief description]
PR: [PR number]
Deployed: YES
Verified: [After verification]
========================
", file = "R/setup/deployment_log.R", append = TRUE)
```

### Option B: Direct to Main (Hotfixes Only)

**Use ONLY for critical hotfixes**

```bash
# 1. Switch to main
git checkout main
git pull origin main

# 2. Make changes and commit
git add file.R
git commit -m "Hotfix: description"

# 3. Push to cachix FIRST
./push_to_cachix.sh

# 4. Push to main
git push origin main

# 5. Monitor deployment
gh run watch $(gh run list --workflow=pkgdown --limit 1 --json databaseId --jq '.[0].databaseId')
```

---

## Verification Methods

After deploying, verify changes are live using these methods:

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

### 3. Check GitHub Pages Deployment
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
git show origin/gh-pages:articles/dashboard_async/index.html | grep "search-text"

# Should find your changes
```

### 5. Test in Browser
```
Visit: https://johngavin.github.io/randomwalk/
Hard refresh: Cmd+Shift+R (Mac) or Ctrl+Shift+R (Windows)
Verify: Does the page show your changes?
```

**Note**: GitHub Pages may take 2-3 minutes to reflect changes after workflow completes.

---

## Session Management and Recovery

### End-of-Session Checklist

Before closing your session:

```r
# 1. Commit or stash work
gert::git_add(".")
gert::git_commit("Progress: description")
# OR
system("git stash push -m 'WIP: description'")

# 2. Update current work file
# Edit .claude/CURRENT_WORK.md with current status

# 3. Push to remote (backup)
gert::git_push()

# 4. Safe to exit
q()
```

### Start-of-Session Protocol

When resuming work:

```bash
# 1. Enter nix shell
cd /Users/johngavin/docs_gh/claude_rix/random_walk
caffeinate -i ~/docs_gh/rix.setup/default.sh

# 2. Check status
git status
git log --oneline -5

# 3. If work was stashed:
git stash list
git stash pop  # Apply most recent stash
```

### Session Restart Instructions

If you created a `RESTART_INSTRUCTIONS.md` file:

1. Read that file for session-specific context
2. Execute any pending commands from that file
3. Continue where you left off

**Files to check**:
- `.claude/CURRENT_WORK.md` - Current focus and progress
- `R/setup/fix_issue_*.R` - Session log files
- `RESTART_INSTRUCTIONS.md` - Session-specific instructions (if exists)

### Multiple Repository Changes

Some sessions may involve changes to multiple git repositories:

1. `/Users/johngavin/docs_gh/rix.setup` (nix environment)
2. `/Users/johngavin/docs_gh/claude_rix` (workflow docs)
3. `/Users/johngavin/docs_gh/claude_rix/random_walk` (main package)

**Note**: Only the package directory (random_walk) needs git commits. Parent directories are not git repos.

---

## Tag-Based Version Management

### Using Tags for Stable Versions

Tags mark stable milestones you can return to later.

**View available tags**:
```bash
git tag -l
```

**View tag details**:
```bash
git show v1.0.1-async-dashboard-working
```

### Reversion Scenarios

**Scenario 1: Just Look at Old Code (Read-Only)**
```bash
# Check out the tag (detached HEAD state)
git checkout v1.0.1-async-dashboard-working

# Look around, test, etc.
# When done, return to main:
git checkout main
```

**Scenario 2: Create Branch from Tag (Recommended)**
```bash
# Create a new branch from the tag
git checkout -b fix-issue-123-from-v1.0.1 v1.0.1-async-dashboard-working

# Make changes, commit as usual
git add .
git commit -m "Fix: description"

# Push your new branch
git push -u origin fix-issue-123-from-v1.0.1

# Create PR to merge back to main
gh pr create --base main --head fix-issue-123-from-v1.0.1
```

**Scenario 3: Cherry-Pick Specific Commits from Tag**
```bash
# Check out main
git checkout main

# Find commits in the tag
git log v1.0.1-async-dashboard-working --oneline | head -10

# Cherry-pick specific commit
git cherry-pick <commit-sha>

# Push to main
git push origin main
```

**Scenario 4: Hard Reset to Tag (DANGEROUS)**

⚠️ **WARNING**: This permanently deletes all commits after the tag!

```bash
# Backup current main first!
git checkout main
git branch backup-main-$(date +%Y%m%d)

# Hard reset to tag
git reset --hard v1.0.1-async-dashboard-working

# Force push (DANGEROUS - requires team coordination)
git push origin main --force
```

**Better alternative**: Create revert commits instead:
```bash
git revert <bad-commit-sha>..HEAD
git push origin main
```

### Creating New Tags

Tag frequently at stable milestones:

```bash
# Create annotated tag
git tag -a v1.0.2-feature-name -m "Description of milestone"

# Push tag to remote
git push origin v1.0.2-feature-name
```

**Semantic versioning**:
- `v1.0.0` - Major release
- `v1.1.0` - New features
- `v1.0.1` - Bug fixes

### Recovering from Mistakes

**If you accidentally deleted commits**:
```bash
# Find the lost commit
git reflog

# Cherry-pick it back
git cherry-pick <commit-sha>
```

**If you force-pushed by mistake**:
```bash
# GitHub keeps refs for ~30 days
git reflog  # Check local history
# Contact GitHub support or check reflog on other clones
```

---

## Troubleshooting Common Issues

### Issue 1: "I pushed but site didn't update"

**Symptoms**: Changes committed and pushed, but website shows old version

**Diagnosis**:
```bash
git branch --show-current  # Are you on main?
git log origin/main --oneline -1  # Is your commit on main?
```

**Solution**: Check if you pushed to `main` or a feature branch. Only `main` triggers deployment.

**Fix**: Merge your branch to main via PR.

---

### Issue 2: "GitHub Actions shows success but site is old"

**Symptoms**: Workflow completed successfully, but site unchanged

**Diagnosis**:
```bash
gh run list --workflow=pkgdown --limit 3
# Check if event is "pull_request" (doesn't deploy)
```

**Solution**: Workflow may have been `pull_request` event (validates but doesn't deploy).

**Fix**: Merge PR to main to trigger deployment.

---

### Issue 3: "Changes work locally but not on site"

**Symptoms**: `pkgdown::build_site()` works locally, but deployed site missing changes

**Diagnosis**:
```bash
git log origin/main --oneline -5
# Are your commits actually on main?
```

**Solution**: Changes may not be on `main` branch yet.

**Fix**: Ensure changes are merged to main and deployment workflow completed.

---

### Issue 4: "Site shows old version after merge"

**Symptoms**: PR merged, workflow succeeded, but site shows old content

**Diagnosis**:
```bash
gh run list --workflow="pages-build-deployment" --limit 2
# Did pages deployment run AFTER pkgdown workflow?
```

**Solution**: GitHub Pages may take 2-3 minutes to propagate changes.

**Fix**:
1. Wait 2-3 minutes
2. Hard refresh browser (Cmd+Shift+R or Ctrl+Shift+R)
3. Clear browser cache if needed

---

### Issue 5: "Vignette links return 404"

**Symptoms**: Vignette links on pkgdown site return 404 errors

**Diagnosis**:
```bash
# Check if workflow builds actual HTML files
grep "build_articles" .github/workflows/pkgdown.yaml
```

**Solution**: Workflow may only build articles INDEX, not HTML files.

**Fix**: Update workflow to build actual vignette HTML:
```yaml
- name: Build site
  run: |
    Rscript -e 'pkgdown::build_articles()'  # ← Ensure this builds HTML
```

---

### Issue 6: "Workflow fails with 'package not in cache'"

**Symptoms**: GitHub Actions fails with package not found in cachix

**Diagnosis**:
```bash
# Did you push to cachix BEFORE git push?
cachix cache johngavin --list | grep randomwalk
```

**Solution**: Step 5 (cachix push) is MANDATORY before Step 6 (git push).

**Fix**:
```bash
# Push to cachix now
./push_to_cachix.sh

# Then re-run workflow
gh workflow run pkgdown.yaml --ref main
```

---

## Best Practices

### Development Practices

1. **Always use feature branches** for development, never commit directly to main
2. **Create GitHub issues first** to document what needs to be changed
3. **Run all checks locally** before pushing to GitHub
4. **Push to cachix BEFORE git push** (mandatory Step 5)
5. **Wait for CI/CD to pass** before merging PRs

### Documentation Practices

1. **Log all commands** in `R/setup/` files for reproducibility
2. **Update `.claude/CURRENT_WORK.md`** every 1-2 hours
3. **Create session logs** before long breaks
4. **Document deployment** in `R/setup/deployment_log.R`

### Git Practices

1. **Create tags at stable milestones** for easy reversion
2. **Use semantic versioning** for tags
3. **Create backup branches** before risky operations
4. **Prefer new branches over hard resets** to preserve history

### Verification Practices

1. **Always verify deployment** after merging to main
2. **Check GitHub Actions logs** for any warnings
3. **Test in browser with hard refresh** to bypass cache
4. **Document any issues encountered** for future reference

---

## Quick Reference Commands

### Deployment
```bash
./push_to_cachix.sh              # Push to cachix (Step 5)
usethis::pr_push()               # Push to GitHub and create PR
usethis::pr_merge_main()         # Merge PR to main
```

### Verification
```bash
git log origin/main --oneline -3                    # Check commits on main
gh run list --workflow=pkgdown --limit 3            # Check pkgdown runs
gh run list --workflow="pages-build-deployment"     # Check page deployments
```

### Recovery
```bash
git stash list                   # List stashed changes
git stash pop                    # Apply most recent stash
git reflog                       # Find lost commits
git tag -l                       # List available tags
```

---

## References

### Documentation
- [CACHIX_WORKFLOW.md](CACHIX_WORKFLOW.md) - Cachix binary cache guide
- [NIX_WORKFLOW.md](/Users/johngavin/docs_gh/claude_rix/NIX_WORKFLOW.md) - Complete nix workflow
- [NIX_TROUBLESHOOTING.md](/Users/johngavin/docs_gh/claude_rix/NIX_TROUBLESHOOTING.md) - Nix troubleshooting
- [context_claude.md](/Users/johngavin/docs_gh/claude_rix/context_claude.md) - Complete agent instructions

### Archived Deployment Docs

The following files were consolidated into this guide:
- `archive/deployment_docs/CRITICAL_DEPLOYMENT_WORKFLOW.md`
- `archive/deployment_docs/DEPLOYMENT_WORKFLOW_ISSUE.md`
- `archive/deployment_docs/RESTART_INSTRUCTIONS.md`
- `archive/deployment_docs/REVERTING_TO_TAGS.md`

### External References
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitHub Pages Documentation](https://docs.github.com/en/pages)
- [pkgdown Documentation](https://pkgdown.r-lib.org/)
- [Git Tagging Documentation](https://git-scm.com/book/en/v2/Git-Basics-Tagging)

---

**Last Updated**: December 2025
**Status**: Consolidated from 4 deployment documents
**Maintained by**: randomwalk development team
