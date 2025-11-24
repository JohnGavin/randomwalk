# How to Revert to Tagged Versions

This document explains how to safely revert to previous stable versions of the code using git tags.

## Available Tags

- `v1.0.1-async-dashboard-working` - First fully working async dashboard (2025-11-24)
  - All buttons functional
  - Debug logging working
  - Async/parallel simulation with crew workers
  - Compatible with WebR/Shinylive

## Quick Reference Commands

### View all available tags
```bash
git tag -l
```

### View tag details
```bash
git show v1.0.1-async-dashboard-working
```

### Check out a specific tag (read-only)
```bash
git checkout v1.0.1-async-dashboard-working
```

## Reversion Scenarios

### Scenario 1: Just Want to Look at Old Code (Read-Only)

```bash
# Check out the tag (detached HEAD state)
git checkout v1.0.1-async-dashboard-working

# Look around, test, etc.
# When done, return to main:
git checkout main
```

**Note**: In this state, any changes you make won't be saved to any branch.

### Scenario 2: Create a Branch from a Tag (Recommended)

If you want to work from a stable version:

```bash
# Create a new branch from the tag
git checkout -b fix-issue-123-from-v1.0.1 v1.0.1-async-dashboard-working

# Now you're on a new branch based on the stable version
# Make changes, commit as usual
git add .
git commit -m "Fix: description"

# Push your new branch
git push -u origin fix-issue-123-from-v1.0.1

# Create PR to merge back to main when ready
gh pr create --base main --head fix-issue-123-from-v1.0.1
```

### Scenario 3: Hard Reset Main to a Tag (DANGEROUS - Loses History)

**⚠️ WARNING: This permanently deletes all commits after the tag. Only use if absolutely necessary!**

```bash
# Backup current main first!
git checkout main
git branch backup-main-$(date +%Y%m%d)

# Hard reset to tag
git reset --hard v1.0.1-async-dashboard-working

# Force push (DANGEROUS - requires team coordination)
git push origin main --force
```

**Better alternative**: Create a revert commit instead:
```bash
# Create a new commit that undoes changes
git revert <bad-commit-sha>..HEAD
git push origin main
```

### Scenario 4: Cherry-Pick Specific Commits from a Tag

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

## Best Practices

1. **Always create a backup branch before risky operations**:
   ```bash
   git branch backup-$(date +%Y%m%d)
   ```

2. **Prefer creating new branches over hard resets**:
   - Preserves history
   - Easier to review changes
   - Safer for collaboration

3. **Tag frequently at stable milestones**:
   ```bash
   git tag -a v1.0.2-feature-name -m "Description"
   git push origin v1.0.2-feature-name
   ```

4. **Use semantic versioning**:
   - `v1.0.0` - Major release
   - `v1.1.0` - New features
   - `v1.0.1` - Bug fixes

## Recovering from Mistakes

### If you accidentally deleted commits

```bash
# Find the lost commit
git reflog

# Cherry-pick it back
git cherry-pick <commit-sha>
```

### If you force-pushed by mistake

```bash
# GitHub keeps refs for ~30 days
# Contact GitHub support or check reflog on other clones
git reflog
```

## Example Workflow: Testing a Fix on Stable Version

```bash
# 1. Create branch from stable tag
git checkout -b test-fix-40 v1.0.1-async-dashboard-working

# 2. Make your changes
# Edit files...

# 3. Test locally
devtools::check()
pkgdown::build_site()

# 4. Commit
git add .
git commit -m "Test: potential fix for issue #40"

# 5. Push and create PR
git push -u origin test-fix-40
gh pr create --base main --head test-fix-40

# 6. After merge, clean up
git checkout main
git pull
git branch -d test-fix-40
git push origin --delete test-fix-40
```

## Additional Resources

- [Git Tagging Documentation](https://git-scm.com/book/en/v2/Git-Basics-Tagging)
- [GitHub Releases](https://docs.github.com/en/repositories/releasing-projects-on-github)
- Project-specific: `CRITICAL_DEPLOYMENT_WORKFLOW.md`
