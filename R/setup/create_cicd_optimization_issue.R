# Create GitHub Issue for CI/CD Build Optimization
# Reduce nix build times from ~20 min to ~5-8 min

library(gh)

issue <- gh("POST /repos/JohnGavin/randomwalk/issues",
  title = "Optimize CI/CD Build Times: Reduce from 20 min to 5-8 min",
  body = "## Problem

Current CI/CD builds take ~20 minutes vs ~2 minutes for simpler projects like statues_named_john (10x slower).

**Root causes:**
1. **nanonext** - C library requiring compilation (~5-10 min)
2. **crew** - Complex async framework (~2-3 min)
3. **Many Suggests packages** - All installed for R CMD check (~3-5 min)

## Goal

Reduce build time from ~20 min to ~5-8 min (60-75% improvement).

## Solution 1: Split Suggests into Categories

**Current (slow):**
```
Suggests:
    dplyr, duckdb, shiny, shinylive, targets,    # Runtime
    devtools, usethis, pkgdown, covr,           # Dev-only
    testthat, shinytest2                         # Testing
```

**Proposed (fast):**

Create separate nix configurations:

### `default-ci.nix` (CI/CD - minimal)
- Imports only (required packages)
- Suggests: runtime + testing only
- Skip: devtools, usethis, pkgdown, covr

### `default-dev.nix` (Local development - complete)
- All Imports
- All Suggests (including dev tools)

### `default.nix` (Symlink)
- Local dev: `ln -s default-dev.nix default.nix`
- CI/CD uses: `default-ci.nix` explicitly

**Expected savings:** ~2-3 minutes

## Solution 2: Cachix Layering Strategy

**Current:** CI/CD builds nanonext/crew from source every time

**Proposed:**

### 2.1 Pre-populate johngavin Cachix

Create one-time setup job to push commonly-used packages:

```bash
# .github/workflows/cachix-prepopulate.yml (manual trigger)
nix-build -E 'with import <nixpkgs> {}; rPackages.nanonext'
nix-store -qR result | cachix push johngavin

nix-build -E 'with import <nixpkgs> {}; rPackages.crew'
nix-store -qR result | cachix push johngavin
```

### 2.2 Update Workflow to Use Layered Cache

```yaml
# .github/workflows/R-CMD-check.yml
- uses: cachix/cachix-action@v12
  with:
    name: johngavin
    authToken: \\${{ secrets.CACHIX_AUTH_TOKEN }}

# Nix will automatically check:
# 1. johngavin cachix (our packages) <- FAST!
# 2. rstats-on-nix (R packages)
# 3. cache.nixos.org (system packages)
```

**Expected savings:** ~5-10 minutes (biggest impact!)

## Solution 3: Optimize GitHub Actions

### 3.1 Separate Pre-build Job

Create a reusable workflow for expensive packages:

```yaml
# .github/workflows/prebuild-deps.yml
name: Pre-build Dependencies

on:
  workflow_dispatch:  # Manual trigger
  schedule:
    - cron: '0 0 * * 0'  # Weekly on Sunday

jobs:
  prebuild:
    runs-on: ubuntu-latest
    steps:
      - uses: cachix/install-nix-action@v20
      - uses: cachix/cachix-action@v12
        with:
          name: johngavin
          authToken: \\${{ secrets.CACHIX_AUTH_TOKEN }}

      - name: Build nanonext
        run: |
          nix-build -E 'with import <nixpkgs> {}; rPackages.nanonext'
          nix-store -qR result | cachix push johngavin

      - name: Build crew
        run: |
          nix-build -E 'with import <nixpkgs> {}; rPackages.crew'
          nix-store -qR result | cachix push johngavin
```

### 3.2 Cache Nix Store Paths

Add to main workflow:

```yaml
- name: Cache Nix store paths
  uses: actions/cache@v3
  with:
    path: /nix/store
    key: nix-\\${{ runner.os }}-\\${{ hashFiles('default-ci.nix') }}
    restore-keys: |
      nix-\\${{ runner.os }}-
```

**Expected savings:** ~2-3 minutes

## Implementation Plan

### Phase 1: Cachix Pre-population (Immediate, 1 hour)
- [ ] Create `.github/workflows/cachix-prepopulate.yml`
- [ ] Manually trigger workflow to populate cache
- [ ] Verify nanonext/crew in johngavin cachix
- [ ] **Expected: 5-10 min savings immediately**

### Phase 2: Split Suggests (2-3 hours)
- [ ] Create `default-ci.nix` (minimal Suggests)
- [ ] Create `default-dev.nix` (full Suggests)
- [ ] Update `R/setup/generate_nix_files.R` to generate both
- [ ] Update workflows to use `default-ci.nix`
- [ ] Test locally with both configs
- [ ] **Expected: 2-3 min additional savings**

### Phase 3: GitHub Actions Optimization (2-3 hours)
- [ ] Add Nix store path caching
- [ ] Create separate pre-build job
- [ ] Set up weekly pre-build schedule
- [ ] Document workflow
- [ ] **Expected: 2-3 min additional savings**

## Success Metrics

**Before:**
- CI/CD time: ~20 minutes
- Cache hit rate: ~30%

**After:**
- CI/CD time: ~5-8 minutes (60-75% improvement)
- Cache hit rate: ~90%

## Priority

**High** - Significant developer experience improvement
- Faster feedback on PRs
- Lower GitHub Actions costs
- More iterations per hour

## Related

- Workflow improvements (Group B in ISSUES_GROUPED.md)
- Step 5 of 9-step workflow (push to cachix)
- NIX_WORKFLOW.md documentation

## References

- [Cachix Documentation](https://docs.cachix.org/)
- [Nix Store Optimization](https://nixos.wiki/wiki/Storage_optimization)
- [GitHub Actions Caching](https://docs.github.com/en/actions/using-workflows/caching-dependencies-to-speed-up-workflows)
",
  labels = list("optimization", "ci-cd", "nix", "cachix", "high-priority")
)

cat("Created issue:", issue$number, "\n")
cat("URL:", issue$html_url, "\n")
