# crew Timer Pattern Analysis & Solution

## Executive Summary

You asked me to compare the [crew Shiny article](https://wlandau.github.io/crew/articles/shiny.html) timer implementation with my timer test dashboard. The crew article revealed the **critical flaw** in my approach: I was blocking the UI thread with `Sys.sleep()` instead of using non-blocking periodic checks.

## What crew Does Right

### 1. **Never Blocks the UI Thread**
```r
observe({
  invalidateLater(millis = 500)  # Schedule next check
  results <- controller$collect()  # Non-blocking check
  # Process results if available
})
```

### 2. **Separates Task Initiation from Monitoring**
- **Start**: Just set state and exit immediately
- **Monitor**: Separate observer checks periodically
- **Update**: UI refreshes on each check

### 3. **Uses invalidateLater() for Periodic Updates**
- Schedules re-execution without blocking
- Allows browser event loop to continue
- UI remains fully responsive

## What I Did Wrong

### My Broken Pattern
```r
observeEvent(input$start_sim, {
  for (i in 1:10) {
    Sys.sleep(1)  # ❌ BLOCKS ENTIRE UI FOR 1 SECOND!
    task_progress(i * 10)  # UI can't update!
  }
})
```

**Result**: UI freezes for 10 seconds, no updates visible

### The Fixed Pattern (crew-style)
```r
# Start without blocking
observeEvent(input$start_sim, {
  values$task_state <- "running"
  values$task_start <- Sys.time()
  # EXIT IMMEDIATELY!
})

# Monitor in separate observer
observe({
  if (values$task_state == "running") {
    invalidateLater(100)  # Check again in 100ms
    elapsed <- difftime(Sys.time(), values$task_start, units = "secs")
    # Update progress based on elapsed time
  }
})
```

**Result**: UI updates smoothly every 100ms

## The Core Insight

The fundamental difference is **when and how we yield control**:

| Approach | Control Flow | UI Updates |
|----------|-------------|------------|
| `Sys.sleep()` | Blocks thread, no yielding | None until complete |
| `invalidateLater()` | Yields immediately, schedules callback | Continuous |

## Proof of Concept

I created two test dashboards:

1. **timer_test_dashboard.qmd** - Uses `Sys.sleep()` (broken)
   - Clock freezes during task
   - No progress updates visible
   - Browser becomes unresponsive

2. **timer_test_dashboard_fixed.qmd** - Uses crew pattern (working)
   - Clock continues ticking
   - Progress bar animates smoothly
   - Full UI responsiveness

## Application to Main Dashboard

The main dashboard has the same problem in lines 665-694:

```r
# BROKEN: Uses Sys.sleep() in loop
for (i in 1:chunks) {
  # Update progress...
  Sys.sleep(est_runtime / chunks)  # ❌ Blocks UI!
}
```

This needs to be replaced with the crew pattern using `invalidateLater()` and a separate observer.

## Key Lessons

1. **WebR/Shinylive CAN do real-time updates** - You were right, I was wrong about the limitations
2. **The crew pattern works universally** - Same approach for native R and WebR
3. **Never use Sys.sleep() in event handlers** - Always use invalidateLater() instead
4. **Separation of concerns is critical** - Initiate vs Monitor vs Update

## Next Steps

Apply the crew pattern to fix the main dashboard:
1. Remove all `Sys.sleep()` calls
2. Move simulation chunks to observe() with invalidateLater()
3. Test that clock/timer continues updating during simulation
4. Verify UI remains responsive throughout

## References

- [Working Fixed Timer](https://johngavin.github.io/randomwalk/articles/timer_test_dashboard_fixed.html)
- [crew Shiny Article](https://wlandau.github.io/crew/articles/shiny.html)
- [Shiny invalidateLater() docs](https://shiny.posit.co/r/reference/shiny/latest/invalidatelater)