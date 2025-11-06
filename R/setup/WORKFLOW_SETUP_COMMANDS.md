# GitHub Workflows Setup - Manual Commands

## Summary

Successfully created three GitHub Actions workflows based on ropensci/rix examples:

1. **`.github/workflows/tests-r-via-nix.yaml`** - Runs `devtools::test()` in Nix environment on macOS and Ubuntu
2. **`.github/workflows/nix-builder.yaml`** - Builds and tests `default.nix` configuration
3. **`.github/workflows/pkgdown.yaml`** - Builds and deploys package documentation site

## Files Created

- `.github/workflows/tests-r-via-nix.yaml`
- `.github/workflows/nix-builder.yaml`
- `.github/workflows/pkgdown.yaml`
- `R/setup/dev_log.R` (updated with workflow setup commands)

## Next Steps - Run These Commands

```bash
# 1. Create GitHub Issue first (via GitHub website or gh CLI)
# Title: "Add GitHub Actions workflows for CI/CD with Nix"

# 2. Create and checkout feature branch
git checkout -b feature/github-workflows-5

# 3. Add workflow files
git add .github/workflows/
git add R/setup/dev_log.R

# 4. Check what will be committed
git status

# 5. Commit changes
git commit -m "Add GitHub Actions workflows for CI/CD with Nix

- Add tests-r-via-nix.yaml for running tests in Nix environment
- Add nix-builder.yaml for building and testing default.nix
- Add pkgdown.yaml for building and deploying documentation
- All workflows based on ropensci/rix examples
- Ensures reproducible builds across platforms

Fixes #5"

# 6. Push to remote and set upstream
git push -u origin feature/github-workflows-5

# 7. Create Pull Request (via GitHub website or gh CLI)
gh pr create --title "Add GitHub Actions workflows for CI/CD with Nix" \
  --body "## Overview
Adds three GitHub Actions workflows for CI/CD using Nix:

1. **R tests via Nix** - Runs devtools::test() in pure Nix environment
2. **Nix builder** - Validates default.nix builds correctly
3. **pkgdown site** - Builds and deploys package documentation

## Workflows Added

- tests-r-via-nix.yaml
- nix-builder.yaml
- pkgdown.yaml

All workflows based on ropensci/rix examples and adapted for randomwalk package.

## Testing

Workflows will be tested automatically when pushed.

Fixes #5"

# 8. After workflows pass, merge the PR
gh pr merge --squash

# 9. Clean up local branch
git checkout main
git pull origin main
git branch -d feature/github-workflows-5
```

## Workflow Details

### 1. tests-r-via-nix.yaml
- **Purpose**: Run R package tests in reproducible Nix environment
- **Platforms**: macOS-latest, Ubuntu-latest
- **Key Features**:
  - Uses cachix for faster builds
  - Runs `devtools::test(stop_on_failure = TRUE)`
  - Pure Nix environment ensures reproducibility

### 2. nix-builder.yaml
- **Purpose**: Validate Nix environment builds correctly
- **Platforms**: Ubuntu 22.04, macOS 14
- **Key Features**:
  - Runs `nix-build default.nix`
  - Verifies `nix-shell default.nix` works
  - Tests R version inside Nix shell

### 3. pkgdown.yaml
- **Purpose**: Build and deploy package documentation website
- **Platform**: Ubuntu-latest
- **Key Features**:
  - Builds package site with `pkgdown::build_site_github_pages()`
  - Deploys to `gh-pages` branch
  - Auto-deploys on pushes to main, PRs, and releases

## GitHub Pages Configuration

After the first successful pkgdown workflow run:

1. Go to repository Settings → Pages
2. Set Source to: Deploy from a branch
3. Select branch: `gh-pages`
4. Select folder: `/ (root)`
5. Click Save

Your package documentation will be available at:
`https://johngavin.github.io/randomwalk/`

## Additional Configuration (if needed)

### Enable GitHub Actions
If workflows don't trigger automatically:
1. Go to repository Settings → Actions → General
2. Set "Actions permissions" to "Allow all actions and reusable workflows"
3. Save changes

### Add Cachix Token (optional, for write access)
If you want to contribute to the rstats-on-nix cache:
1. Sign up at https://www.cachix.org/
2. Create a token
3. Add as repository secret: `CACHIX_AUTH`

## References

- Original workflows: https://github.com/ropensci/rix/tree/main/.github/workflows
- Context guidelines: `/Users/johngavin/docs_gh/claude_rix/context.md`
- Dev log: `R/setup/dev_log.R`
