# Issues Grouped by Similarity and Difficulty

**Last Updated**: 2025-12-09
**Total Open Issues**: 30 (includes issue #121 created today)
**Open PRs**: 11

---

## 📋 **Group A: Documentation & Wiki Content**
*Purpose: Improve written documentation, reduce duplication, maintain wiki*

### Easy (< 1 hour)
1. **#116** - Duplicate telemetry.qmd in inst/qmd and vignettes *(has PR #119)*
2. **#95** - Review excessive HTML files in ./docs/
3. **#66** - Highlight defensive programming examples in wiki

### Medium (1-3 hours)
4. **#96** - Update README with nanonext examples + nix shell instructions
5. **#86** - Home page sections and wiki links need updating *(has PR #90)*
6. **#76** - Fix README badges and broken vignette links *(has PR #77)*
7. **#48** - Wiki: Show fractal similarity workers=0 vs workers=1 *(has PR #59)*

### Hard (3-6 hours)
8. **#89** - Document Dynamic Broadcasting Algorithm in Wiki/Vignette
9. **#87** - Update async dashboard wiki with comprehensive comparison

---

## 🎨 **Group B: Vignettes & Articles (HTML Content)**
*Purpose: Fix/create vignette HTML and embedded Shinylive apps*

### Easy (< 1 hour)
1. **#117** - vignettes/dynamic_broadcasting.html content mismatch

### Medium (1-3 hours)
2. **#101** - Fix dynamic_broadcasting.html content (should show r-shinylive app)
3. **#118** - Shinylive App Not Running in dashboard.html (embed-resources issue)

### Hard (3-6 hours)
4. **#103** - Restore embedded Shinylive app in dashboard.html
5. **#85** - Missing vignettes and broken links on pkgdown site
6. **#82** - Enable article building in pkgdown workflow *(PR)*

### Very Hard (6+ hours)
7. **#50** - Vignette: Create targets pipeline with nested parallelism
8. **#121** - Implementation Plan: Fix Website Rebuild & Vignette Deployment *(NEW)*

---

## 📊 **Group C: Dashboard Features & Enhancements**
*Purpose: Improve interactive dashboard functionality*

### Easy (< 1 hour)
1. **#102** - Fix 404 on dashboard_async URL
2. **#60** - Improve validation visibility and control *(has PR #61, #62)*

### Medium (1-3 hours)
3. **#88** - Update simulation parameters to demonstrate scalability
4. **#57** - Non-blocking event display latest statistics

### Hard (3-6 hours)
5. **#56** - Page for survival curve for steps to event

### Very Hard (6+ hours)
6. **#68** - Support three dashboard versions (sync, async-pre-nanonext, async-nanonext)

---

## 🔧 **Group D: CI/CD & Build Performance**
*Purpose: Optimize GitHub Actions, fix caching, improve build times*

### Easy (< 1 hour)
1. **#78** - Automate nix file regeneration when DESCRIPTION changes *(has PR #79)*

### Hard (3-6 hours)
2. **#111** - **CRITICAL**: CI Failures in R-CMD-check and pkgdown Workflows
3. **#92** - CI/CD Rebuilding Environment - Not Using johngavin Cachix *(has PR #93)*
4. **#69** - Enable persistent caching for targets in CI/CD

### Very Hard (6+ hours)
5. **#91** - Optimize CI/CD Build Times: Reduce from 20 min to 5-8 min
6. **#109** - Optimize Nix CI workflow with caching and timeouts *(PR)*

---

## 🗂️ **Group E: Repository Organization & PR Management**
*Purpose: Clean up repo structure, manage open PRs, reduce clutter*

### Easy (< 1 hour)
1. **#84** - Reorganize R/setup/ files into subfolders

### Hard (3-6 hours)
2. **#115** - **Rationalize and Consolidate Open Pull Requests** *(11 open PRs need review)*

---

## 🔥 **Quick Wins** (Do First - High Impact, Low Effort)

Priority order:
1. **#116** - Remove duplicate telemetry.qmd (15 min) → Merge PR #119
2. **#102** - Fix dashboard_async 404 (30 min)
3. **#117** - Verify dynamic_broadcasting.html content (30 min)
4. **#95** - Clean up excessive HTML files (1 hour)
5. **#78** - Automate nix file regeneration (30 min) → Merge PR #79

**Total Time**: ~3 hours for 5 issues ✅

---

## 🚨 **Critical Path** (Must Fix for Stability)

These issues block other work or cause CI/CD failures:

1. **#111** - CI Failures (BLOCKING) - Fix R-CMD-check and pkgdown workflows
2. **#92** - Cachix not working (EXPENSIVE) - Wasting 18+ min per build
3. **#115** - Too many open PRs (NOISE) - 11 PRs need decisions

**Estimated**: 1 day to resolve all three

---

## 📈 **Feature Development** (After Critical Path Cleared)

### Phase 1: Complete Current Features (1-2 days)
- #50 - Targets nested parallelism vignette
- #68 - Three dashboard versions
- #87 - Async dashboard wiki comparison

### Phase 2: Analysis & Visualization (1 day)
- #56 - Survival curve analysis
- #57 - Non-blocking statistics display
- #48 - Fractal similarity analysis

### Phase 3: Documentation (1 day)
- #89 - Dynamic broadcasting algorithm docs
- #66 - Defensive programming examples
- #96 - README updates with nanonext examples

---

## 📊 **Summary Statistics**

| Difficulty | Count | Est. Time | Priority |
|------------|-------|-----------|----------|
| Very Easy (< 1h) | 8 | 6 hours | High |
| Medium (1-3h) | 9 | 18 hours | Medium |
| Hard (3-6h) | 8 | 36 hours | Medium-Low |
| Very Hard (6+h) | 5 | 40+ hours | Low |

**Total**: 30 issues, ~100 hours of work

---

## 🎯 **Recommended Work Order**

### Week 1: Stabilization
1. Quick Wins (#116, #102, #117, #95, #78) - 3 hours
2. Critical Path (#111, #92, #115) - 1 day
3. Vignette Deployment (#121, #85) - 4 hours

### Week 2: Feature Completion
4. Dashboard Features (#60, #88, #57, #56) - 1.5 days
5. Documentation (#96, #86, #76, #66) - 1 day

### Week 3: Advanced Features (Optional)
6. Advanced Vignettes (#50, #68) - 2 days
7. Wiki Content (#48, #87, #89) - 1 day

---

## 📝 **Notes**

**Consolidation (2025-12-09)**:
- ✅ Removed duplicate files: PROJECT_INFO.md, ISSUES_GROUPED.md, STARTUP.md
- ✅ Created issue #121 from STARTUP.md detailed plan
- ✅ This file now serves as canonical issue reference
- ✅ Archive/ folder contains historical documentation
- 🔗 Detailed topics moved to [randomwalk wiki](https://github.com/JohnGavin/randomwalk/wiki)

**PR Management**:
11 open PRs need review (see #115):
- #119, #120, #109, #93, #90, #82, #79, #77, #62, #61, #59

Many PRs address parent issues and can be merged once CI passes.
