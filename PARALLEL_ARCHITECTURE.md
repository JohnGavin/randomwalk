# Parallel & Async Architecture - Random Walk Simulation

**Status**: Designed but **Not Yet Implemented** in v1.0.0
**Current Mode**: Synchronous only (single-threaded)

## Important Notice

⚠️ **The current v1.0.0 implementation is SYNCHRONOUS only** despite the title claiming "Asynchronous Pixel Walking."

Looking at the actual code in `R/simulation.R`:
```r
# Line 11: workers parameter exists but is not used
# Line 12: Note: Async implementation not yet available in this version.
# Line 69: Mode: Synchronous (hardcoded)
```

The package **describes** an async architecture but **has not implemented** it yet. The DESCRIPTION and documentation reference the intended design, but the code runs serially.

## Intended Architecture (Not Yet Built)

Based on `prompt_random_walk.md`, here's the **planned** parallel architecture:

### Components

1. **Main Process**
   - Shiny app with UI
   - Simulation management and coordination
   - Results aggregation

2. **Worker Processes** (using `crew` package)
   - Independent R processes
   - Each manages one walker at a time
   - Work queue for walker assignment

3. **Communication** (using `nanonext` package)
   - Push/Pull sockets for job distribution
   - Publisher/Subscriber for state synchronization
   - Ports: 5555, 5556, 5557, 5558

4. **State Management** (using `duckdb` package)
   - In-memory DuckDB database
   - Global grid state shared across workers
   - Real-time state synchronization

### How Parallelization Would Work

#### Walker Distribution
```
Controller Queue: [Walker1, Walker2, Walker3, ... Walker8]
                         ↓          ↓          ↓
                    Worker1     Worker2    Worker3
```

- **Workers**: 3 parallel R processes
- **Walkers**: 8 total (queued for processing)
- Each worker processes walkers independently
- When a walker terminates, worker picks next from queue

#### State Synchronization Flow
```
Worker1: Walker terminates → Updates DuckDB → Broadcasts to all
Worker2: Receives broadcast → Updates local cache → Continues
Worker3: Receives broadcast → Updates local cache → Continues
```

**Key Mechanism**:
- Every walker checks global state **before every move**
- If grid updated, worker fetches latest from DuckDB
- Prevents walkers from stepping on newly-black pixels

### Parallelization Benefits (Theoretical)

#### What Gets Parallelized

1. **Walker Movement** - Each walker runs independently:
   - Compute next position
   - Check boundary conditions
   - Detect termination
   - Update path history

2. **Collision Detection** - Workers check grid independently:
   - Each maintains local black pixel cache
   - Checks for black neighbors
   - Updates on global state changes

3. **Statistics Collection** - Workers track locally:
   - Step counts
   - Path trajectories
   - Termination reasons

#### What Remains Serial

1. **Grid State Updates** - Must be synchronized:
   - When walker terminates and pixel turns black
   - Broadcast to all workers
   - All workers must receive update

2. **Global Statistics Aggregation** - Done by controller:
   - Collect results from all workers
   - Compute percentiles across all walkers
   - Final grid state assembly

### Expected Speedup (Theoretical Estimates)

Based on the parallel design, here are **estimated** speedups:

#### Ideal Case (CPU-bound work, no contention)

| Workers | Walkers | Expected Speedup | Reason |
|---------|---------|------------------|---------|
| 1 | 8 | 1.0x (baseline) | Serial execution |
| 2 | 8 | ~1.8x | Near-linear, some sync overhead |
| 3 | 8 | ~2.5x | Good parallelism, moderate overhead |
| 4 | 8 | ~3.0x | Diminishing returns start |
| 8 | 8 | ~4.0x | Heavy sync overhead |

**Why not 8x with 8 workers?**
- Grid state synchronization overhead
- DuckDB lock contention
- nanonext communication latency
- Worker startup/shutdown costs

#### Realistic Case (with sync overhead)

Assuming each walker takes 1000 steps:
- **Computation**: 900 steps (90%) - can parallelize
- **Synchronization**: 100 steps (10%) - must serialize

**Amdahl's Law**: `Speedup = 1 / (0.1 + 0.9/N)`

| Workers | Theoretical Max | Expected Reality |
|---------|----------------|------------------|
| 2 | 1.82x | ~1.5-1.7x |
| 4 | 3.08x | ~2.2-2.8x |
| 8 | 5.26x | ~3.0-4.0x |
| 16 | 8.11x | ~4.0-5.5x |

**Reality factors**:
- Cache invalidation when state updates
- Network latency (even local sockets)
- Database query overhead
- R process communication costs

### Bottlenecks in Parallel Design

1. **Global State Updates**
   - Every walker termination requires broadcast
   - All workers must receive and acknowledge
   - Can stall fast walkers waiting for slow workers

2. **DuckDB Contention**
   - Read/write locks on grid state table
   - Multiple workers querying simultaneously
   - INSERT operations block readers

3. **Communication Overhead**
   - nanonext socket latency (~1-10ms per message)
   - Serialization/deserialization of grid state
   - Broadcast amplification (1→N messages)

4. **Cache Coherency**
   - Each worker maintains local black pixel cache
   - Must invalidate and refresh on every broadcast
   - Memory bandwidth limitation

### Performance Optimizations (Planned)

From `prompt_random_walk.md`:

1. **Batched Updates**
   - Don't broadcast every single pixel change
   - Batch multiple terminations
   - Periodic sync intervals

2. **Local Caching**
   - Workers maintain black pixel cache
   - Only refresh on explicit updates
   - Fast neighbor checking

