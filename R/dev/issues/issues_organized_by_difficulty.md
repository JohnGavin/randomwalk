# GitHub Issues Organized by Similarity and Difficulty
Generated: 2025-12-27

**Total Open Issues: 27**

Issues grouped by topic/theme, ordered by difficulty (easiest first, hardest last within each group).
Groups ordered from easiest overall to hardest overall.

---

## Group 1: Documentation (8 issues)
**Theme**: Writing, updating, and improving documentation
**Overall Difficulty**: Easy to Medium

### Easy
1. **#76** - Fix README badges and broken vignette links
   - **Difficulty**: ⭐ Easy
   - **Effort**: 15-30 min
   - **Type**: Fix broken links and update badges

2. **#86** - Fix: Home page sections and wiki links need updating
   - **Difficulty**: ⭐ Easy
   - **Effort**: 30 min - 1 hour
   - **Type**: Update content, fix links

### Easy-Medium
3. **#66** - defensive programming examples
   - **Difficulty**: ⭐⭐ Easy-Medium
   - **Effort**: 1-2 hours
   - **Type**: Write code examples with explanations

4. **#96** - DOCS: Update README with nanonext examples and nix shell instructions
   - **Difficulty**: ⭐⭐ Medium
   - **Effort**: 2-3 hours
   - **Type**: Write comprehensive documentation
   - **Labels**: documentation, nix, examples, nanonext

### Medium
5. **#87** - Enhancement: Update async dashboard wiki with comprehensive comparison
   - **Difficulty**: ⭐⭐ Medium
   - **Effort**: 3-4 hours
   - **Type**: Comprehensive comparison documentation

6. **#50** - Vignette: Create targets pipeline example with nested parallelism
   - **Difficulty**: ⭐⭐ Medium
   - **Effort**: 4-6 hours
   - **Type**: Write complete vignette with working code

7. **#56** - Page for survival curve for number of steps to event (end state)
   - **Difficulty**: ⭐⭐ Medium
   - **Effort**: 4-6 hours
   - **Type**: Create new analysis vignette page

### Medium-Hard
8. **#89** - Document Dynamic Broadcasting Algorithm in Wiki/Vignette
   - **Difficulty**: ⭐⭐⭐ Medium-Hard
   - **Effort**: 6-8 hours
   - **Type**: Deep technical documentation
   - **Labels**: documentation, wiki, vignette, Group E

---

## Group 2: Code Organization & Workflow (2 issues)
**Theme**: Project organization and process documentation
**Overall Difficulty**: Easy

### Easy
9. **#84** - Chore: Reorganize R/setup/ files into subfolders
   - **Difficulty**: ⭐ Easy
   - **Effort**: 30 min - 1 hour
   - **Type**: Move files, update imports

10. **#131** - Retrospective: Workflow violation - WASM async investigation (2025-12-15)
    - **Difficulty**: ⭐ Easy
    - **Effort**: 1 hour
    - **Type**: Document what happened and lessons learned

---

## Group 3: Configuration & Parameters (2 issues)
**Theme**: Adjusting simulation parameters for performance
**Overall Difficulty**: Easy-Medium

### Easy-Medium
11. **#124** - Optimize vignette simulation parameters to reduce local testing time
    - **Difficulty**: ⭐⭐ Easy-Medium
    - **Effort**: 1-2 hours
    - **Type**: Test and adjust parameters for faster local builds

### Medium
12. **#88** - Enhancement: Update simulation parameters to demonstrate scalability
    - **Difficulty**: ⭐⭐ Medium
    - **Effort**: 2-3 hours
    - **Type**: Test various parameter combinations

---

## Group 4: Pkgdown/Website (1 issue)
**Theme**: Website configuration and deployment
**Overall Difficulty**: Medium

### Medium
13. **#85** - Fix: Missing vignettes and broken links on pkgdown site
    - **Difficulty**: ⭐⭐ Medium
    - **Effort**: 2-3 hours
    - **Type**: Configure _pkgdown.yml, fix navigation

---

