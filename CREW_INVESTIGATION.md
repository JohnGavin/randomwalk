# Crew + Nanonext Integration Investigation

**Date**: 2025-11-19
**Branch**: async-v2-phase1
**Status**: In Progress - Socket Error Under Investigation

## Executive Summary

Successfully resolved the primary crew integration issue (functions now accessible to workers via globals). However, a nanonext socket creation error persists that requires further investigation.

## Completed Fixes

### 1. Package Availability ✅
- Verified crew v1.3.0 installed in nix environment
- Enhanced check_nix_r_env.R to validate GitHub packages
- Confirmed randomwalk and btw packages loadable from Nix

### 2. Function Accessibility ✅
- **Root Cause**: Installed randomwalk (from main branch) lacks async functions
- **Solution**: Pass all worker functions as globals
- **Result**: Workers can now access: worker_run_walker, worker_init, worker_step_walker, etc.
- **Files**: R/simulation.R, R/async_worker.R

### 3. Namespace Prefix Removal ✅
- Removed `nanonext::` prefixes from worker functions
- Changed to direct calls (nano, subscribe, recv, close)
- Relies on `packages = c("nanonext", "logger")` parameter
- **Rationale**: Namespace references don't resolve correctly in functions passed as globals

## Current Issue: Nanonext Socket Error

### Error Message
```
`object` is not a valid Socket or Context
```

### Test Results

#### ✅ PASS: test_nanonext_in_crew.R
Simple nanonext calls work in crew workers:
```r
# Test 4 & 5 - Both succeeded
controller$push(
  command = {
    library(nanonext)
    socket <- nano("sub", dial = "tcp://127.0.0.1:5555")
    subscribe(socket, "")
    "subscribed"
  },
  packages = "nanonext"
)
# Result: success, socket class = "nanoObject"
```

#### ❌ FAIL: With functions as globals
```r
controller$push(
  command = worker_run_walker(...),
  globals = list(worker_run_walker = worker_run_walker, ...),
  packages = c("nanonext", "logger")
)
# Error: `object` is not a valid Socket or Context
```

#### ❌ FAIL: With inline function definition
```r
controller$push(
  command = {
    library(nanonext)
    worker_init_inline <- function(addr) {
      socket <- nano("sub", dial = addr)
      subscribe(socket, "")
      list(socket = socket, ...)
    }
    worker_init_inline(pub_address)
  },
  data = list(pub_address = "tcp://127.0.0.1:5555")
)
# Error: `object` is not a valid Socket or Context
```

#### ❌ FAIL: test_direct_nano.R
Even direct calls fail when using data parameters:
```r
# Test 1: Hardcoded address
controller$push(
  command = {
    library(nanonext)
    socket <- nano("sub", dial = "tcp://127.0.0.1:5555")
    subscribe(socket, "")
    list(...)
  }
)
# Result: ERROR - socket error

# Test 2: Parameter from data
controller$push(
  command = {
    library(nanonext)
    socket <- nano("sub", dial = addr)
    subscribe(socket, "")
    list(...)
  },
  data = list(addr = "tcp://127.0.0.1:5555")
)
# Result: ERROR - socket error
```

### Key Observations

1. **Simple nanonext calls work** when command is minimal
2. **Fails with publisher socket running** in main process
3. **Fails regardless of** function wrapping, inline definition, or data parameters
4. **Error occurs at subscribe() call** (based on traceback patterns)

### Hypotheses

#### H1: Port Conflict
- Main process holds publisher on tcp://127.0.0.1:5555
- Worker subscriber may conflict
- **Test**: Use different ports for pub/sub
- **Status**: Not yet tested

#### H2: Socket Lifecycle
- Publisher must be created before subscriber connects
- Connection timing issue in crew workers
- **Test**: Add delay, check publisher status
- **Status**: Not yet tested

