# randomwalk Issues Grouped by Similarity and Difficulty

**Repository**: https://github.com/JohnGavin/randomwalk
**Total Open Issues**: 23 (4 new issues added 2025-12-05)
**Ordered**: Easiest → Hardest (within and between groups)

---

## Group A: Documentation & Website Fixes
**Theme**: Website content, badges, links, documentation cleanup

### A1. Fix README Badges and Links (#76, #77)
- **Issues**:
  - #76: Fix README badges and broken vignette links
  - #77: Fix #76: Add GitHub Actions badges and fix broken vignette links
- **Difficulty**: ⭐ Very Easy
- **Effort**: 30 minutes - 1 hour
- **Risk**: Very Low
- **Tasks**:
  - Add GitHub Actions status badges to README
  - Fix broken vignette/article links
  - Update pkgdown site links
- **Why easy**:
  - Markdown edits only
  - No code changes
  - Clear requirements

### A2. Fix Home Page Sections and Links (#86) 🆕
- **Difficulty**: ⭐⭐ Easy-Medium
- **Effort**: 1-2 hours
- **Risk**: Low
- **Tasks**:
  - Move "Wiki Guides" section to claude_rix wiki
  - Move "Additional Resources" section to claude_rix wiki
  - Remove development-specific content (default.nix references)
  - Update "Essential Documentation" section (remove outdated, keep relevant)
  - Add cross-reference to claude_rix wiki
- **Why easy-medium**:
  - Mostly content reorganization
  - Some wiki editing required
  - No code changes
  - Clear scope
- **Related**: Centralizes shared documentation in claude_rix wiki

### A3. Fix Missing Vignettes and Broken Links (#85) 🆕
- **Difficulty**: ⭐⭐ Easy-Medium
- **Effort**: 2-3 hours
- **Risk**: Low-Medium
- **Tasks**:
  - Investigate why nanonext broadcast vignette not appearing
  - Fix 404 errors (dashboard_async.html, dashboard.html)
  - Clarify inst/qmd/ vs vignettes/ location
  - Review CRAN/tidyverse vignette structure recommendations
  - Update _pkgdown.yml to include all vignettes
  - Verify all vignette links work
- **Why easy-medium**:
  - Requires investigation (why missing?)
  - pkgdown configuration
  - May need file reorganization
  - Testing required
- **Blockers**: Must fix before #87 (async wiki comparison)

---

## Group B: Build & CI/CD Infrastructure
**Theme**: Fixing build processes, CI/CD, automation

### B1. Fix Broken Vignette/Article Links (#67, #82)
- **Issues**:
  - #67: Fix: Broken vignette/article links on pkgdown site
  - #82: Fix #67: Enable article building in pkgdown workflow
- **Difficulty**: ⭐⭐ Easy-Medium
- **Effort**: 1-2 hours
- **Risk**: Low
- **Tasks**:
  - Enable article building in pkgdown
  - Fix article links in navigation
  - Update GitHub Actions workflow
  - Verify all links work
- **Why easy-medium**:
  - Mostly configuration changes
  - pkgdown settings well-documented
  - Can test locally
- **Related**: May overlap with #85 (both about vignette visibility)

### B2. Automate Nix File Regeneration (#78, #79)
- **Issues**:
  - #78: Automate nix file regeneration when DESCRIPTION changes
  - #79: Fix #78: Automate nix file regeneration with pre-commit hook
- **Difficulty**: ⭐⭐⭐ Medium
- **Effort**: 2-3 hours
- **Risk**: Medium
- **Tasks**:
  - Create pre-commit hook script
  - Detect DESCRIPTION changes
  - Auto-regenerate default.nix and package.nix
  - Test hook doesn't break workflow
  - Add to documentation
- **Why medium**:
  - Requires git hooks knowledge
  - Must handle edge cases (partial commits, merge conflicts)
  - Needs thorough testing
- **Related**: claude_rix #5 (generation strategy), #9 ($HOME escaping bug)

### B3. Enable Persistent Caching for targets (#69)
- **Difficulty**: ⭐⭐⭐ Medium
- **Effort**: 2-4 hours
- **Risk**: Medium
- **Tasks**:
  - Configure GitHub Actions cache for `_targets/`
  - Handle cache invalidation correctly
  - Test cache hit/miss scenarios
  - Measure speedup
  - Document caching strategy