## Group 5: Shinylive/Dashboard Issues (4 issues)
**Theme**: Dashboard functionality and Shinylive embedding
**Overall Difficulty**: Medium to Medium-Hard

### Medium
14. **#60** - Enhancement: Improve validation visibility and control in dashboard
    - **Difficulty**: ⭐⭐ Medium
    - **Effort**: 3-4 hours
    - **Type**: Add UI controls and visual feedback

15. **#57** - Non-blocking event should display the latest statistics as soon as it is computed
    - **Difficulty**: ⭐⭐ Medium
    - **Effort**: 3-4 hours
    - **Type**: Implement reactive programming pattern

### Medium-Hard
16. **#103** - Restore embedded Shinylive app in dashboard.html
    - **Difficulty**: ⭐⭐⭐ Medium-Hard
    - **Effort**: 4-6 hours
    - **Type**: Fix Shinylive embedding configuration

17. **#118** - Shinylive App Not Running in dashboard.html (embed-resources: false already set)
    - **Difficulty**: ⭐⭐⭐ Medium-Hard
    - **Effort**: 4-6 hours
    - **Type**: Debug Shinylive execution issues

---

## Group 6: Nix Environment (2 issues)
**Theme**: Nix environment setup and automation
**Overall Difficulty**: Medium-Hard

### Medium-Hard
18. **#78** - Automate nix file regeneration when DESCRIPTION changes
    - **Difficulty**: ⭐⭐⭐ Medium-Hard
    - **Effort**: 4-6 hours
    - **Type**: Create automation script/hook

19. **#138** - Add shell.nix for users (non-developers) to use randomwalk
    - **Difficulty**: ⭐⭐⭐ Medium-Hard
    - **Effort**: 4-6 hours
    - **Type**: Create user-friendly Nix configuration

---

## Group 7: CI/CD & Build (3 issues)
**Theme**: Continuous integration and deployment optimization
**Overall Difficulty**: Hard

### Hard
20. **#69** - Enable persistent caching for targets in CI/CD
    - **Difficulty**: ⭐⭐⭐⭐ Hard
    - **Effort**: 6-8 hours
    - **Type**: Configure CI caching for targets pipeline

21. **#121** - Implementation Plan: Fix Website Rebuild & Pre-built Vignette Deployment
    - **Difficulty**: ⭐⭐⭐⭐ Hard
    - **Effort**: 8-12 hours
    - **Type**: Redesign CI/CD workflow

22. **#91** - Optimize CI/CD Build Times: Reduce from 20 min to 5-8 min
    - **Difficulty**: ⭐⭐⭐⭐ Hard
    - **Effort**: 8-12 hours
    - **Type**: Performance profiling and optimization
    - **Labels**: ci-cd, optimization, nix, cachix, high-priority

---

## Group 8: WebR/WASM (3 issues)
**Theme**: WebAssembly compilation and WebR compatibility
**Overall Difficulty**: Medium to Very Hard

### Medium (In Progress)
23. **#157** - Isolated pixels appearing in dashboard_comprehensive.html grid plot
    - **Difficulty**: ⭐⭐ Medium
    - **Effort**: Already addressed
    - **Type**: WebR reactive timing bug
    - **Status**: PR #158 ready to merge

24. **#158** - Fix Issue #157: Add WebR isolated pixels diagnostics and defensive validation
    - **Difficulty**: ⭐⭐ Medium
    - **Effort**: Completed
    - **Type**: Defensive validation and diagnostics
    - **Status**: PR ready to merge

### Very Hard
25. **#155** - Build compatible mirai + nanonext WASM packages in CI
    - **Difficulty**: ⭐⭐⭐⭐⭐ Very Hard
    - **Effort**: 20+ hours
    - **Type**: WASM compilation, C dependencies
    - **Labels**: enhancement, webr, ci
    - **Blockers**: Requires deep WASM/C toolchain knowledge

---

## Group 9: Async/Parallelization (4 issues) 🔥 HARDEST
**Theme**: Asynchronous execution and parallel processing
**Overall Difficulty**: Medium to Very Hard