3. **Non-blocking Communication**
   - Workers don't wait for ACK
   - Continue processing with stale state
   - Accept "approximate" synchronization

4. **Smart Work Distribution**
   - Queue prioritizes walkers by position
   - Spread walkers across grid regions
   - Minimize contention hotspots

### Approximate vs Exact Simulation

**Key Trade-off** (from prompt_random_walk.md lines 88-96):

> "the simulation is an approximation in async mode cos the global updates are nearly in real time but real time is not guaranted."

**Sync Mode (1 worker)**:
- ✅ Exact: Global state always current
- ❌ Slow: Serial execution
- Use case: Small grids, accuracy critical

**Async Mode (2+ workers)**:
- ✅ Fast: Parallel execution
- ⚠️ Approximate: State updates lag
- Use case: Large grids, speed matters

**The Approximation**:
```
Timeline:
t=0: Worker1 walker terminates, pixel turns black
t=1: Worker1 broadcasts update
t=2: Worker2 receives update (but moved 2 steps with stale state!)
t=3: Worker2 updates cache, continues with current state
```

Between t=0 and t=2, Worker2 operated with outdated grid state. This could cause:
- Walking onto a black pixel that should have stopped it
- Slightly different paths than pure serial simulation
- Different random walk trajectory

**This is acceptable** because:
- Random walks are stochastic anyway
- Statistical properties converge
- Speedup outweighs small inaccuracies
- Final patterns are "close enough"

## Example Simulation Timeline (Theoretical)

### Sync Mode (1 worker, 8 walkers)
```
Step 1: Walker 1 moves (10ms)
Step 2: Walker 2 moves (10ms)
Step 3: Walker 3 moves (10ms)
...
Step 8: Walker 8 moves (10ms)
Total per round: 80ms
```

### Async Mode (3 workers, 8 walkers)
```
Step 1: [Worker1: W1 moves | Worker2: W2 moves | Worker3: W3 moves] (10ms)
Step 2: [Worker1: W4 moves | Worker2: W5 moves | Worker3: W6 moves] (10ms)
Step 3: [Worker1: W7 moves | Worker2: W8 moves | Worker3: idle    ] (10ms)
Total per round: 30ms
Speedup: 2.67x
```

### With Synchronization Overhead
```
Async with sync:
Step 1: [W1, W2, W3 move in parallel] (10ms)
        W1 terminates → broadcast (5ms) → all workers update (2ms)
Step 2: [W4, W5, W6 move] (10ms)
Total per round: ~40-50ms
Speedup: 1.6-2.0x (realistic)
```

## Current Implementation (v1.0.0)

**What actually exists**:
```r
# R/simulation.R lines 85-121
while (any(sapply(walkers, function(w) w$active))) {
  for (i in seq_along(walkers)) {  # Serial loop - no parallelism!
    walker <- walkers[[i]]
    if (!walker$active) next

    walker <- step_walker(walker, ...)
    walker <- check_termination(walker, ...)

    if (!walker$active) {
      grid <- set_pixel_black(grid, walker$pos, boundary)
    }

    walkers[[i]] <- walker
  }
}
```

This is a **simple serial loop** processing walkers one at a time. No parallelism whatsoever.

## Why Async Not Implemented

Looking at DESCRIPTION:
```
Suggests:
    duckdb,
    nanonext,
```

These are in **Suggests**, not **Imports**, meaning:
- Optional dependencies
- Not required for core functionality
- Likely not implemented yet

The v1.0.0 release focused on:
1. Getting the basic simulation working
2. Creating the Shinylive dashboard
3. Resolving deployment issues

The parallel/async architecture is **future work**.

## Summary

### What v1.0.0 Has
- ✅ Basic random walk simulation (works correctly)
- ✅ Shinylive browser dashboard (fully functional)
- ✅ Grid visualization and statistics
- ✅ Multiple walkers (processed serially)
- ✅ Comprehensive documentation

### What v1.0.0 Lacks
- ❌ Parallel worker processes (crew)
- ❌ Async communication (nanonext)
- ❌ Shared state database (DuckDB)
- ❌ Real-time synchronization
- ❌ Actual speedup from parallelism

### Future Work for v2.0.0

To implement the planned architecture:

1. **Add crew for worker management**
   - Move crew from Suggests to Imports
   - Implement worker pool initialization
   - Add work queue and task distribution

2. **Add nanonext for communication**
   - Set up pub/sub pattern for state broadcasts
   - Implement push/pull for job distribution
   - Handle socket lifecycle

3. **Add DuckDB for state**
   - Create in-memory database schema
   - Implement grid state table
   - Add concurrent read/write handling

4. **Implement synchronization**
   - State update broadcasts
   - Local cache invalidation
   - Periodic sync intervals

5. **Add performance benchmarks**
   - Measure actual speedups
   - Compare sync vs async modes
   - Tune batch sizes and sync intervals

### Estimated Implementation Effort

- **Small (1-2 weeks)**: Basic parallel execution with crew
- **Medium (3-4 weeks)**: Add state sync with DuckDB
- **Large (2-3 months)**: Full async architecture with all optimizations

## Conclusion

The random walk package has a well-designed parallel architecture **on paper**, but v1.0.0 implements **only the serial version**. The title "Asynchronous Pixel Walking" describes the **intended** future state, not the current implementation.

The current Shinylive dashboard works perfectly for demonstrating the simulation concept, but runs synchronously in the browser (which is fine for small grids and few walkers).

For production use with large grids and many walkers, the async architecture would need to be implemented to achieve meaningful speedups.
