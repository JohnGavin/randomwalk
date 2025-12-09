# CRITICAL: pkgdown + Quarto + Nix Workflow

**Created**: 2025-12-09
**Why**: Prevent recurring bslib/Nix errors in GitHub Actions

---

## 🚨 **THE FUNDAMENTAL INCOMPATIBILITY**

```
Nix + pkgdown + Quarto + bslib = IMPOSSIBLE
```

**Why it fails:**
1. Quarto vignettes require Bootstrap 5
2. Bootstrap 5 requires bslib R package
3. bslib must copy JS/CSS files at runtime
4. Nix `/nix/store` is **read-only** by design
5. bslib tries to write → **ERROR** → CI fails

**This cannot be fixed** - these are immutable constraints.

---

## ✅ **THE ONLY SOLUTION: Build Locally, Deploy Remotely**

### **Workflow Summary**

```
LOCAL (Nix)                     GITHUB ACTIONS
┌──────────────────┐           ┌──────────────────┐
│ 1. tar_make()    │           │ 1. Checkout repo │
│    builds all    │  ─push──▶ │                  │
│ 2. Commit docs/  │           │ 2. Deploy docs/  │
│                  │           │    to gh-pages   │
└──────────────────┘           └──────────────────┘
  20min first run                 30 seconds
  2min cached run
```

### **Step-by-Step Implementation**

#### **1. Local: Create Targets Plan (_targets.R)**

```r
library(targets)
library(tarchetypes)

tar_option_set(packages = c("randomwalk", "pkgdown", "quarto"))

list(
  # Pre-build ALL vignettes
  tar_quarto(dashboard, "vignettes/dashboard.qmd"),
  tar_quarto(dashboard_async, "vignettes/dashboard_async.qmd"),
  tar_quarto(dynamic_broadcasting, "vignettes/dynamic_broadcasting.qmd"),
  tar_quarto(telemetry, "vignettes/telemetry.qmd"),

  # Build COMPLETE pkgdown site
  tar_target(
    pkgdown_site,
    {
      pkgdown::build_site()
      "docs/"
    },
    format = "file"
  )
)
```

#### **2. Local: Build TWICE (Verify Caching)**

```bash
# First run: Build from source
START1=$(date +%s)
Rscript -e "targets::tar_make()"
END1=$(date +%s)
TIME1=$((END1 - START1))
echo "✅ First run: ${TIME1}s (~$((TIME1/60))m)"

# Second run: From cache (should be FAST)
rm -rf _targets/scratch  # Optional
START2=$(date +%s)
Rscript -e "targets::tar_make()"
END2=$(date +%s)
TIME2=$((END2 - START2))
echo "✅ Second run: ${TIME2}s (~$((TIME2/60))m)"

# DISPLAY SPEEDUP (required!)
SPEEDUP=$((100 - (TIME2 * 100 / TIME1)))
echo "🚀 Speedup: ${SPEEDUP}% (${TIME1}s → ${TIME2}s)"
```

**Expected output:**
```
✅ First run: 1200s (~20m)
✅ Second run: 120s (~2m)
🚀 Speedup: 90% (1200s → 120s)
```

#### **3. Local: Commit Built Artifacts**

```r
# Commit EVERYTHING built by targets
gert::git_add(c(
  "vignettes/*.html",        # Pre-built vignette HTML
  "vignettes/*_files/",      # Vignette assets (Shinylive, etc.)
  "docs/",                   # ENTIRE website
  "_targets.R",              # Targets plan
  "_targets/meta/meta"       # Targets metadata (optional)
))

gert::git_commit("Build: Pre-build website locally for GitHub Pages

- Built with targets::tar_make() in Nix environment
- First run: XXXs, Second run: YYYs (ZZ% speedup)
- Committed docs/ directory for deployment
- GitHub Actions will only deploy, not build

Fixes recurring bslib/Nix incompatibility in CI/CD")
```

