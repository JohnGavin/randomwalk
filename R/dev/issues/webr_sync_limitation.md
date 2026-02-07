# WebR Synchronous Execution Limitation

## Issue
The timer shows "Ready | Current time: HH:MM:SS" but **does not update during simulation**. It only updates before simulation starts and after it completes.

## Root Cause
WebR runs R code synchronously in the browser's main thread. When `run_simulation()` executes:
1. It blocks the JavaScript event loop
2. No browser events (including timers) can fire
3. The reactive timer cannot update until the simulation completes

## Evidence
- Timer shows static time during simulation
- Updates immediately after simulation completes
- This is a fundamental WebR limitation, not a bug

## Why Reactive Timers Don't Help
Even though we have:
```r
autoInvalidate <- reactiveTimer(100)  # Updates every 100ms
```

The timer events cannot fire while R code is executing because the browser's event loop is blocked.

## Workarounds
1. **Chunked execution**: Break simulation into smaller chunks that yield control
2. **Web Workers**: Run simulation in background thread (not supported by WebR yet)
3. **Progress estimation**: Show estimated progress based on typical runtime (current approach)

## Current Implementation
We estimate progress based on elapsed time:
```r
observe({
  autoInvalidate()
  if (sim_state() == "running") {
    # This only runs BEFORE simulation starts
    # Cannot update DURING simulation
  }
})
```

## Conclusion
This is **not fixable** without WebR supporting async execution or web workers. The timer will remain frozen during simulation execution.