- **Why medium**:
  - GitHub Actions caching can be tricky
  - Need to handle cache keys carefully
  - Must ensure cache doesn't cause stale data issues

---

## Group C: Code Organization & Configuration
**Theme**: Restructuring code, updating parameters, improving organization

### C1. Reorganize R/setup/ Files (#84)
- **Difficulty**: ⭐⭐ Easy-Medium
- **Effort**: 1-2 hours
- **Risk**: Low
- **Tasks**:
  - Create subfolders in R/setup/
  - Move files to appropriate subfolders
  - Update any references to moved files
  - Update documentation
- **Why easy-medium**:
  - Straightforward file operations
  - Low risk (git tracks moves)
  - Improves maintainability
- **Suggested structure**:
  ```
  R/setup/
  ├── issues/           # Issue-specific fixes
  ├── features/         # Feature development logs
  ├── maintenance/      # Routine maintenance
  └── experiments/      # Experimental code
  ```

### C2. Update Simulation Parameters (#88) 🆕
- **Difficulty**: ⭐⭐ Easy-Medium
- **Effort**: 2-3 hours
- **Risk**: Low
- **Tasks**:
  - Update default parameters in simulation functions
  - Change from: 50×50/10, 100×100/20, 200×200/50 walkers
  - Change to: 50×50/500, 50×50/2000, 100×100/6000 walkers
  - Update vignettes with new parameters
  - Update dashboard examples
  - Update targets pipeline if needed
  - Test execution times and memory usage
  - Update documentation and README
- **Why easy-medium**:
  - Simple parameter changes
  - Need to test performance impact
  - Multiple files to update (vignettes, dashboards, targets)
  - Should verify CI/CD timeouts still work
- **Benefits**:
  - More interesting visual patterns
  - Better demonstrates scalability
  - Clearer async/parallel performance benefits
  - Makes dashboards more engaging
- **Related**: #87 (async comparison will benefit from more walkers)

---

## Group D: Feature Enhancements - Dashboard
**Theme**: Improving dashboard functionality and UX

### D1. Improve Validation Visibility (#60, #61, #62)
- **Issues**:
  - #60: Enhancement: Improve validation visibility and control in dashboard
  - #61: Fix #60 (Solution 3): Change validation logging from TRACE to INFO level
  - #62: Fix #60 (Solution 1): Add validate_strict checkbox to dashboard UI
- **Difficulty**: ⭐⭐⭐ Medium
- **Effort**: 3-4 hours total
- **Risk**: Low-Medium
- **Tasks**:
  - D1.1: Change log level (⭐⭐ Easy, 30 min)
  - D1.2: Add UI checkbox (⭐⭐⭐ Medium, 2-3 hours)
  - Test validation modes
  - Update documentation
- **Why medium**:
  - D1.1 is simple (change log level)
  - D1.2 requires Shiny UI work
  - Both affect user experience

**Recommended order**: D1.1 first (quick win), then D1.2

### D2. Survival Curve Page (#56)
- **Difficulty**: ⭐⭐⭐ Medium
- **Effort**: 3-4 hours
- **Risk**: Low-Medium
- **Tasks**:
  - Calculate survival statistics
  - Create survival curve visualization
  - Add new dashboard tab/page
  - Integrate with existing simulation
  - Test with various parameters
- **Why medium**:
  - Statistical calculation needed
  - Visualization with ggplot2/plotly
  - Dashboard integration
  - Standard R/Shiny work

### D3. Non-blocking Event Display (#57)
- **Difficulty**: ⭐⭐⭐ Medium-Hard
- **Effort**: 3-5 hours
- **Risk**: Medium
- **Tasks**:
  - Implement reactive polling for latest stats
  - Ensure non-blocking updates
  - Handle race conditions
  - Test responsiveness
- **Why medium-hard**:
  - Requires understanding of reactive programming
  - Async complexity
  - Must avoid blocking main thread

### D4. Support Three Dashboard Versions (#68)
- **Difficulty**: ⭐⭐⭐⭐ Medium-Hard
- **Effort**: 4-6 hours
- **Risk**: Medium
- **Tasks**:
  - Create sync version (baseline)
  - Create async-pre-nanonext version
  - Create async-nanonext version
  - Add version selector UI
  - Document differences
  - Test all three versions
- **Why medium-hard**:
  - Three separate implementations
  - Need to maintain consistency
  - UI complexity for version switching
  - Testing effort increases

---