#### **4. Local: Push to Cachix FIRST**

```bash
# MANDATORY Step 5 of 9-step workflow
../push_to_cachix.sh
```

#### **5. Local: Push to GitHub**

```r
usethis::pr_push()
```

#### **6. GitHub: Simple Deployment Workflow**

**File:** `.github/workflows/deploy-pages.yaml`

```yaml
name: Deploy to GitHub Pages

on:
  push:
    branches: [main]

permissions:
  contents: read
  pages: write
  id-token: write

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      # NO BUILD - Pre-built locally!
      # NO NIX - Not needed!
      # NO QUARTO - Already rendered!
      # NO BSLIB - No runtime file copying!

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v2
        with:
          path: 'docs'

      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v2
```

**Time:** ~30 seconds (no build, just deploy)

---

## ⚠️ **CRITICAL: What NOT to Do**

### ❌ **DON'T: Build on GitHub Actions**

```yaml
# ❌ THIS WILL FAIL
- name: Build pkgdown site
  run: |
    nix-shell default-ci.nix --run "Rscript -e 'pkgdown::build_site()'"
# ERROR: bslib cannot write to /nix/store
```

### ❌ **DON'T: Use native R in GitHub Actions**

```yaml
# ❌ THIS BREAKS REPRODUCIBILITY
- uses: r-lib/actions/setup-r@v2
- run: Rscript -e "pkgdown::build_site()"
# Different R version, different package versions, not reproducible!
```

### ❌ **DON'T: Try to "fix" bslib permissions**

```yaml
# ❌ IMPOSSIBLE - Nix store is read-only by design
- run: chmod +w /nix/store/...  # Won't work
- run: R_LIBS_USER=/tmp ...      # Workaround breaks Nix purity
```

---

## ✅ **WHY This Workflow Works**

| Aspect | Local Build | GitHub Deploy |
|--------|-------------|---------------|
| **Environment** | Nix (reproducible) | None needed |
| **Build time** | 20m first, 2m cached | 0m (no build) |
| **CI time** | N/A | 30 seconds |
| **Errors** | None (bslib works locally) | None (just copy files) |
| **Reproducible** | ✅ Nix + targets | ✅ Bit-identical |

---

## 📋 **Checklist for Future Updates**

When updating vignettes or website:

- [ ] Update .qmd source files
- [ ] Run `targets::tar_make()` TWICE
- [ ] Log speedup (first run → second run)
- [ ] Verify docs/ directory updated
- [ ] Commit vignettes/*.html
- [ ] Commit vignettes/*_files/
- [ ] Commit docs/ directory
- [ ] Push to cachix
- [ ] Push to GitHub
- [ ] Wait for deployment (~30 sec)
- [ ] Verify website at https://johngavin.github.io/randomwalk/

---

## 🔗 **Related Documentation**

- **9-Step Workflow:** `~/.claude/CLAUDE_STREAMLINED.md` (Step 5: cachix)
- **Targets Documentation:** https://docs.ropensci.org/targets/
- **GitHub Pages:** https://docs.github.com/en/pages
- **Issue #121:** Implementation plan for vignette deployment

---

## 📝 **Error Prevention**

**If you see this error in GitHub Actions:**
```
Error in find.package(...) : there are no packages called 'randomwalk', 'webr'
Error running 'Rscript' command. Perhaps you need to install / update the 'shinylive' R package?
```

**Or this error:**
```
cannot create directory '/nix/store/.../bslib/...'
Permission denied
```

**Then you violated this workflow!**
- ❌ You tried to build on GitHub Actions
- ✅ You must build locally with targets
- ✅ You must commit docs/ directory
- ✅ GitHub just deploys, never builds

---

**Last Updated:** 2025-12-09
**Applies To:** All projects using Nix + pkgdown + Quarto + bslib
**Status:** Mandatory workflow - no exceptions