#### H3: Serialization Issue
- Socket objects don't serialize properly through crew
- The `subscribe()` call receives invalid socket object
- **Test**: Check what `nano()` returns in worker
- **Status**: Partially tested - returns "nanoObject" in simple test

#### H4: Environment/Context
- Package environment not fully available even with `packages` parameter
- Missing some nanonext internals
- **Test**: Load nanonext differently, check loaded objects
- **Status**: Not yet tested

## Files Created/Modified

### Test Scripts
- `R/setup/test_nanonext_in_crew.R` - Proves nanonext works (5/5 tests pass)
- `R/setup/test_inline_worker.R` - Inline function test (fails)
- `R/setup/test_direct_nano.R` - Direct call test (fails)
- `R/setup/debug_crew_results.R` - Main debug script (fails)
- `R/setup/fix_crew_worker_loading.R` - Documentation of loading investigation

### Modified Code
- `R/async_worker.R` - Removed nanonext:: prefixes
- `R/simulation.R` - Pass functions as globals
- `R/async_controller.R` - Simplified controller creation

### Documentation
- `TESTING_STATUS.md` - Overall testing progress
- `CREW_INVESTIGATION.md` - This file

## Next Steps

### Immediate Actions

1. **Test H1: Port Conflict**
   ```r
   # Use separate ports
   pub_socket <- nano("pub", listen = "tcp://127.0.0.1:5555")
   # Worker uses different port
   socket <- nano("sub", dial = "tcp://127.0.0.1:5556")
   ```

2. **Test H2: Socket Lifecycle**
   ```r
   # Verify publisher exists before worker connects
   # Add longer delays
   # Check socket status
   ```

3. **Test H3: Return socket info**
   ```r
   command = {
     library(nanonext)
     socket <- nano("sub", dial = "tcp://127.0.0.1:5555")
     # Return socket details before subscribe
     list(
       socket_class = class(socket),
       socket_str = capture.output(str(socket)),
       socket_valid = !is.null(socket)
     )
   }
   ```

### Alternative Approaches

If socket error persists:

#### Option A: Simplify Communication
- Remove nanonext pub/sub entirely
- Pass grid state in task data
- Workers don't subscribe to updates
- **Pro**: Simpler, no socket issues
- **Con**: More data transfer, less efficient

#### Option B: Different Communication Pattern
- Use files or shared memory instead of sockets
- R6 objects or environments
- **Pro**: Avoids nanonext entirely
- **Con**: More complex state management

#### Option C: Future Package Instead
- Use future/promises instead of crew
- Different worker mechanism
- **Pro**: Well-tested, widely used
- **Con**: Different API, restart implementation

### Research Needed

1. Check crew + nanonext examples in crew documentation
2. Search for crew + socket issues in GitHub issues
3. Check nanonext documentation for crew compatibility
4. Look for working examples of crew with network sockets

## Lessons Learned

1. **Development vs Production Packages**
   - Crew workers load installed packages, not dev versions
   - Globals work for passing development functions
   - Important pattern for testing unreleased code

2. **Namespace in Globals**
   - Functions with `pkg::function()` calls don't work well as globals
   - Package must be loaded via `packages` parameter
   - Functions should call package functions without prefix

3. **Testing Strategy**
   - Test each component in isolation
   - Build complexity gradually
   - Create minimal reproducible examples

4. **Nix Environment**
   - GitHub packages install correctly
   - check_nix_r_env.R is valuable diagnostic tool
   - Both CRAN and GitHub packages work reliably

## References

- [crew documentation](https://wlandau.github.io/crew/)
- [nanonext documentation](https://shikokuchuo.net/nanonext/)
- [Issue #21](https://github.com/JohnGavin/randomwalk/issues/21)
- [PR #29](https://github.com/JohnGavin/randomwalk/pull/29)
- V2_ASYNC_PLAN.md
- PHASE1_STATUS.md
- CREW_FIXES_SUMMARY.md
