# WebAssembly Async Support Status

**Date:** 2025-12-15
**Issue:** Enabling async parallel processing in WebAssembly for dynamic_broadcasting vignette

## Summary

The core async messaging infrastructure (nanonext, mirai) IS available for WebAssembly. However, the worker process management layer (crew) is NOT yet available, which blocks async functionality in the browser.

## Package Availability Matrix

| Package | Purpose | Wasm Status | Source |
|---------|---------|-------------|--------|
| **nanonext** | Low-level async messaging (NNG bindings) | ✅ Available | [r-lib.r-universe.dev](https://r-lib.r-universe.dev/bin/emscripten/contrib/4.5/nanonext_1.7.2.9000.tgz) |
| **mirai** | Parallel task execution framework | ✅ Available | [r-lib.r-universe.dev](https://r-lib.r-universe.dev/bin/emscripten/contrib/4.5/mirai_2.5.3.9000.tgz) |
| **crew** | Worker process management | ❌ NOT Available | Not in wasm repos |

## Technical Details

### nanonext (v1.7.2.9000)
- **Status:** Available for R 4.5.1 emscripten
- **Built:** 2025-12-03
- **Size:** 500KB
- **Provides:** Socket-based async messaging, NNG protocol bindings
- **Repository:** `https://r-lib.r-universe.dev`

### mirai (v2.5.3.9000)
- **Status:** Available for R 4.5.1 emscripten
- **Built:** 2025-12-01
- **Size:** 250KB
- **Provides:** Async evaluation framework, parallel task distribution
- **Dependencies:** Requires nanonext >= 1.7.2
- **Repository:** `https://r-lib.r-universe.dev`

### crew (latest)
- **Status:** NOT available for WebAssembly
- **Built on:** mirai (which IS available for wasm)
- **Provides:** Higher-level worker pool management
- **Why blocked:** Likely requires features not available in wasm environment

## Current Implementation

The randomwalk package uses this stack:

```
run_simulation() [R/simulation.R]
         ↓
run_simulation_async_dynamic() [R/simulation.R]
         ↓
create_controller() [R/async_controller.R]
         ↓
crew::crew_controller_local() [❌ NOT available in wasm]
         ↓
mirai (✅ available in wasm)
         ↓
nanonext (✅ available in wasm)
```

## Path Forward: Option 1 (Refactor to mirai)

**Goal:** Remove crew dependency, use mirai directly

**Changes needed:**
1. Refactor `R/async_controller.R::create_controller()` to use `mirai::daemons()` instead of `crew::crew_controller_local()`
2. Update task submission to use `mirai::mirai()` instead of crew's task interface
3. Update task collection to use `mirai::call_mirai()` / `mirai::collect_mirai()`
4. Update cleanup to use `mirai::daemons(0)` instead of crew shutdown

**Benefits:**
- ✅ Async functionality works in WebAssembly
- ✅ Same functionality as current crew-based code
- ✅ Potentially simpler code (mirai is lower-level but more direct)
- ✅ All dependencies available for wasm

**Risks:**
- ⚠️ Requires rewriting async controller logic
- ⚠️ Need to ensure mirai works in browser environment (may have limitations)
- ⚠️ mirai daemons might not work the same way in wasm as in native R

## Path Forward: Option 2 (Wait for crew wasm)

**Goal:** Wait for crew package to be compiled for WebAssembly

**Benefits:**
- ✅ No code changes needed
- ✅ Keep current clean abstraction

**Risks:**
- ⏳ Unclear timeline
- ⏳ crew may have dependencies that are hard to compile for wasm

## Recommendation

**Try Option 1 first** with a prototype:

1. Create a new branch `feat/mirai-wasm`
2. Implement mirai-based async controller in parallel with crew version
3. Test in both environments (local native R vs WebAssembly)
4. If successful, create a runtime switch:
   ```r
   if (is_webr()) {
     use_mirai_controller()
   } else {
     use_crew_controller()
   }
   ```
5. This gives us async in wasm NOW while keeping crew for better abstractions locally

## References

- **R-Universe WebAssembly packages:** `https://r-lib.r-universe.dev/bin/emscripten/contrib/4.5/PACKAGES`
- **mirai documentation:** `https://mirai.r-lib.org/`
- **nanonext documentation:** `https://shikokuchuo.net/nanonext/`
- **WebR documentation:** `https://docs.r-wasm.org/webr/latest/`

## Testing Checklist

When implementing mirai-based async:

- [ ] Local testing: mirai daemons work in native R
- [ ] Wasm testing: mirai daemons work in WebR/browser
- [ ] Network: Verify socket communication works in wasm
- [ ] Performance: Compare mirai vs crew performance
- [ ] Error handling: Ensure clean shutdown in both environments
- [ ] Documentation: Update vignettes with wasm async examples

## Related Files

- `vignettes/dynamic_broadcasting.qmd` - Updated with current wasm status
- `R/async_controller.R` - Needs refactoring for mirai
- `R/async_worker.R` - May need updates for mirai interface
- `R/simulation.R` - Main entry point, handles async dispatch

## Session Log

This investigation was triggered by user request to enable nanonext in r-shinylive dashboard vignettes. Through investigation we discovered:

1. nanonext IS available for wasm (contrary to vignette documentation)
2. mirai (foundation of crew) is ALSO available for wasm
3. crew (the actual blocker) is NOT available for wasm
4. This opens a path to async wasm support via mirai refactoring
