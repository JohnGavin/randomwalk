# v2.0.0 Async Implementation Plan

**Status**: Tracked in GitHub Issues
**GitHub Issue**: [#20 - v2.0.0: Implement Async/Parallel Simulation Framework](https://github.com/JohnGavin/randomwalk/issues/20)
**Target**: Implement true async/parallel random walk simulation
**Approach**: Simplified architecture without DuckDB

## Implementation Tracking

This plan is now tracked in GitHub issues:
- **Main Issue**: [#20](https://github.com/JohnGavin/randomwalk/issues/20) - v2.0.0 Async Framework
- **Phase 1**: [#21](https://github.com/JohnGavin/randomwalk/issues/21) - Minimal Async Implementation
- **Phase 2**: [#22](https://github.com/JohnGavin/randomwalk/issues/22) - State Synchronization
- **Phase 3**: [#23](https://github.com/JohnGavin/randomwalk/issues/23) - Optimization
- **Phase 4**: [#24](https://github.com/JohnGavin/randomwalk/issues/24) - Testing & Documentation

**Note**: Phases are logical organization, not time estimates. Implementation proceeds as tasks are completed.

**This document serves as the detailed technical reference for the implementation.**

## Decision: Simplified Architecture

After analysis, we've decided to implement async mode **without DuckDB** for v2.0.0.

### Original Plan (DuckDB + nanonext)
- ❌ DuckDB for persistent state
- ✅ nanonext for communication
- ✅ crew for worker management
- **Complexity**: High
- **Dependencies**: 3 new packages

### Revised Plan (nanonext + R environment)
- ✅ R environment for in-memory state
- ✅ nanonext for pub/sub communication
- ✅ crew for worker management
- **Complexity**: Medium
- **Dependencies**: 2 new packages

### Rationale

DuckDB adds complexity without clear benefit for this use case:
- Grid state fits easily in memory (20×20 = 400 values)
- No need for SQL queries or transactions
- Random walks don't require persistence
- Simpler = easier to debug and maintain

**DuckDB consideration**: Can revisit for v3.0.0 if needed for very large grids (1000×1000+) or complex spatial queries.

## Architecture Components

### 1. Shared State (R Environment)

```r
# Global environment shared across main process
grid_state_env <- new.env()
grid_state_env$grid <- matrix(0, nrow = grid_size, ncol = grid_size)
grid_state_env$black_pixels <- list()  # Fast lookup
grid_state_env$version <- 0L  # Increment on each update
```

**Benefits**:
- Fast in-memory access
- No serialization overhead
- Native R data structures
- Easy to inspect/debug

### 2. Communication (nanonext)

```r
# Publisher socket (main process)
pub_socket <- nano_socket("pub", listen = "tcp://127.0.0.1:5555")

# Worker subscribes
sub_socket <- nano_socket("sub", dial = "tcp://127.0.0.1:5555")

# Broadcast update
nano_send(pub_socket, list(
  type = "pixel_update",
  position = c(10, 10),
  version = grid_state_env$version
))

# Worker receives
update <- nano_recv(sub_socket, mode = "raw", block = FALSE)
```

**Communication Patterns**:
- **Pub/Sub**: State updates broadcast to all workers
- **Push/Pull**: Job queue for walker assignment
- **Req/Rep**: Worker status queries (optional)

### 3. Worker Management (crew)

```r
library(crew)

# Create worker pool
controller <- crew_controller_local(
  name = "random_walk_workers",
  workers = 4,
  seconds_idle = 300  # Keep alive for 5 minutes
)

# Start workers
controller$start()

# Push walker jobs
for (walker_id in seq_len(n_walkers)) {
  controller$push(
    command = step_walker_async(walker_id, grid_state_env$version),
    data = list(
      walker_id = walker_id,
      neighborhood = neighborhood,
      boundary = boundary
    )
  )
}

# Collect results
results <- controller$pop()
```

**Worker Lifecycle**:
1. Controller spawns R process
2. Worker initializes local cache
3. Worker pulls job from queue
4. Worker executes walker steps
5. Worker reports results
6. Worker pulls next job or waits
7. Controller terminates idle workers

## Implementation Phases

### Phase 1: Minimal Async (1-2 weeks)

**Goal**: Get basic parallel execution working

**Tasks**:
- [ ] Add crew to Imports in DESCRIPTION
- [ ] Add nanonext to Imports in DESCRIPTION
- [ ] Create `R/async_controller.R`:
  - `create_controller()` - Initialize crew controller
  - `create_pub_socket()` - Set up nanonext publisher
  - `cleanup_async()` - Shutdown workers and sockets
- [ ] Create `R/async_worker.R`:
  - `worker_init()` - Initialize worker with sub socket
  - `worker_step_walker()` - Execute walker step
  - `worker_check_updates()` - Check for grid updates
- [ ] Modify `R/simulation.R`:
  - Add `if (workers > 0)` branch for async mode
  - Keep existing sync code for `workers = 0`
- [ ] Add tests in `tests/testthat/test-async.R`:
  - Test controller startup/shutdown
  - Test job distribution
  - Test basic 2-worker simulation

**Deliverable**: Basic parallel execution (no optimization)

**Expected Speedup**: 1.5-1.8x with 2 workers

### Phase 2: State Synchronization (1 week)

**Goal**: Implement efficient grid state updates

**Tasks**:
- [ ] Create `R/grid_state.R`:
  - `create_grid_env()` - Initialize shared environment
  - `update_pixel()` - Mark pixel black, increment version
  - `broadcast_update()` - Send via nanonext
  - `get_black_neighbors()` - Fast neighbor lookup
- [ ] Implement worker cache:
  - `worker_cache$black_pixels` - Local copy
  - `worker_cache$version` - Track state version
  - `refresh_cache()` - Pull updates when version mismatch
- [ ] Add cache invalidation:
  - Workers check version before each step
  - Refresh only if outdated
  - Batch multiple updates

**Deliverable**: Workers stay synchronized with <10ms lag

**Expected Speedup**: 1.7-2.0x with 2 workers, 2.5-3.0x with 4 workers

### Phase 3: Optimization (1-2 weeks)

**Goal**: Minimize synchronization overhead

**Tasks**:
- [ ] Implement batched updates:
  - Accumulate multiple pixel changes
  - Broadcast every N updates or T seconds
  - Trade freshness for reduced overhead
- [ ] Add spatial partitioning:
  - Assign walkers to workers by grid region
  - Minimize contention on same pixels
  - Reduce cross-worker interference
- [ ] Non-blocking communication:
  - Use `block = FALSE` in nano_recv
  - Workers continue with stale state if no update
  - Periodic sync rather than every step
- [ ] Benchmark and tune:
  - Measure sync overhead vs computation time
  - Optimize batch sizes
  - Find optimal update frequency

**Deliverable**: Near-linear speedup for 2-4 workers

**Expected Speedup**: 1.8-2.0x with 2 workers, 3.0-3.5x with 4 workers, 4.0-5.0x with 8 workers

### Phase 4: Testing & Documentation (1 week)

**Goal**: Production-ready async mode

**Tasks**:
- [ ] Comprehensive test suite:
  - Test 1, 2, 4, 8, 16 workers
  - Test with different grid sizes
  - Test boundary conditions
  - Test worker failures/restarts
- [ ] Performance benchmarks:
  - Compare sync vs async modes
  - Measure speedup across configurations
  - Identify bottlenecks
- [ ] Documentation:
  - Update README with async usage
  - Add vignette on parallel performance
  - Document when to use sync vs async
- [ ] Update Shinylive dashboard:
  - Add worker count slider (disabled in browser)
  - Show async mode status
  - Display worker statistics

**Deliverable**: v2.0.0 release with async mode

## Implementation Details

### Shared Grid State

```r
# R/grid_state.R

#' Create Shared Grid Environment
create_grid_env <- function(grid_size) {
  env <- new.env()
  env$grid <- matrix(0, nrow = grid_size, ncol = grid_size)
  env$grid[ceiling(grid_size/2), ceiling(grid_size/2)] <- 1  # Center black
  env$black_pixels <- list(c(ceiling(grid_size/2), ceiling(grid_size/2)))
  env$version <- 1L
  env$lock <- mutex()  # For thread safety
  env
}

#' Update Pixel (Thread-safe)
update_pixel <- function(grid_env, pos) {
  lock(grid_env$lock)
  on.exit(unlock(grid_env$lock))

  if (grid_env$grid[pos[1], pos[2]] == 0) {
    grid_env$grid[pos[1], pos[2]] <- 1
    grid_env$black_pixels[[length(grid_env$black_pixels) + 1]] <- pos
    grid_env$version <- grid_env$version + 1L
    return(TRUE)  # Update made
  }
  return(FALSE)  # Already black
}

#' Get Black Neighbors (Fast Lookup)
get_black_neighbors <- function(grid_env, pos, neighborhood) {
  offsets <- if (neighborhood == "4-hood") {
    list(c(-1,0), c(1,0), c(0,-1), c(0,1))
  } else {
    list(c(-1,-1), c(-1,0), c(-1,1), c(0,-1),
         c(0,1), c(1,-1), c(1,0), c(1,1))
  }

  # Check each neighbor against black_pixels list
  neighbors <- lapply(offsets, function(off) pos + off)
  black <- sapply(neighbors, function(n) {
    any(sapply(grid_env$black_pixels, function(bp) {
      all(bp == n)
    }))
  })

  neighbors[black]
}
```

### Worker Communication

```r
# R/async_worker.R

#' Initialize Worker
worker_init <- function(sub_socket_url) {
  # Subscribe to updates
  sub_socket <- nano_socket("sub", dial = sub_socket_url)

  # Initialize local cache
  cache <- new.env()
  cache$black_pixels <- list()
  cache$version <- 0L

  list(socket = sub_socket, cache = cache)
}

#' Check for Grid Updates
worker_check_updates <- function(worker, grid_env) {
  # Non-blocking check for messages
  msg <- nano_recv(worker$socket, mode = "raw", block = FALSE)

  if (!is.null(msg)) {
    update <- unserialize(msg)

    if (update$version > worker$cache$version) {
      # Newer state available, refresh cache
      worker$cache$black_pixels <- grid_env$black_pixels
      worker$cache$version <- grid_env$version
      logger::log_debug("Worker cache updated to version {update$version}")
    }
  }

  worker
}

#' Worker Step Function
worker_step_walker <- function(walker, neighborhood, boundary,
                                grid_env, worker) {
  # Check for updates before step
  worker <- worker_check_updates(worker, grid_env)

  # Move walker
  walker <- step_walker(walker, neighborhood, boundary)

  # Check termination (using cached black pixels)
  has_black_neighbor <- length(
    get_black_neighbors(grid_env, walker$pos, neighborhood)
  ) > 0

  if (has_black_neighbor) {
    walker$active <- FALSE
    walker$termination_reason <- "touched_black_neighbor"

    # Update global state
    if (update_pixel(grid_env, walker$pos)) {
      # Broadcast update
      broadcast_update(pub_socket, walker$pos, grid_env$version)
    }
  }

  walker
}
```

### Broadcast Mechanism

```r
# R/async_controller.R

#' Create Publisher Socket
create_pub_socket <- function(port = 5555) {
  url <- sprintf("tcp://127.0.0.1:%d", port)
  nano_socket("pub", listen = url)
}

#' Broadcast State Update
broadcast_update <- function(pub_socket, pos, version) {
  msg <- list(
    type = "pixel_update",
    position = pos,
    version = version,
    timestamp = Sys.time()
  )

  nano_send(pub_socket, serialize(msg, NULL), mode = "raw")
  logger::log_trace("Broadcasted update: v{version} at ({pos[1]},{pos[2]})")
}
```

## Configuration

### run_simulation() Parameters

```r
run_simulation <- function(
  grid_size = 10,
  n_walkers = 5,
  neighborhood = "4-hood",
  boundary = "terminate",
  workers = 0,           # 0 = sync, 1+ = async
  max_steps = 10000L,
  update_batch = 1,      # Batch N updates before broadcast
  update_interval = 0.1, # Or broadcast every T seconds
  verbose = FALSE
)
```

### Recommended Settings

**Small grids (≤50×50), few walkers (≤10)**:
- `workers = 0` (sync mode)
- Overhead exceeds benefit

**Medium grids (50-200), many walkers (10-50)**:
- `workers = 2-4` (async mode)
- `update_batch = 5-10`
- `update_interval = 0.05`

**Large grids (200+), many walkers (50+)**:
- `workers = 4-8` (async mode)
- `update_batch = 20-50`
- `update_interval = 0.1`

## Testing Strategy

### Unit Tests

```r
# tests/testthat/test-async.R

test_that("controller starts and stops", {
  controller <- create_controller(workers = 2)
  expect_true(controller$started)

  cleanup_async(controller)
  expect_false(controller$started)
})

test_that("workers receive broadcasts", {
  grid_env <- create_grid_env(10)
  pub_socket <- create_pub_socket(5555)

  # Simulate worker
  worker <- worker_init("tcp://127.0.0.1:5555")

  # Broadcast update
  broadcast_update(pub_socket, c(5, 5), 2)

  Sys.sleep(0.1)  # Allow time for message

  # Worker should receive
  worker <- worker_check_updates(worker, grid_env)
  expect_equal(worker$cache$version, 2)
})
```

### Integration Tests

```r
test_that("async simulation produces correct results", {
  # Run same simulation in sync and async
  set.seed(123)
  sync_result <- run_simulation(
    grid_size = 20,
    n_walkers = 8,
    workers = 0  # Sync
  )

  set.seed(123)
  async_result <- run_simulation(
    grid_size = 20,
    n_walkers = 8,
    workers = 2  # Async
  )

  # Results should be similar (not identical due to async timing)
  expect_equal(sync_result$statistics$total_walkers,
               async_result$statistics$total_walkers)

  # Black pixel counts should be close (within 10%)
  expect_lt(
    abs(sync_result$statistics$black_pixels -
        async_result$statistics$black_pixels),
    sync_result$statistics$black_pixels * 0.1
  )
})
```

### Performance Benchmarks

```r
# benchmarks/benchmark_async.R

library(bench)

results <- bench::mark(
  sync = run_simulation(grid_size = 100, n_walkers = 20, workers = 0),
  async_2 = run_simulation(grid_size = 100, n_walkers = 20, workers = 2),
  async_4 = run_simulation(grid_size = 100, n_walkers = 20, workers = 4),
  async_8 = run_simulation(grid_size = 100, n_walkers = 20, workers = 8),
  iterations = 10,
  check = FALSE
)

# Calculate speedups
results$speedup <- results$median[1] / results$median
print(results[, c("expression", "median", "speedup")])
```

## Migration Path

### v1.0.0 → v2.0.0

**Breaking Changes**: None (async is opt-in via `workers` parameter)

**New Features**:
- Async mode with crew + nanonext
- Performance benchmarks
- Worker statistics

**Deprecated**: Nothing

**Removed**: Nothing

**User Impact**: Zero for existing code (default `workers = 0` is sync)

## Success Criteria

### Functional Requirements
- ✅ Async mode produces valid random walks
- ✅ Workers synchronize within 10ms
- ✅ No race conditions or deadlocks
- ✅ Graceful handling of worker failures
- ✅ Clean shutdown releases all resources

### Performance Requirements
- ✅ 2 workers: 1.5-2.0x speedup
- ✅ 4 workers: 2.5-3.5x speedup
- ✅ 8 workers: 3.5-5.0x speedup
- ✅ Sync overhead < 15% of total time

### Code Quality Requirements
- ✅ Test coverage > 80%
- ✅ No R CMD check warnings
- ✅ Documentation complete
- ✅ Vignette with examples

## Implementation Phases

| Phase | Deliverable |
|-------|-------------|
| Phase 1 | Basic async (1.5x speedup) |
| Phase 2 | State sync (2.5x speedup) |
| Phase 3 | Optimization (4x speedup) |
| Phase 4 | Testing & docs |
| **Complete** | **v2.0.0 release** |

## Future Considerations (v3.0.0+)

### When DuckDB Makes Sense

Consider adding DuckDB if:
- Grid size > 1000×1000 (1M+ pixels)
- Need SQL queries on grid state
- Want persistent checkpoints
- Complex spatial analytics required

### Other Enhancements

- GPU acceleration for large grids (OpenCL/CUDA)
- Distributed workers across multiple machines (ZMQ)
- Real-time 3D visualization (rgl/threejs)
- Alternative termination conditions (custom rules)

## References

- **crew**: https://wlandau.github.io/crew/
- **nanonext**: https://shikokuchuo.net/nanonext/
- **Amdahl's Law**: https://en.wikipedia.org/wiki/Amdahl%27s_law
- **ZMQ Patterns**: https://zguide.zeromq.org/docs/chapter2/
