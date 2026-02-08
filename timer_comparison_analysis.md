# Timer Implementation: Why crew Works and My Approach Doesn't

## The Core Problem: Blocking vs Non-Blocking

### ❌ My Broken Approach (Blocks UI)
```r
observeEvent(input$start_sim, {
  for (i in 1:10) {
    Sys.sleep(1)  # BLOCKS ENTIRE UI THREAD FOR 1 SECOND
    task_progress(i * 10)  # UI can't update - we're blocked!
  }
})
```

**What happens:**
1. User clicks button
2. Event handler starts
3. UI freezes for 10 seconds (10 × 1 second sleeps)
4. No updates visible until loop completes
5. Then suddenly everything updates at once

### ✅ crew's Working Approach (Non-Blocking)
```r
# Start task without blocking
observeEvent(input$start_sim, {
  task_state("running")
  task_start(Sys.time())
  # EXIT IMMEDIATELY - no sleep, no loop!
})

# Separate observer polls for progress
observe({
  if (task_state() == "running") {
    invalidateLater(100)  # Schedule next check
    elapsed <- difftime(Sys.time(), task_start(), units = "secs")
    # Update progress based on elapsed time
  }
})
```

**What happens:**
1. User clicks button
2. Event handler sets state and exits immediately
3. Separate observer checks every 100ms
4. UI updates smoothly throughout
5. User sees real-time progress

## The Key Insight: Separation of Concerns

### Traditional (Broken) Pattern
```
Button Click → Long Task → Update UI
             ↑
        [UI FROZEN HERE]
```

### crew Pattern (Working)
```
Button Click → Set State → Exit
                  ↓
            Observer Loop → Check State → Update UI → Schedule Next Check
                  ↑_______________________|
```

## Critical Rules for WebR/Shinylive

1. **NEVER use `Sys.sleep()` in event handlers**
   - Blocks the JavaScript event loop
   - Freezes the entire UI

2. **ALWAYS use `invalidateLater()` for periodic updates**
   - Schedules re-execution without blocking
   - Allows UI to remain responsive

3. **Separate task initiation from monitoring**
   - Event handlers should only set state
   - Observers should monitor and update

## Applying to the Main Dashboard

### Current (Broken) Simulation Loop
```r
observeEvent(input$start, {
  for (step in 1:max_steps) {
    # Simulate one step
    walkers <- update_walkers(walkers)
    # Try to update reactive values
    reactive_walkers(walkers)  # Won't display until loop ends!
  }
})
```

### Fixed Non-Blocking Version
```r
# Initialize simulation
observeEvent(input$start, {
  values$sim_state <- "running"
  values$current_step <- 0
  values$max_steps <- input$max_steps
})

# Run simulation steps
observe({
  if (values$sim_state == "running") {
    invalidateLater(50)  # Run ~20 steps per second

    # Do a small batch of steps
    for (i in 1:10) {  # Small batch for responsiveness
      if (values$current_step < values$max_steps) {
        values$walkers <- update_walkers(values$walkers)
        values$current_step <- values$current_step + 1
      } else {
        values$sim_state <- "complete"
        break
      }
    }
  }
})
```

## Performance Considerations

| Approach | UI Updates | CPU Usage | User Experience |
|----------|-----------|-----------|-----------------|
| Blocking Loop | None during execution | 100% for duration | Frozen, appears broken |
| crew Pattern (50ms) | 20 Hz | Distributed | Smooth, responsive |
| crew Pattern (100ms) | 10 Hz | Lower, distributed | Good, slightly less smooth |
| crew Pattern (500ms) | 2 Hz | Minimal | Choppy but functional |

## Testing the Fix

### Signs It's Working:
- ✅ Clock continues ticking during simulation
- ✅ Progress bar animates smoothly
- ✅ Stop button responds immediately
- ✅ Other UI elements remain interactive

### Signs It's Still Broken:
- ❌ Clock freezes when simulation starts
- ❌ Progress jumps from 0% to 100%
- ❌ Cannot stop once started
- ❌ Browser shows "Page Unresponsive" warning

## References
- [crew Shiny article](https://wlandau.github.io/crew/articles/shiny.html) - The correct pattern
- [Shiny async programming](https://rstudio.github.io/promises/articles/shiny.html)
- [invalidateLater documentation](https://shiny.posit.co/r/reference/shiny/latest/invalidatelater)