### Medium
26. **#48** - Wiki: Show fractal similarity between workers=0 (sync) and workers=1 (async)
    - **Difficulty**: ⭐⭐ Medium
    - **Effort**: 4-6 hours
    - **Type**: Analysis and documentation

### Hard
27. **#68** - Enhancement: Support three dashboard versions (sync, async-pre-nanonext, async-nanonext)
    - **Difficulty**: ⭐⭐⭐⭐ Hard
    - **Effort**: 12-16 hours
    - **Type**: Maintain multiple parallel versions

### Very Hard
28. **#130** - Switch entirely to mirai, remove crew dependency
    - **Difficulty**: ⭐⭐⭐⭐⭐ Very Hard
    - **Effort**: 20-30 hours
    - **Type**: Major refactoring, breaking changes
    - **Labels**: enhancement, async, refactoring, simplification

29. **#144** - Async cache coherency: Workers making decisions on stale grid state 🔥
    - **Difficulty**: ⭐⭐⭐⭐⭐ Very Hard
    - **Effort**: 30+ hours
    - **Type**: Complex distributed state synchronization bug
    - **Labels**: bug, performance, async
    - **Challenge**: Race conditions, timing-dependent, requires deep async expertise

---

## Summary by Difficulty

### ⭐ Easy (4 issues)
- #76, #86, #84, #131
- **Estimated Total**: 3-5 hours

### ⭐⭐ Easy-Medium (3 issues)
- #66, #124, #88
- **Estimated Total**: 4-7 hours

### ⭐⭐ Medium (9 issues)
- #96, #87, #50, #56, #85, #60, #57, #157, #48
- **Estimated Total**: 27-41 hours

### ⭐⭐⭐ Medium-Hard (5 issues)
- #89, #103, #118, #78, #138
- **Estimated Total**: 24-36 hours

### ⭐⭐⭐⭐ Hard (3 issues)
- #69, #121, #91, #68
- **Estimated Total**: 34-52 hours

### ⭐⭐⭐⭐⭐ Very Hard (3 issues) 🔥
- #155, #130, #144
- **Estimated Total**: 70+ hours
- **Special Notes**: Require expert-level knowledge in WASM, async programming, distributed systems

---

## Recommended Priority Order

### Quick Wins (Do First)
1. #76 - Fix README badges (15 min)
2. #86 - Fix home page links (30 min)
3. #84 - Reorganize files (1 hour)
4. #131 - Workflow retrospective (1 hour)
5. #157/#158 - Merge PR #158 (5 min) ✅

### Low-Hanging Fruit (Do Next)
6. #66 - Defensive programming examples (2 hours)
7. #124 - Optimize vignette parameters (2 hours)
8. #88 - Update simulation parameters (3 hours)

### Medium Priority
9. #96 - Update README with nanonext/nix docs
10. #87 - Update async dashboard wiki
11. #50 - Targets pipeline vignette
12. #56 - Survival curve vignette
13. #85 - Fix pkgdown site
14. #60 - Dashboard validation UI
15. #57 - Non-blocking statistics display

### Advanced Work (Requires Expertise)
16. #89 - Document dynamic broadcasting
17. #103/#118 - Fix Shinylive embedding
18. #78 - Automate nix regeneration
19. #138 - User-friendly shell.nix

### Major Projects (Plan Carefully)
20. #69 - Persistent targets caching
21. #121 - Website rebuild workflow
22. #91 - Optimize CI build times
23. #48 - Fractal similarity analysis
24. #68 - Three dashboard versions

### Expert-Level Challenges (Last)
25. #155 - WASM mirai/nanonext compilation
26. #130 - Switch to mirai-only
27. #144 - Async cache coherency bug 🔥

---

## Notes

- **#157/#158**: Already completed, just needs merge confirmation
- **#144**: Most challenging issue - distributed state synchronization
- **#155**: Requires WASM/C toolchain expertise
- **#130**: Major breaking change, needs careful planning
- **#91**: High priority but complex optimization work

**Total Estimated Effort**: 160-230+ hours
