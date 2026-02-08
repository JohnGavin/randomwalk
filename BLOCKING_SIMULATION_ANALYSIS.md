# Why Progress Updates Don't Work: The Blocking Simulation Problem

## The Core Issue

`run_simulation()` is a compiled C++ function that runs **synchronously and blocks the entire thread**. No amount of `invalidateLater()` or `observe()` patterns can fix this because the function doesn't yield control back to the event loop.

## What We Tried

### Attempt 1: Sys.sleep() Chunking (Failed)
```r
for (i in 1:chunks) {
  Sys.sleep(delay)  # Blocks UI
  update_progress()
}
run_simulation()  # Still blocks
```
**Result**: UI frozen during sleep AND simulation

### Attempt 2: invalidateLater() Pattern (Partially Works)
```r
observe({
  if (chunk < 19) {
    invalidateLater(100)  # Non-blocking
    show_fake_progress()   # Works!
  } else {
    run_simulation()       # BLOCKS!
  }
})
```
**Result**: Smooth fake progress 0-95%, then freezes

## Why It Doesn't Work

The simulation runs in a single atomic operation:
```cpp
// In C++ - runs to completion without yielding
for (int step = 0; step < max_steps; step++) {
  update_all_walkers();
  check_collisions();
  mark_black_pixels();
  // No way to yield control here!
}
```

## Real Solutions

### 1. Modify C++ Code for Chunking
```cpp
// Add callback parameter
SEXP run_simulation_chunked(SEXP params, SEXP callback) {
  for (int step = 0; step < max_steps; step++) {
    // Do work...

    if (step % 100 == 0) {
      // Call R function with progress
      Rf_eval(Rf_lang2(callback, Rf_ScalarInteger(step)), R_GlobalEnv);
    }
  }
}
```

### 2. Use promises/future (R Solution)
```r
library(promises)
library(future)
plan(multisession)

future_promise({
  run_simulation(...)  # Runs in separate R process
}) %...>%
  function(result) {
    # Update UI with result
  }
```

### 3. WebR-Specific: Use Comlink
```javascript
// simulation.worker.js
importScripts('https://cdn.jsdelivr.net/npm/comlink');

async function runSimulation(params) {
  // Run simulation with progress callbacks
  for (let i = 0; i < steps; i++) {
    await Comlink.proxy((progress) => {
      postMessage({progress});
    })(i / steps);
  }
}

Comlink.expose(runSimulation);
```

### 4. Honest UI: Indeterminate Progress
```r
# Just show a spinner
withProgress(message = "Running simulation...", {
  result <- run_simulation(...)
})
```

## Current Workaround

The current implementation shows **fake progress** which is misleading:
- 0-95%: Fake updates (smooth, not real)
- 95-100%: Actual simulation (UI frozen)
- Complete: Sudden jump to done

## Recommendation

For WebR/Shinylive, the most honest approach is:
1. Show an indeterminate spinner or animated message
2. Disable the button during execution
3. Don't claim to show real progress unless we can actually measure it

Or implement true chunking by modifying the C++ code to yield control periodically.

## Testing

To verify the blocking behavior:
1. Open browser DevTools (F12)
2. Watch Console during simulation
3. Note that NO console messages appear during the actual simulation
4. All messages appear at once when complete

This proves the thread is completely blocked during `run_simulation()`.