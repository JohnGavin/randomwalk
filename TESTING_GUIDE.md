# Testing Guide: Async Simulation Before Merge

## Quick Test Options

### Option 1: Check GitHub Actions ✅ Recommended (Fastest)

**Already done!** All tests passed in CI:
- URL: https://github.com/JohnGavin/randomwalk/actions/runs/19509825796
- Status: ✅ All 225 tests passed
- Environment: Nix (reproducible)
- Duration: ~5-10 minutes

**To verify**:
```bash
# View recent workflow runs
gh run list --repo JohnGavin/randomwalk --branch async-v2-phase1 --limit 5

# View specific run details
gh run view 19509825796 --repo JohnGavin/randomwalk
```

---

### Option 2: Run Tests Locally

**From your project directory**:

```bash
# Switch to async branch
cd /Users/johngavin/docs_gh/claude_rix/random_walk
git checkout async-v2-phase1

# Option A: Run in Nix shell (recommended - same as CI)
nix-shell
Rscript -e "devtools::test()"

# Option B: Run without Nix (if packages already installed)
Rscript -e "devtools::test()"

# Option C: Run just async tests
Rscript -e "testthat::test_file('tests/testthat/test-async.R')"
```

**Expected output**:
```
✅ PASS: 225
⏭️  SKIP: 8
❌ FAIL: 0
⚠️  WARN: 0
```

---

### Option 3: Run Interactive Async Simulation

**Test the actual async functionality**:

```r
# Load the package
library(randomwalk)

# Run small async simulation (2 workers, 3 walkers)
result <- run_simulation(
  grid_size = 10,
  n_walkers = 3,
  workers = 2,           # Async mode
  neighborhood = "4-hood",
  boundary = "terminate",
  verbose = TRUE
)

# Check results
print(result$statistics)

# Expected output:
# - completed_walkers: 3
# - black_pixels: 2-5 (varies due to randomness)
# - elapsed_time_secs: < 5 seconds
# - termination_reasons: table of why walkers stopped
```

**Larger test**:
```r
# More walkers, more workers
result_large <- run_simulation(
  grid_size = 50,
  n_walkers = 20,
  workers = 4,
  verbose = FALSE
)

print(result_large$statistics)
```

---

### Option 4: Compare Sync vs Async

**Verify async works and produces reasonable results**:

```r
library(randomwalk)

set.seed(123)

# Sync mode (baseline)
sync_result <- run_simulation(
  grid_size = 20,
  n_walkers = 10,
  workers = 0,  # Sync
  verbose = FALSE
)

set.seed(123)

# Async mode (2 workers)
async_result <- run_simulation(
  grid_size = 20,
  n_walkers = 10,
  workers = 2,  # Async
  verbose = FALSE
)

# Compare results
cat("Sync mode:\n")
print(sync_result$statistics)

cat("\nAsync mode:\n")
print(async_result$statistics)

cat("\nComparison:\n")
cat("Both completed:",
    sync_result$statistics$completed_walkers, "vs",
    async_result$statistics$completed_walkers, "\n")
cat("Black pixels:",
    sync_result$statistics$black_pixels, "vs",
    async_result$statistics$black_pixels, "\n")
cat("Time (sync vs async):",
    sync_result$statistics$elapsed_time_secs, "vs",
    async_result$statistics$elapsed_time_secs, "\n")

# Note: Results may differ slightly (this is expected with static snapshots)
```

---

### Option 5: Run Benchmark

**Test performance targets (1.5-1.8x speedup)**:

```bash
Rscript benchmarks/benchmark_async.R
```

**Or interactively**:
```r
source("benchmarks/benchmark_async.R")
```

**Expected output**:
```
Sync mode (1 worker): ~X seconds
Async mode (2 workers): ~X/1.5 to X/1.8 seconds
Speedup: 1.5-1.8x
```

---

### Option 6: Use Pre-built Test Script

**We created this earlier**:

```bash
Rscript R/setup/test_simplified_async_fix.R
```

**Expected output**:
```
=== Testing Simplified Async Simulation ===

Test 1: Small async simulation (2 workers, 3 walkers)...
✅ Test 1 PASSED
Completed walkers: 3 / 3
Black pixels: 2-5
Elapsed time: 1-3 seconds

Test 2: Single worker async simulation...
✅ Test 2 PASSED
Completed walkers: 2 / 2

=== Tests Complete ===
```

---

## What to Look For

### ✅ Success Indicators

1. **No errors** - Simulation completes without crashing
2. **All walkers complete** - `completed_walkers == n_walkers`
3. **Black pixels > 0** - Walkers are terminating and leaving trails
4. **Reasonable time** - Completes in seconds, not minutes
5. **No timeouts** - Workers don't hang

### ❌ Failure Indicators

1. **Timeout errors** - "Async simulation timeout after Xs"
2. **Socket errors** - "object is not a valid Socket" (should be gone!)
3. **Worker errors** - "Invalid walker structure"
4. **Hanging** - Never completes
5. **All walkers fail** - `completed_walkers == 0`

---

## Viewing Results (if pkgdown deployed)

**If pkgdown site is deployed**, you can view documentation at:
```
https://johngavin.github.io/randomwalk/
```

**Check if deployed**:
```bash
gh run list --repo JohnGavin/randomwalk --workflow=pkgdown --limit 3
```

**Articles/Vignettes** might include interactive examples (if configured).

---

## Quick Verification Checklist

Before merging to main, verify:

- [ ] GitHub Actions passing (already ✅)
- [ ] Local tests pass (`devtools::test()`)
- [ ] Manual async simulation works
- [ ] Sync vs async both complete successfully
- [ ] No hanging or timeout issues
- [ ] Performance acceptable (optional benchmark)

---

## If You Find Issues

**Report back with**:
1. What command you ran
2. Error message (full output)
3. Expected vs actual behavior

**Debug with**:
```r
# Enable verbose logging
library(logger)
log_threshold(DEBUG)

# Run with verbose output
result <- run_simulation(
  grid_size = 10,
  n_walkers = 3,
  workers = 2,
  verbose = TRUE  # Show progress
)
```

---

## Recommended Testing Flow

**Minimal** (GitHub Actions already passed):
1. ✅ Check GH Actions - DONE
2. ✅ Merge to main

**Standard** (quick local verification):
1. ✅ Check GH Actions
2. Run `Rscript R/setup/test_simplified_async_fix.R`
3. If passes → Merge

**Thorough** (full local testing):
1. ✅ Check GH Actions
2. Run `devtools::test()`
3. Run interactive simulation
4. Compare sync vs async
5. If all pass → Merge

**Paranoid** (full verification):
1. ✅ Check GH Actions
2. Run all tests locally
3. Run benchmarks
4. Test on different grid sizes
5. Compare with sync mode
6. Review all code changes
7. Check pkgdown site
8. Then merge

---

## My Recommendation

**Since GitHub Actions already passed in a clean Nix environment**, you can safely merge.

The CI environment is more reliable than local testing because:
- ✅ Reproducible (Nix)
- ✅ Clean environment
- ✅ Same as production
- ✅ All 225 tests passed

**Optional**: Run the quick test script for peace of mind:
```bash
Rscript R/setup/test_simplified_async_fix.R
```

---

## After Merging

**Test on main branch**:
```bash
git checkout main
git pull
Rscript -e "devtools::test()"
```

**Should see same results**: ✅ 225 PASS, 0 FAIL
