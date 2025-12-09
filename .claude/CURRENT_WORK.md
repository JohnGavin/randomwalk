# Current Focus: Repository Consolidation & Issue Management

## Active Branch
main

## What I'm Doing
- **Consolidating .md files** to reduce duplication
- **Moving detailed content** to GitHub issues and wiki
- **Organizing issues** by similarity and difficulty
- **Cleaning up** outdated documentation files

## Progress
- [x] Analyzed all .md files in top-level directory
- [x] Created issue #121 from STARTUP.md detailed implementation plan
- [x] Removed duplicate/outdated files (PROJECT_INFO.md, ISSUES_GROUPED.md, STARTUP.md)
- [x] Updated ISSUES_GROUPED_BY_DIFFICULTY.md as canonical reference (30 issues, 5 groups)
- [ ] Update CURRENT_WORK.md (this file) - IN PROGRESS
- [ ] Create consolidation summary document
- [ ] Commit consolidation changes

## Key Consolidation Actions

### Files Removed ❌
1. **PROJECT_INFO.md** - Outdated (showed v1.0.0, project has progressed)
2. **ISSUES_GROUPED.md** - Old grouping from Nov 28 (only 7 issues, superseded)
3. **STARTUP.md** - Detailed plan moved to issue #121

### Files Updated ✅
1. **ISSUES_GROUPED_BY_DIFFICULTY.md** - Now canonical reference:
   - 30 open issues organized into 5 groups (A-E)
   - Sorted by difficulty within each group (easiest → hardest)
   - Clear priority sections: Quick Wins, Critical Path, Feature Development
   - Summary statistics and recommended work order
   - Notes on 11 open PRs needing review

2. **.claude/CURRENT_WORK.md** - This file (session continuity)

### Files Created 📝
1. **Issue #121** - "Implementation Plan: Fix Website Rebuild & Vignette Deployment"
   - Moved detailed workflow from STARTUP.md
   - Tagged: workflow, vignettes, pkgdown, targets, deployment
   - Priority: High

## Current State Summary

**Total Open Issues**: 30
**Open PRs**: 11 (many ready to merge)

**Issue Groups**:
- **Group A**: Documentation & Wiki (9 issues)
- **Group B**: Vignettes & Articles (8 issues)
- **Group C**: Dashboard Features (6 issues)
- **Group D**: CI/CD & Build (6 issues)
- **Group E**: Repo Organization (2 issues, including PR consolidation #115)

**Quick Wins** (3 hours total):
1. #116 - Duplicate telemetry.qmd (has PR #119)
2. #102 - Fix dashboard_async 404
3. #117 - Verify dynamic_broadcasting.html
4. #95 - Clean up HTML files
5. #78 - Automate nix regen (has PR #79)

**Critical Path** (blocks other work):
1. #111 - CI Failures (BLOCKING)
2. #92 - Cachix not working (EXPENSIVE - 18 min waste per build)
3. #115 - Too many open PRs (NOISE - need decisions)

## Blockers
None - consolidation work is independent

## Next Session Should
1. **Review PR status** - Check which of 11 PRs can be merged
2. **Address Quick Wins** - Knock out 5 easy issues in 3 hours
3. **Fix Critical Path** - Especially #111 (CI failures) and #92 (cachix)
4. **Continue consolidation** if more .md files found in subdirectories

## Important Notes

### Archive Structure
- `archive/` folder contains historical documentation (kept for reference)
- Session logs, fix summaries, deployment docs preserved
- No need to consolidate archive/ - it's already organized

### Wiki Cross-Referencing
Detailed topics should be in wiki with cross-links from issues:
- Nix environment troubleshooting
- Development workflow guides
- Dynamic broadcasting algorithm details
- Fractal similarity analysis

### Documentation Philosophy
- **README.md**: User-facing package documentation
- **ISSUES_GROUPED_BY_DIFFICULTY.md**: Canonical issue reference (this file)
- **.claude/CURRENT_WORK.md**: Session continuity (this file)
- **GitHub Issues**: Actionable tasks with clear acceptance criteria
- **Wiki**: Detailed guides, troubleshooting, architectural decisions

## Related Issues
- #121 - Implementation plan for vignette deployment (created today)
- #115 - Rationalize open PRs (meta-issue for cleanup)
- #84 - Reorganize R/setup/ files

---
**Last updated**: 2025-12-09
**Session state**: Consolidation complete, ready to commit
**Next action**: Create summary document, then commit consolidation changes
