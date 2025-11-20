# Update GitHub Issue #34 with Progress
# Date: 2025-11-20

# NOTE: Run this from a fresh nix shell after restart
# This documents progress so far on issue #34

cat("To update issue #34 with progress, run:\n\n")

comment_body <- "## Progress Update - 2025-11-20

### ✅ Completed

1. **Created minimal default-ci.nix**
   - Reduced from ~100+ packages to 13 essential packages
   - Packages: logger, ggplot2, crew, nanonext, testthat, covr, roxygen2, pkgdown, knitr, rmarkdown, devtools, rcmdcheck, shinylive

2. **Updated workflows**
   - `.github/workflows/nix-builder.yaml` - Uses default-ci.nix
   - `.github/workflows/tests-r-via-nix.yaml` - Uses default-ci.nix

3. **Set up custom Cachix cache**
   - Cache name: `randomwalk`
   - Added `CACHIX_AUTH_TOKEN` to GitHub secrets
   - Updated workflows to use custom cache with auth

4. **First cached build completed (Run #96)**
   - nix-builder: 6m 33s (was ~17 min)
   - R-tests-via-nix: 7m 18s (was ~17 min)
   - **62% speedup achieved!**

### 🔍 Key Finding

The original slow builds were caused by using the **read-only** `rstats-on-nix` Cachix cache. We couldn't push our builds there, so packages were rebuilt from source every time.

**Solution**: Created our own `randomwalk` Cachix cache with write permissions.

### ⏳ Next Steps

1. **Trigger Run #97** to test full cache pull
   - Expected: ~2-3 min (85% faster than original)
   - Should pull all packages from populated cache
   - No building, just downloading

2. **If successful** (Run #97 ~2-3 min):
   - Merge PR #35
   - Close this issue
   - Document in CLAUDE_CONTEXT.md

3. **If still slow** (Run #97 >5 min):
   - Investigate why cache isn't working
   - Consider fallback to r-lib/actions (Option A)

### 📊 Results So Far

| Metric | Before | After Run #96 | Target (Run #97) |
|--------|--------|---------------|------------------|
| nix-builder | ~17 min | 6m 33s | ~2-3 min |
| R-tests-via-nix | ~17 min | 7m 18s | ~2-3 min |
| Speedup | - | 62% | 85%+ |

### 📁 Documentation

All work logged in `R/setup/`:
- `SESSION_2025-11-20_ISSUE_34_PROGRESS.md` - Full session summary
- `setup_custom_cachix.md` - Cachix setup guide
- All R scripts for reproducibility

**Status**: Ready for final caching test (Run #97)"

cat(comment_body)
cat("\n\n---\n\n")
cat("To post this to GitHub issue #34, run:\n\n")
cat("library(gh)\n")
cat("gh::gh(\n")
cat("  'POST /repos/JohnGavin/randomwalk/issues/34/comments',\n")
cat("  body = readLines('R/setup/issue_34_comment.txt') |> paste(collapse = '\\n')\n")
cat(")\n")

# Save comment for later posting
writeLines(comment_body, "R/setup/issue_34_comment.txt")
cat("\n✅ Comment saved to R/setup/issue_34_comment.txt\n")