## Group E: Feature Enhancements - Core Functionality
**Theme**: Major new features, architectural changes

### E1. Dynamic Grid State Broadcasting (#51, #83)
- **Issues**:
  - #51: Feature: Dynamic grid state broadcasting with nanonext/mirai
  - #83: Implement Issue #51: Dynamic grid broadcasting (Phase 1)
- **Difficulty**: ⭐⭐⭐⭐⭐ Very Hard
- **Effort**: 10-20 hours (Phase 1: 6-8 hours)
- **Risk**: High
- **Tasks**:
  - Design broadcasting architecture
  - Implement with nanonext/mirai
  - Handle synchronization
  - Test performance at scale
  - Handle edge cases (dropped messages, ordering)
  - Document architecture
- **Why very hard**:
  - Complex distributed system design
  - Requires deep understanding of nanonext/mirai
  - Performance-critical
  - Many potential failure modes
  - Architectural impact on entire package

**Sub-phases**:
- Phase 1 (#83): Basic broadcasting (6-8 hours)
- Phase 2: Optimization and edge cases (4-6 hours)
- Phase 3: Production hardening (4-6 hours)

---

## Group F: Documentation & Educational Content
**Theme**: Vignettes, wikis, examples, teaching materials

### F1. Defensive Programming Examples (#66)
- **Difficulty**: ⭐⭐⭐ Medium
- **Effort**: 3-5 hours
- **Risk**: Low
- **Tasks**:
  - Identify defensive programming patterns in codebase
  - Write vignette with examples
  - Show before/after code
  - Document best practices
  - Add to pkgdown site
- **Why medium**:
  - Requires code review
  - Educational writing
  - Examples need to be clear
  - But no new features needed

### F2. Sync vs Async Comparison Vignette (#48, #59)
- **Issues**:
  - #48: Wiki: Show fractal similarity between workers=0 (sync) and workers=1 (async)
  - #59: Fix #48: Add sync vs async comparison vignette
- **Difficulty**: ⭐⭐⭐ Medium-Hard
- **Effort**: 4-6 hours
- **Risk**: Low-Medium
- **Tasks**:
  - Create comparison framework
  - Run benchmarks (sync vs async)
  - Create visualizations
  - Explain "fractal similarity" concept
  - Write clear explanations
  - Generate reproducible examples
- **Why medium-hard**:
  - Requires performance analysis
  - Complex concept to explain
  - Visualization challenging
  - Must be reproducible

### F3. Update Async Dashboard Wiki (#87) 🆕
- **Difficulty**: ⭐⭐⭐ Medium
- **Effort**: 3-4 hours
- **Risk**: Low
- **Tasks**:
  - Document both async vignettes (pre-nanonext and nanonext)
  - Add comprehensive compare/contrast section
  - Create comparison table (mechanism, performance, use cases)
  - Add cross-links between vignettes
  - Integrate with existing targets pipeline
  - Create examples showing differences
- **Why medium**:
  - Educational writing
  - Requires understanding both approaches
  - Need to create clear comparisons
  - Integration with targets
- **Dependencies**:
  - Requires #85 (nanonext vignette must be published first)
  - Complements F2 (sync vs async vignette)
  - Benefits from #88 (more walkers make differences clearer)

### F4. Targets Pipeline with Nested Parallelism (#50)
- **Difficulty**: ⭐⭐⭐⭐ Hard
- **Effort**: 6-8 hours
- **Risk**: Medium
- **Tasks**:
  - Design nested parallelism strategy
  - Create example pipeline
  - Document targets + mirai/nanonext interaction
  - Show performance benefits
  - Explain when to use nested parallelism
  - Provide troubleshooting tips
- **Why hard**:
  - Complex topic (nested parallelism is tricky)
  - Must understand targets deeply
  - Must understand mirai/nanonext deeply
  - Performance tuning needed
  - Easy to create anti-patterns

---

## Summary: Ordered by Overall Difficulty

### 1. Quick Wins (⭐ - 1-2 hours each)
- **A1**: Fix badges and links (#76, #77) - 30-60 min

### 2. Easy Tasks (⭐⭐ - 1-3 hours each)
- **A2**: Fix home page sections (#86) 🆕 - 1-2 hours
- **A3**: Fix missing vignettes (#85) 🆕 - 2-3 hours
- **B1**: Fix article links (#67, #82) - 1-2 hours
- **C1**: Reorganize R/setup/ (#84) - 1-2 hours
- **C2**: Update simulation parameters (#88) 🆕 - 2-3 hours
- **D1.1**: Change log level (#61) - 30 min

### 3. Medium Tasks (⭐⭐⭐ - 2-6 hours each)
- **B2**: Automate nix regeneration (#78, #79) - 2-3 hours
- **B3**: Enable targets caching (#69) - 2-4 hours
- **D1.2**: Add validation checkbox (#62) - 2-3 hours
- **D2**: Survival curve page (#56) - 3-4 hours
- **D3**: Non-blocking display (#57) - 3-5 hours
- **F1**: Defensive programming examples (#66) - 3-5 hours
- **F3**: Update async wiki (#87) 🆕 - 3-4 hours

### 4. Medium-Hard Tasks (⭐⭐⭐⭐ - 4-8 hours each)
- **D4**: Three dashboard versions (#68) - 4-6 hours
- **F2**: Sync vs async vignette (#48, #59) - 4-6 hours
- **F4**: Nested parallelism vignette (#50) - 6-8 hours

### 5. Hard Tasks (⭐⭐⭐⭐⭐ - 10-20 hours)
- **E1**: Dynamic grid broadcasting (#51, #83) - 10-20 hours

---

## Recommended Implementation Order

### Phase 1: Quick Wins & Website Fixes (6-10 hours)
```
1. A1  - Fix badges/links (#76, #77)          1 hour      ⭐
2. A2  - Fix home page sections (#86) 🆕      2 hours     ⭐⭐
3. B1  - Fix article links (#67, #82)         2 hours     ⭐⭐
4. A3  - Fix missing vignettes (#85) 🆕       3 hours     ⭐⭐
5. C1  - Reorganize R/setup/ (#84)            2 hours     ⭐⭐
6. D1.1- Change log level (#61)               30 min      ⭐⭐
```

**Why first**:
- Low-hanging fruit
- Improves website quality immediately
- Sets up infrastructure for later work
- A3 must be done before F3 (async wiki needs vignettes visible)

### Phase 2: Configuration & Build Automation (6-10 hours)
```
7. C2 - Update simulation parameters (#88) 🆕 3 hours     ⭐⭐
8. B2 - Automate nix regen (#78, #79)         3 hours     ⭐⭐⭐
9. B3 - Enable caching (#69)                  4 hours     ⭐⭐⭐
```

**Why second**:
- C2 makes examples more impressive (do early)
- Improves developer workflow
- Speeds up CI/CD for remaining work

### Phase 3: Dashboard Enhancements (10-16 hours)
```
10. D1.2 - Validation checkbox (#62)          3 hours     ⭐⭐⭐
11. D2   - Survival curve (#56)               4 hours     ⭐⭐⭐
12. D3   - Non-blocking display (#57)         4 hours     ⭐⭐⭐
13. D4   - Three versions (#68)               6 hours     ⭐⭐⭐⭐
```

**Why third**:
- User-facing improvements
- Measurable UX impact
- Benefits from C2 (more interesting with more walkers)

### Phase 4: Documentation & Examples (14-21 hours)
```
14. F1 - Defensive programming (#66)          4 hours     ⭐⭐⭐
15. F3 - Update async wiki (#87) 🆕           4 hours     ⭐⭐⭐
16. F2 - Sync vs async vignette (#48, #59)    6 hours     ⭐⭐⭐⭐
17. F4 - Nested parallelism (#50)             8 hours     ⭐⭐⭐⭐
```

**Why fourth**:
- Educational value
- Helps users understand package
- F3 requires A3 complete (vignettes visible)
- F3 and F2 complement each other

### Phase 5: Major Feature (10-20 hours)
```
18. E1 - Dynamic broadcasting (#51, #83)      15 hours    ⭐⭐⭐⭐⭐
    - Phase 1: Basic implementation           8 hours
    - Phase 2: Optimization                   4 hours
    - Phase 3: Hardening                      3 hours
```

**Why last**:
- Most complex
- Requires all other infrastructure in place
- Benefits from B2, B3 for efficient testing

---

## Effort vs Impact Matrix

```
High Impact ↑
           │
        E1 │ C2              ← Critical features
           │
        B2,│ D1.2, D2        ← Medium priority
        B3 │
           │
        A1,│ A2, A3, B1,     ← Quick wins!
        C1 │ D1.1
           │ F1, F2, F3, F4  ← Educational
           │
        D3,│ D4              ← Lower priority
           │
Low Impact │
           └─────────────────→ High Effort
         Low Effort
```

---

## Dependencies Between Tasks

```
A1 (badges) ← Independent
A2 (home page) ← Independent
A3 (vignettes) → F3 (async wiki) ← BLOCKS: F3 needs vignettes visible
B1 (articles) ← Independent (may overlap with A3)
C1 (organize) ← Independent
C2 (parameters) ← Independent (but helps D4, F2, F3 look better)

B2 (nix automation) ← Helps B3
B3 (caching) ← Helps all development

D1.1 (log level) → D1.2 (checkbox) ← Sequence
D2 (survival) ← Independent (benefits from C2)
D3 (non-blocking) ← Independent
D4 (versions) ← Needs D1 complete

F1 (defensive) ← Independent
F2 (sync/async) ← Benefits from C2 (more walkers show differences)
F3 (async wiki) ← Requires A3 (vignettes visible), benefits from C2
F4 (nested) ← Builds on F2/F3

E1 (broadcasting) ← Needs B2, B3 for efficient testing
```

---

## Total Effort Summary

| Phase | Tasks | Effort | Risk | Priority |
|-------|-------|--------|------|----------|
| **Quick Wins** | 6 tasks | 6-10 hours | Low | High |
| **Configuration** | 3 tasks | 6-10 hours | Medium | High |
| **Dashboard** | 4 tasks | 10-16 hours | Low-Medium | Medium |
| **Documentation** | 4 tasks | 14-21 hours | Low | Medium |
| **Major Feature** | 1 task | 10-20 hours | High | Medium |
| **TOTAL** | **18 tasks (23 issues)** | **46-77 hours** | Mixed | - |

---

## Risk Assessment

### Low Risk (Can Complete Quickly)
- A1, A2, B1, C1, C2, D1.1, D2, F1, F3

### Medium Risk (Test Carefully)
- A3, B2, B3, D1.2, D3, D4, F2, F4

### High Risk (Requires Deep Expertise)
- E1 (dynamic broadcasting)

---

## Grouping Summary

| Group | Theme | Issues | Difficulty | Total Effort |
|-------|-------|--------|------------|--------------|
| **A** | Documentation/Website | 3 (+1🆕) | ⭐-⭐⭐ | 4-6 hours |
| **B** | Build/CI | 3 | ⭐⭐-⭐⭐⭐ | 5-9 hours |
| **C** | Organization/Config | 2 (+1🆕) | ⭐⭐ | 3-5 hours |
| **D** | Dashboard Features | 4 | ⭐⭐⭐-⭐⭐⭐⭐ | 10-18 hours |
| **E** | Core Features | 2 | ⭐⭐⭐⭐⭐ | 10-20 hours |
| **F** | Educational | 4 (+1🆕) | ⭐⭐⭐-⭐⭐⭐⭐ | 16-23 hours |

---

## What's New (2025-12-05)

🆕 **4 New Issues Added**:

1. **#85** (A3): Fix missing vignettes and broken links - Critical for website quality
2. **#86** (A2): Fix home page sections - Improves documentation organization
3. **#87** (F3): Update async dashboard wiki - Comprehensive comparison of async approaches
4. **#88** (C2): Update simulation parameters - More impressive demonstrations

**Impact**:
- Total effort increased from 39-65 hours → 46-77 hours
- Added ~7-12 hours of work
- All new issues are Low-Medium risk
- Phase 1 expanded with more quick wins
- Documentation phase strengthened

**Key Dependencies**:
- #85 (A3) BLOCKS #87 (F3) - vignettes must be visible before wiki can reference them
- #88 (C2) ENHANCES #87, F2, D4 - more walkers make demonstrations more impressive

---

**Last Updated**: 2025-12-05
**Status**: 23 open issues (4 new), 0 completed during this session
**Estimated Total**: 46-77 hours of development work
**Realistic Timeline**: 2-3 weeks of focused development

---

## Next Steps Recommendation

**Start with Phase 1** (Quick Wins & Website Fixes):
1. These are low-risk, high-visibility improvements
2. Sets up infrastructure for later phases
3. Improves user experience immediately
4. Resolves blocking dependencies (A3 needed for F3)

**Then tackle C2** (simulation parameters) early in Phase 2:
- Makes all dashboards and vignettes more impressive
- Benefits multiple later tasks
- Simple change with high impact
