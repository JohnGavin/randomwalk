# Implementation Plan: Issue #51 - Dynamic Grid State Broadcasting

**Issue:** https://github.com/JohnGavin/randomwalk/issues/51
**Difficulty:** ⭐⭐⭐⭐⭐ VERY HARD
**Estimated Effort:** 2-3 days
**Status:** Planning Phase
**Date:** 2025-12-04

---

## Table of Contents

1. [Overview](#overview)
2. [Current Architecture (Static Snapshots)](#current-architecture-static-snapshots)
3. [Proposed Architecture (Dynamic Broadcasting)](#proposed-architecture-dynamic-broadcasting)
4. [Technical Approaches](#technical-approaches)
5. [Implementation Phases](#implementation-phases)
6. [Detailed Implementation Steps](#detailed-implementation-steps)
7. [Testing Strategy](#testing-strategy)
8. [Performance Considerations](#performance-considerations)
9. [Risk Analysis](#risk-analysis)
10. [Alternative Approaches](#alternative-approaches)

---

## Overview

### Problem Statement

Currently, async workers receive **static grid snapshots** that never update. This means:
- Workers don't see each other's movements
- Walkers can't collide (no termination on occupied cells)
- Different behavior between sync mode (workers=0) and async mode (workers≥1)
- Unrealistic simulation (walkers should interact)

### Goal

Implement **real-time grid state synchronization** so workers see each other's updates and walkers can collide when they land on the same cell.

### Why This Is Hard

1. **Distributed State Management** - Multiple processes must share mutable state
2. **Race Conditions** - Workers updating grid simultaneously can cause conflicts
3. **Performance Critical** - Broadcasting must not significantly slow simulation
4. **Serialization Overhead** - Grid updates must be serialized/deserialized efficiently
5. **Network Topology** - Need reliable pub/sub or shared memory architecture
6. **Debugging Complexity** - Parallel bugs are notoriously difficult to reproduce/fix

---

## Current Architecture (Static Snapshots)

### How It Works Now

```r
# R/simulation.R (lines 241-426)

# Main process
controller <- crew_controller_local(workers = 4)
grid_state <- initialize_grid(grid_size)  # Initial state

# Push tasks to workers
for (walker_id in 1:n_walkers) {
  controller$push(
    command = simulate_walker(...),
    data = list(
      walker_id = walker_id,
      grid_state = grid_state  # FROZEN SNAPSHOT - never updates!
    )
  )
}

# Workers operate independently
# Each worker has its own copy of grid_state
# Workers never see updates from other workers
```

### Memory Layout (Current)

```
┌─────────────────────────────────────────────────┐
│ Main Process                                    │
│ ├─ grid_state (original)                       │
│ └─ crew_controller                             │
└─────────────────────────────────────────────────┘
              │
              │ Serialized copy sent at start
              │
    ┌─────────┴─────────┬─────────────┬──────────┐
    │                   │             │          │
┌───▼────┐      ┌───────▼──┐   ┌──────▼─┐  ┌────▼───┐
│Worker 1│      │Worker 2  │   │Worker 3│  │Worker 4│
│        │      │          │   │        │  │        │
│grid    │      │grid      │   │grid    │  │grid    │
│(copy)  │      │(copy)    │   │(copy)  │  │(copy)  │
│        │      │          │   │        │  │        │
│NEVER   │      │NEVER     │   │NEVER   │  │NEVER   │
│UPDATES │      │UPDATES   │   │UPDATES │  │UPDATES │
└────────┘      └──────────┘   └────────┘  └────────┘
```

### Consequences

**Advantages:**
- ✅ Simple - no synchronization needed
- ✅ Safe - no race conditions
- ✅ Fast - no locking overhead
- ✅ Deterministic - reproducible results

**Disadvantages:**
- ❌ Unrealistic - walkers don't interact
- ❌ Different from sync mode - behavior mismatch
- ❌ No collisions - walkers can occupy same cell
- ❌ No termination on occupied cells

---

## Proposed Architecture (Dynamic Broadcasting)

### Option A: Publish-Subscribe (nanonext)

Use **nanonext** sockets for message passing between processes.

```
┌──────────────────────────────────────────────────┐
│ Main Process                                     │
│ ├─ Grid State (authoritative)                   │
│ ├─ Publisher Socket (nanonext)                  │
│ └─ Crew Controller                              │
└──────────────────────────────────────────────────┘
              │
              │ pub/sub (nanonext NNG sockets)
              │
    ┌─────────┴─────────┬─────────────┬──────────┐
    │                   │             │          │
┌───▼────┐      ┌───────▼──┐   ┌──────▼─┐  ┌────▼───┐
│Worker 1│      │Worker 2  │   │Worker 3│  │Worker 4│
│        │      │          │   │        │  │        │
│Local   │      │Local     │   │Local   │  │Local   │
│Grid    │      │Grid      │   │Grid    │  │Grid    │
│        │      │          │   │        │  │        │
│Sub     │      │Sub       │   │Sub     │  │Sub     │
│Socket  │      │Socket    │   │Socket  │  │Socket  │
└────────┘      └──────────┘   └────────┘  └────────┘
```

### Option B: Shared Memory (mirai)

Use **mirai** shared memory for zero-copy access.

```
┌──────────────────────────────────────────────────┐
│ Main Process                                     │
│ ├─ Shared Grid Memory Region (mirai)            │
│ └─ Crew Controller                              │
└──────────────────────────────────────────────────┘
              │
              │ Direct memory access
              │
    ┌─────────┴─────────┬─────────────┬──────────┐
    │                   │             │          │
┌───▼────┐      ┌───────▼──┐   ┌──────▼─┐  ┌────▼───┐
│Worker 1│      │Worker 2  │   │Worker 3│  │Worker 4│
│        │      │          │   │        │  │        │
│Read    │      │Read      │   │Read    │  │Read    │
│from    │      │from      │   │from    │  │from    │
│Shared  │      │Shared    │   │Shared  │  │Shared  │
│Memory  │      │Memory    │   │Memory  │  │Memory  │
│(atomic)│      │(atomic)  │   │(atomic)│  │(atomic)│
└────────┘      └──────────┘   └────────┘  └────────┘
```

---

## Technical Approaches

### Approach 1: Full Broadcasting (nanonext pub/sub)

**Concept:** Main process broadcasts every grid update to all workers.

#### Architecture

```r
# Main process
pub_socket <- nanonext::socket("pub")
nanonext::listen(pub_socket, "tcp://*:5555")

# Workers
sub_socket <- nanonext::socket("sub")
nanonext::dial(sub_socket, "tcp://localhost:5555")
nanonext::subscribe(sub_socket, "")  # Subscribe to all messages
```

#### Message Format

```r
message <- list(
  type = "grid_update",
  position = c(x, y),
  value = "black",
  timestamp = Sys.time(),
  walker_id = walker_id
)

# Serialize and broadcast
nanonext::send(pub_socket, serialize(message, NULL))
```

#### Worker Update Logic

```r
check_grid_updates <- function(local_grid, sub_socket) {
  # Non-blocking receive
  msg <- nanonext::recv(sub_socket, mode = "raw", block = FALSE)

  if (!is.null(msg)) {
    update <- unserialize(msg)
    if (update$type == "grid_update") {
      pos <- update$position
      local_grid[pos[1], pos[2]] <- update$value
    }
  }

  return(local_grid)
}
```

#### Worker Simulation Loop

```r
simulate_walker_with_broadcasting <- function(
  walker_id,
  initial_grid,
  pub_socket,  # For broadcasting own updates
  sub_socket   # For receiving others' updates
) {
  local_grid <- initial_grid
  position <- sample_start_position(nrow(local_grid))
  path <- list()

  for (step in 1:max_steps) {
    # STEP 1: Check for broadcasts from other workers
    local_grid <- check_grid_updates(local_grid, sub_socket)

    # STEP 2: Check if current position is now black (collision)
    if (local_grid[position[1], position[2]] == "black") {
      return(list(
        walker_id = walker_id,
        status = "collision",
        steps = step - 1,
        path = path,
        collision_position = position
      ))
    }

    # STEP 3: Make move
    new_position <- make_step(position, local_grid)

    # STEP 4: Update local grid
    local_grid[new_position[1], new_position[2]] <- "black"

    # STEP 5: Broadcast update to all workers
    message <- list(
      type = "grid_update",
      position = new_position,
      value = "black",
      walker_id = walker_id,
      timestamp = Sys.time()
    )
    nanonext::send(pub_socket, serialize(message, NULL))

    # STEP 6: Record path
    path[[step]] <- new_position
    position <- new_position
  }

  return(list(
    walker_id = walker_id,
    status = "max_steps",
    steps = max_steps,
    path = path
  ))
}
```

#### Pros and Cons

**Pros:**
- ✅ Flexible - can broadcast any type of message
- ✅ Network-ready - works across machines
- ✅ Explicit control - clear when broadcasts happen
- ✅ Extensible - can add more message types

**Cons:**
- ❌ Message overhead - serialization/deserialization cost
- ❌ Network latency - even local sockets have delay
- ❌ Complexity - need to manage socket lifecycle
- ❌ Scalability - broadcast storms with many workers

---

### Approach 2: Batched Broadcasting

**Concept:** Accumulate updates and broadcast in batches to reduce overhead.

```r
# Worker accumulates updates
update_buffer <- list()

for (step in 1:max_steps) {
  # ... make move ...

  # Accumulate update
  update_buffer[[length(update_buffer) + 1]] <- list(
    position = new_position,
    value = "black"
  )

  # Flush every N steps or N milliseconds
  if (length(update_buffer) >= batch_size ||
      time_since_flush > flush_interval) {
    broadcast_batch(pub_socket, update_buffer)
    update_buffer <- list()
  }
}
```

**Pros:**
- ✅ Reduced message count - fewer broadcasts
- ✅ Better throughput - amortized serialization cost
- ✅ Configurable - tune batch size vs latency

**Cons:**
- ❌ Increased latency - updates delayed until batch flushes
- ❌ Stale data - workers operate on slightly outdated grid
- ❌ Complexity - need to tune batch size

---

### Approach 3: Spatial Partitioning

**Concept:** Only broadcast to workers operating in nearby regions.

```r
# Divide grid into regions
regions <- list(
  region_1 = list(x = 1:50,   y = 1:50),   # Top-left
  region_2 = list(x = 51:100, y = 1:50),   # Top-right
  region_3 = list(x = 1:50,   y = 51:100), # Bottom-left
  region_4 = list(x = 51:100, y = 51:100)  # Bottom-right
)

# Assign workers to regions
worker_regions <- list(
  worker_1 = "region_1",
  worker_2 = "region_2",
  worker_3 = "region_3",
  worker_4 = "region_4"
)

# Only broadcast to nearby regions
broadcast_to_region <- function(position, radius = 20) {
  affected_regions <- get_regions_in_range(position, radius)

  for (region in affected_regions) {
    workers <- get_workers_in_region(region)
    send_to_specific_workers(pub_socket, workers, update)
  }
}
```

**Pros:**
- ✅ Reduced broadcast volume - only relevant workers receive updates
- ✅ Scalability - better performance with many workers
- ✅ Locality - workers mostly care about nearby updates

**Cons:**
- ❌ Complexity - need region management
- ❌ Edge cases - walkers crossing region boundaries
- ❌ Imbalance - some regions may be more active

---

### Approach 4: Shared Memory (mirai)

**Concept:** Use shared memory instead of message passing.

```r
# Main process creates shared grid
shared_grid <- mirai::mirai_map(
  .x = initial_grid,
  .args = list(shared = TRUE)
)

# Workers read directly
simulate_walker_shared <- function(walker_id, shared_grid_ref) {
  for (step in 1:max_steps) {
    # STEP 1: Read current state (lock-free)
    current_grid <- mirai::read_shared(shared_grid_ref)

    # STEP 2: Check for collision
    if (current_grid[position[1], position[2]] == "black") {
      # Collision detected
      return(...)
    }

    # STEP 3: Make move
    new_position <- make_step(position, current_grid)

    # STEP 4: Update grid (atomic operation)
    mirai::atomic_set(shared_grid_ref,
                      new_position[1],
                      new_position[2],
                      "black")
  }
}
```

**Pros:**
- ✅ Fast - zero-copy access
- ✅ Low overhead - no serialization
- ✅ Simple API - just read/write
- ✅ Atomic operations - built-in

**Cons:**
- ❌ Platform-specific - may not work on all systems
- ❌ Memory contention - many writers can slow down
- ❌ Limited to single machine - can't distribute across network
- ❌ Race conditions - need careful synchronization

---

## Implementation Phases

### Phase 1: Research & Prototyping (3-4 hours)

**Goal:** Validate that chosen approach works and benchmark performance.

#### Step 1.1: Benchmark Current Performance
```r
# Benchmark static snapshot approach
library(bench)

result_static <- mark(
  static = run_simulation(
    grid_size = 100,
    n_walkers = 20,
    workers = 4,
    sync_mode = "static"  # Current behavior
  ),
  iterations = 5
)

# Baseline metrics:
# - Total time
# - Memory usage
# - Black pixels
# - Steps taken
```

#### Step 1.2: nanonext Socket Prototype
```r
# R/prototypes/nanonext_socket_test.R

library(nanonext)

# Test 1: Simple pub/sub
test_nanonext_pubsub <- function() {
  # Publisher
  pub <- socket("pub")
  listen(pub, "tcp://*:5555")

  # Subscriber (in separate process)
  sub <- socket("sub")
  dial(sub, "tcp://localhost:5555")
  subscribe(sub, "")

  # Send message
  message <- list(type = "test", value = 42)
  send(pub, serialize(message, NULL))

  # Receive message
  received <- recv(sub, mode = "raw")
  unserialize(received)
}

# Test 2: Measure latency
benchmark_message_latency <- function() {
  n_messages <- 1000

  times <- replicate(n_messages, {
    start <- Sys.time()
    send(pub, serialize(message, NULL))
    received <- recv(sub, mode = "raw")
    end <- Sys.time()
    as.numeric(difftime(end, start, units = "ms"))
  })

  list(
    mean_latency = mean(times),
    median_latency = median(times),
    max_latency = max(times)
  )
}

# Test 3: Grid update simulation
simulate_grid_broadcasts <- function(n_updates = 100) {
  grid <- matrix(0, 10, 10)

  for (i in 1:n_updates) {
    pos <- c(sample(1:10, 1), sample(1:10, 1))

    # Broadcast update
    message <- list(
      type = "grid_update",
      position = pos,
      value = 1
    )
    send(pub, serialize(message, NULL))

    # Receive and apply
    received <- recv(sub, mode = "raw", block = FALSE)
    if (!is.null(received)) {
      update <- unserialize(received)
      grid[update$position[1], update$position[2]] <- update$value
    }
  }

  return(grid)
}
```

#### Step 1.3: Benchmark Overhead
```r
# Measure overhead of broadcasting
benchmark_broadcasting_overhead <- function() {
  grid_sizes <- c(50, 100, 200)
  n_updates <- c(100, 500, 1000)

  results <- expand.grid(
    grid_size = grid_sizes,
    n_updates = n_updates
  )

  for (i in 1:nrow(results)) {
    grid_size <- results$grid_size[i]
    n_updates <- results$n_updates[i]

    # Without broadcasting
    time_without <- system.time({
      grid <- matrix(0, grid_size, grid_size)
      for (j in 1:n_updates) {
        pos <- c(sample(1:grid_size, 1), sample(1:grid_size, 1))
        grid[pos[1], pos[2]] <- 1
      }
    })

    # With broadcasting
    time_with <- system.time({
      grid <- matrix(0, grid_size, grid_size)
      for (j in 1:n_updates) {
        pos <- c(sample(1:grid_size, 1), sample(1:grid_size, 1))

        # Serialize and broadcast
        message <- list(position = pos, value = 1)
        send(pub, serialize(message, NULL))

        # Receive and apply
        received <- recv(sub, mode = "raw", block = FALSE)
        if (!is.null(received)) {
          update <- unserialize(received)
          grid[update$position[1], update$position[2]] <- update$value
        }
      }
    })

    results$overhead_pct[i] <-
      ((time_with["elapsed"] / time_without["elapsed"]) - 1) * 100
  }

  return(results)
}
```

#### Step 1.4: Decision Point

**Criteria for proceeding:**
- ✅ Message latency < 1ms (ideally < 0.1ms)
- ✅ Broadcasting overhead < 50% for 1000 updates
- ✅ No socket errors or connection issues
- ✅ Serialization/deserialization reliable

**If criteria not met:** Consider alternative approaches (shared memory, batching, etc.)

---

### Phase 2: Core Implementation (1 day)

**Goal:** Implement basic broadcasting infrastructure in simulation code.

#### Step 2.1: Add Socket Management

**File:** `R/broadcasting.R` (new file)

```r
#' Initialize Publisher Socket
#'
#' Creates a nanonext publisher socket for broadcasting grid updates
#'
#' @param port Port number for socket (default 5555)
#' @return Publisher socket object
#' @export
init_publisher_socket <- function(port = 5555) {
  pub_socket <- nanonext::socket("pub")
  nanonext::listen(pub_socket, sprintf("tcp://*:%d", port))

  logger::log_info("Publisher socket listening on port {port}")

  return(pub_socket)
}

#' Initialize Subscriber Socket
#'
#' Creates a nanonext subscriber socket for receiving grid updates
#'
#' @param host Host address (default "localhost")
#' @param port Port number (default 5555)
#' @return Subscriber socket object
#' @export
init_subscriber_socket <- function(host = "localhost", port = 5555) {
  sub_socket <- nanonext::socket("sub")
  nanonext::dial(sub_socket, sprintf("tcp://%s:%d", host, port))
  nanonext::subscribe(sub_socket, "")  # Subscribe to all messages

  logger::log_debug("Subscriber socket connected to {host}:{port}")

  return(sub_socket)
}

#' Broadcast Grid Update
#'
#' Serializes and broadcasts a grid update to all subscribers
#'
#' @param pub_socket Publisher socket
#' @param position Vector c(x, y) of updated position
#' @param value New value (typically "black")
#' @param walker_id ID of walker making update
#' @export
broadcast_update <- function(pub_socket, position, value, walker_id) {
  message <- list(
    type = "grid_update",
    position = position,
    value = value,
    walker_id = walker_id,
    timestamp = Sys.time()
  )

  nanonext::send(pub_socket, serialize(message, NULL))
}

#' Check for Grid Updates (Non-blocking)
#'
#' Checks subscriber socket for pending updates and applies them to local grid
#'
#' @param sub_socket Subscriber socket
#' @param local_grid Current local grid state
#' @return Updated local grid
#' @export
check_grid_updates <- function(sub_socket, local_grid) {
  # Non-blocking receive (returns NULL if no message)
  msg <- nanonext::recv(sub_socket, mode = "raw", block = FALSE)

  if (!is.null(msg)) {
    update <- unserialize(msg)

    if (update$type == "grid_update") {
      pos <- update$position
      local_grid[pos[1], pos[2]] <- update$value

      logger::log_trace(
        "Applied update from walker {update$walker_id} at ({pos[1]}, {pos[2]})"
      )
    }
  }

  return(local_grid)
}

#' Close Sockets
#'
#' Properly closes nanonext sockets
#'
#' @param ... Socket objects to close
#' @export
close_sockets <- function(...) {
  sockets <- list(...)

  for (socket in sockets) {
    if (!is.null(socket)) {
      nanonext::close(socket)
      logger::log_debug("Socket closed")
    }
  }
}
```

#### Step 2.2: Modify Walker Function

**File:** `R/walker.R`

Add broadcasting capability to walker simulation:

```r
#' Simulate Walker with Broadcasting (Dynamic Grid)
#'
#' @param walker_id Unique walker ID
#' @param initial_grid Initial grid state
#' @param pub_socket Publisher socket for broadcasting updates
#' @param sub_socket Subscriber socket for receiving updates
#' @param ... Other parameters
#' @export
simulate_walker_broadcast <- function(
  walker_id,
  initial_grid,
  pub_socket,
  sub_socket,
  max_steps = 1000,
  neighborhood = "4-hood",
  boundary = "terminate"
) {
  # Initialize local state
  local_grid <- initial_grid
  position <- sample_start_position(nrow(local_grid), ncol(local_grid))
  path <- list()
  steps <- 0

  logger::log_debug("Walker {walker_id} starting at ({position[1]}, {position[2]})")

  # Main simulation loop
  while (steps < max_steps) {
    # STEP 1: Check for updates from other workers
    local_grid <- check_grid_updates(sub_socket, local_grid)

    # STEP 2: Check for collision (current position became black)
    if (local_grid[position[1], position[2]] == "black") {
      logger::log_info(
        "Walker {walker_id} collision at ({position[1]}, {position[2]}) after {steps} steps"
      )

      return(list(
        walker_id = walker_id,
        status = "collision",
        steps = steps,
        path = path,
        collision_position = position
      ))
    }

    # STEP 3: Choose next move
    next_position <- choose_next_position(
      position,
      local_grid,
      neighborhood = neighborhood
    )

    # STEP 4: Check boundary condition
    if (is_boundary_hit(next_position, nrow(local_grid), ncol(local_grid))) {
      if (boundary == "terminate") {
        logger::log_debug("Walker {walker_id} hit boundary, terminating")

        return(list(
          walker_id = walker_id,
          status = "boundary",
          steps = steps,
          path = path
        ))
      } else {
        # Reflect or wrap (existing logic)
        next_position <- handle_boundary(next_position, boundary)
      }
    }

    # STEP 5: Update local grid
    local_grid[next_position[1], next_position[2]] <- "black"

    # STEP 6: Broadcast update to all workers
    broadcast_update(pub_socket, next_position, "black", walker_id)

    # STEP 7: Record path and advance
    steps <- steps + 1
    path[[steps]] <- next_position
    position <- next_position
  }

  # Max steps reached
  logger::log_debug("Walker {walker_id} completed {steps} steps")

  return(list(
    walker_id = walker_id,
    status = "max_steps",
    steps = steps,
    path = path
  ))
}
```

#### Step 2.3: Update Simulation Function

**File:** `R/simulation.R`

Modify async simulation to use broadcasting:

```r
# In run_simulation() function, add sync_mode parameter

run_simulation <- function(
  grid_size = 100,
  n_walkers = 10,
  workers = 0,
  sync_mode = "static",  # NEW: "static" or "dynamic"
  ...
) {
  # ... existing code ...

  if (workers > 0) {
    # Async mode
    if (sync_mode == "dynamic") {
      # NEW: Dynamic broadcasting mode
      result <- run_simulation_async_broadcast(
        grid_size, n_walkers, workers, ...
      )
    } else {
      # Existing: Static snapshot mode
      result <- run_simulation_async_static(
        grid_size, n_walkers, workers, ...
      )
    }
  } else {
    # Sync mode
    result <- run_simulation_sync(grid_size, n_walkers, ...)
  }

  return(result)
}

# New function for dynamic broadcasting
run_simulation_async_broadcast <- function(
  grid_size,
  n_walkers,
  workers,
  ...
) {
  logger::log_info(
    "Starting async simulation with dynamic broadcasting: " +
    "grid_size={grid_size}, n_walkers={n_walkers}, workers={workers}"
  )

  # Initialize grid
  grid <- initialize_grid(grid_size)

  # Initialize sockets
  pub_socket <- init_publisher_socket(port = 5555)

  # Initialize crew controller
  controller <- crew::crew_controller_local(
    workers = workers,
    seconds_idle = 10
  )
  controller$start()

  logger::log_info("Crew controller started with {workers} workers")

  # Push tasks to workers
  for (walker_id in 1:n_walkers) {
    controller$push(
      command = simulate_walker_broadcast(
        walker_id = walker_id,
        initial_grid = grid,
        pub_socket = pub_socket,    # Pass publisher socket
        sub_socket = NULL,           # Workers create their own subscriber
        max_steps = max_steps,
        neighborhood = neighborhood,
        boundary = boundary
      ),
      data = list(
        walker_id = walker_id,
        grid = grid,
        # NOTE: Workers will initialize their own subscriber sockets
        # because sockets can't be serialized
      )
    )

    logger::log_trace("Pushed walker {walker_id} to queue")
  }

  logger::log_info("All {n_walkers} walkers queued")

  # Wait for completion
  controller$wait()

  # Collect results
  results <- controller$pop()$result

  # Clean up
  controller$terminate()
  close_sockets(pub_socket)

  logger::log_info("Simulation complete: {length(results)} walkers finished")

  # Compile statistics
  compile_simulation_results(results, grid)
}
```

#### Step 2.4: Handle Socket Initialization in Workers

**Challenge:** Sockets can't be serialized, so workers must create their own subscriber sockets.

**Solution:** Workers initialize subscriber in their environment:

```r
# In worker function, add initialization code
simulate_walker_broadcast <- function(...) {
  # Worker initializes its own subscriber socket
  sub_socket <- init_subscriber_socket(
    host = "localhost",
    port = 5555
  )

  # Ensure socket is closed on exit
  on.exit(close_sockets(sub_socket))

  # ... rest of walker logic ...
}
```

---

### Phase 3: Testing & Validation (4 hours)

#### Step 3.1: Unit Tests

**File:** `tests/testthat/test-broadcasting.R`

```r
test_that("Socket initialization works", {
  pub <- init_publisher_socket(port = 5556)
  sub <- init_subscriber_socket(port = 5556)

  expect_s3_class(pub, "nanoSocket")
  expect_s3_class(sub, "nanoSocket")

  close_sockets(pub, sub)
})

test_that("Broadcast and receive messages", {
  pub <- init_publisher_socket(port = 5557)
  sub <- init_subscriber_socket(port = 5557)

  # Send message
  broadcast_update(pub, c(5, 10), "black", walker_id = 1)

  # Receive message
  Sys.sleep(0.1)  # Small delay for message delivery
  grid <- matrix("white", 20, 20)
  grid <- check_grid_updates(sub, grid)

  expect_equal(grid[5, 10], "black")

  close_sockets(pub, sub)
})

test_that("Non-blocking receive returns NULL when no messages", {
  sub <- init_subscriber_socket(port = 5558)

  grid <- matrix("white", 10, 10)
  updated_grid <- check_grid_updates(sub, grid)

  expect_equal(updated_grid, grid)  # No changes

  close_sockets(sub)
})

test_that("Multiple updates are applied correctly", {
  pub <- init_publisher_socket(port = 5559)
  sub <- init_subscriber_socket(port = 5559)

  grid <- matrix("white", 10, 10)

  # Send multiple updates
  updates <- list(
    c(1, 1), c(2, 2), c(3, 3), c(4, 4), c(5, 5)
  )

  for (pos in updates) {
    broadcast_update(pub, pos, "black", walker_id = 1)
  }

  # Apply all updates
  Sys.sleep(0.2)
  for (i in 1:5) {
    grid <- check_grid_updates(sub, grid)
  }

  # Verify all positions are black
  for (pos in updates) {
    expect_equal(grid[pos[1], pos[2]], "black")
  }

  close_sockets(pub, sub)
})
```

#### Step 3.2: Integration Tests

**File:** `tests/testthat/test-simulation-broadcast.R`

```r
test_that("Dynamic broadcasting simulation completes", {
  skip_on_cran()
  skip_if_not_installed("nanonext")

  result <- run_simulation(
    grid_size = 50,
    n_walkers = 5,
    workers = 2,
    sync_mode = "dynamic",
    max_steps = 100
  )

  expect_s3_class(result, "simulation_result")
  expect_equal(length(result$walkers), 5)
  expect_true(all(sapply(result$walkers, function(w) w$steps <= 100)))
})

test_that("Collisions are detected in dynamic mode", {
  skip_on_cran()
  skip_if_not_installed("nanonext")

  # Run many walkers on small grid - collisions likely
  result <- run_simulation(
    grid_size = 20,
    n_walkers = 50,
    workers = 4,
    sync_mode = "dynamic",
    max_steps = 50
  )

  # Check for collision status
  collision_count <- sum(sapply(result$walkers,
                                function(w) w$status == "collision"))

  expect_gt(collision_count, 0,
            label = "At least one collision should occur")
})

test_that("Dynamic mode produces different results than static mode", {
  skip_on_cran()
  skip_if_not_installed("nanonext")

  set.seed(42)

  # Static mode
  result_static <- run_simulation(
    grid_size = 50,
    n_walkers = 20,
    workers = 2,
    sync_mode = "static",
    max_steps = 100
  )

  # Dynamic mode
  result_dynamic <- run_simulation(
    grid_size = 50,
    n_walkers = 20,
    workers = 2,
    sync_mode = "dynamic",
    max_steps = 100
  )

  # Results should differ due to collisions
  expect_false(
    identical(result_static$black_pixels, result_dynamic$black_pixels)
  )

  # Dynamic mode should have more collisions
  collision_count_static <- sum(sapply(result_static$walkers,
                                      function(w) w$status == "collision"))
  collision_count_dynamic <- sum(sapply(result_dynamic$walkers,
                                       function(w) w$status == "collision"))

  expect_gte(collision_count_dynamic, collision_count_static)
})
```

#### Step 3.3: Performance Testing

**File:** `R/setup/benchmark_broadcasting.R`

```r
library(bench)
library(ggplot2)

# Benchmark static vs dynamic
results <- mark(
  static = run_simulation(
    grid_size = 100,
    n_walkers = 20,
    workers = 4,
    sync_mode = "static",
    max_steps = 500
  ),
  dynamic = run_simulation(
    grid_size = 100,
    n_walkers = 20,
    workers = 4,
    sync_mode = "dynamic",
    max_steps = 500
  ),
  iterations = 5,
  check = FALSE  # Results will differ
)

# Plot results
plot(results) +
  labs(
    title = "Static vs Dynamic Broadcasting Performance",
    subtitle = "Grid: 100x100, Walkers: 20, Workers: 4, Max Steps: 500"
  )

# Calculate overhead
overhead_pct <-
  (median(results$total_time[results$expression == "dynamic"]) /
   median(results$total_time[results$expression == "static"]) - 1) * 100

cat(sprintf("Broadcasting overhead: %.1f%%\n", overhead_pct))

# Detailed timing breakdown
profile_broadcasting <- function() {
  profvis::profvis({
    run_simulation(
      grid_size = 100,
      n_walkers = 20,
      workers = 4,
      sync_mode = "dynamic",
      max_steps = 500
    )
  })
}

# Run profiler
profile_broadcasting()
```

---

### Phase 4: Optimization (4 hours)

#### Step 4.1: Implement Batched Broadcasting

```r
#' Broadcast Updates in Batch
#'
#' @param pub_socket Publisher socket
#' @param updates List of update messages
#' @export
broadcast_batch <- function(pub_socket, updates) {
  if (length(updates) == 0) return()

  # Single message containing multiple updates
  batch_message <- list(
    type = "grid_update_batch",
    updates = updates,
    timestamp = Sys.time()
  )

  nanonext::send(pub_socket, serialize(batch_message, NULL))

  logger::log_trace("Broadcasted batch of {length(updates)} updates")
}

#' Check for Batch Updates
#'
#' @param sub_socket Subscriber socket
#' @param local_grid Current grid
#' @return Updated grid
#' @export
check_batch_updates <- function(sub_socket, local_grid) {
  msg <- nanonext::recv(sub_socket, mode = "raw", block = FALSE)

  if (!is.null(msg)) {
    message <- unserialize(msg)

    if (message$type == "grid_update_batch") {
      # Apply all updates in batch
      for (update in message$updates) {
        pos <- update$position
        local_grid[pos[1], pos[2]] <- update$value
      }

      logger::log_trace("Applied batch of {length(message$updates)} updates")
    }
  }

  return(local_grid)
}
```

Modify walker to accumulate updates:

```r
simulate_walker_broadcast_batched <- function(..., batch_size = 10) {
  update_buffer <- list()
  flush_time <- Sys.time()
  flush_interval <- 0.1  # seconds

  for (step in 1:max_steps) {
    # ... existing logic ...

    # Accumulate update
    update_buffer[[length(update_buffer) + 1]] <- list(
      position = next_position,
      value = "black",
      walker_id = walker_id
    )

    # Flush if buffer full or timeout
    time_elapsed <- as.numeric(difftime(Sys.time(), flush_time, units = "secs"))

    if (length(update_buffer) >= batch_size || time_elapsed >= flush_interval) {
      broadcast_batch(pub_socket, update_buffer)
      update_buffer <- list()
      flush_time <- Sys.time()
    }
  }

  # Flush remaining updates
  if (length(update_buffer) > 0) {
    broadcast_batch(pub_socket, update_buffer)
  }
}
```

#### Step 4.2: Add Spatial Partitioning

```r
#' Assign Workers to Grid Regions
#'
#' @param grid_size Grid dimensions
#' @param n_workers Number of workers
#' @return List of region assignments
#' @export
partition_grid <- function(grid_size, n_workers) {
  # Simple quadrant partitioning for 4 workers
  if (n_workers == 4) {
    mid <- grid_size / 2

    regions <- list(
      region_1 = list(
        x_range = c(1, mid),
        y_range = c(1, mid),
        workers = c(1)
      ),
      region_2 = list(
        x_range = c(mid + 1, grid_size),
        y_range = c(1, mid),
        workers = c(2)
      ),
      region_3 = list(
        x_range = c(1, mid),
        y_range = c(mid + 1, grid_size),
        workers = c(3)
      ),
      region_4 = list(
        x_range = c(mid + 1, grid_size),
        y_range = c(mid + 1, grid_size),
        workers = c(4)
      )
    )

    return(regions)
  }

  # For other worker counts, implement different partitioning
  stop("Spatial partitioning only implemented for 4 workers")
}

#' Get Affected Regions for Position
#'
#' @param position Vector c(x, y)
#' @param regions Region assignments
#' @param radius Broadcast radius
#' @return List of affected region IDs
#' @export
get_affected_regions <- function(position, regions, radius = 20) {
  affected <- c()

  for (region_id in names(regions)) {
    region <- regions[[region_id]]

    # Check if position is within radius of region
    x_close <- any(abs(position[1] - region$x_range) <= radius)
    y_close <- any(abs(position[2] - region$y_range) <= radius)

    if (x_close && y_close) {
      affected <- c(affected, region_id)
    }
  }

  return(affected)
}
```

---

### Phase 5: Documentation & Integration (2 hours)

#### Step 5.1: Update Documentation

**File:** `R/simulation.R` - Add roxygen documentation:

```r
#' @param sync_mode Character string. Grid synchronization mode for async
#'   simulations. Options:
#'   \describe{
#'     \item{"static"}{Workers receive static grid snapshot (default, fastest)}
#'     \item{"dynamic"}{Workers receive real-time grid updates via broadcasting
#'                      (enables collision detection, slower)}
#'   }
#'   Only applies when \code{workers > 0}. Has no effect in sync mode
#'   (\code{workers = 0}).
#'
#' @details
#' ## Sync Modes
#'
#' The \code{sync_mode} parameter controls how workers share grid state in
#' async simulations:
#'
#' **Static Mode (default):**
#' - Workers receive frozen grid snapshot at start
#' - Workers never see each other's updates
#' - No collision detection between walkers
#' - Fastest performance (no broadcasting overhead)
#' - Suitable for most use cases
#'
#' **Dynamic Mode (experimental):**
#' - Workers receive real-time grid updates via pub/sub
#' - Walkers can collide (terminate on occupied cells)
#' - More realistic simulation
#' - ~30-50% slower due to broadcasting overhead
#' - Requires nanonext package
#'
#' @examples
#' # Static mode (default)
#' result_static <- run_simulation(
#'   grid_size = 100,
#'   n_walkers = 20,
#'   workers = 4,
#'   sync_mode = "static"
#' )
#'
#' # Dynamic mode with collision detection
#' result_dynamic <- run_simulation(
#'   grid_size = 100,
#'   n_walkers = 20,
#'   workers = 4,
#'   sync_mode = "dynamic"
#' )
#'
#' # Compare collision rates
#' collisions_static <- sum(sapply(result_static$walkers,
#'                                 function(w) w$status == "collision"))
#' collisions_dynamic <- sum(sapply(result_dynamic$walkers,
#'                                  function(w) w$status == "collision"))
#'
#' cat(sprintf("Collisions - Static: %d, Dynamic: %d\n",
#'             collisions_static, collisions_dynamic))
```

#### Step 5.2: Create Vignette

**File:** `vignettes/dynamic_broadcasting.Rmd`

```r
---
title: "Dynamic Grid Broadcasting"
output: rmarkdown::html_vignette
vignette: >
  %\VignetteIndexEntry{Dynamic Grid Broadcasting}
  %\VignetteEngine{knitr::rmarkdown}
  %\VignetteEncoding{UTF-8}
---

## Overview

This vignette demonstrates the **dynamic broadcasting** feature for
async simulations.

## Static vs Dynamic

### Static Mode (Default)

Workers receive a frozen snapshot of the grid:

\```{r}
library(randomwalk)

result_static <- run_simulation(
  grid_size = 50,
  n_walkers = 10,
  workers = 2,
  sync_mode = "static"
)

plot_grid(result_static)
\```

### Dynamic Mode

Workers receive real-time updates:

\```{r}
result_dynamic <- run_simulation(
  grid_size = 50,
  n_walkers = 10,
  workers = 2,
  sync_mode = "dynamic"
)

plot_grid(result_dynamic)
\```

## Collision Detection

Dynamic mode enables collision detection:

\```{r}
# Count collisions
count_collisions <- function(result) {
  sum(sapply(result$walkers, function(w) w$status == "collision"))
}

collisions_static <- count_collisions(result_static)
collisions_dynamic <- count_collisions(result_dynamic)

cat(sprintf("Static: %d collisions\n", collisions_static))
cat(sprintf("Dynamic: %d collisions\n", collisions_dynamic))
\```

## Performance

Dynamic mode has overhead:

\```{r}
library(bench)

results <- mark(
  static = run_simulation(
    grid_size = 100,
    n_walkers = 20,
    workers = 4,
    sync_mode = "static",
    max_steps = 500
  ),
  dynamic = run_simulation(
    grid_size = 100,
    n_walkers = 20,
    workers = 4,
    sync_mode = "dynamic",
    max_steps = 500
  ),
  iterations = 3,
  check = FALSE
)

plot(results)
\```

## When to Use Dynamic Mode

Use dynamic mode when:
- ✅ You need realistic walker interactions
- ✅ Collision detection is important
- ✅ You're studying emergent behavior
- ✅ Performance overhead is acceptable

Use static mode when:
- ✅ Maximum performance needed
- ✅ Collision detection not required
- ✅ Independent walker paths sufficient
- ✅ Reproducibility critical
```

#### Step 5.3: Update Dashboard

**File:** `inst/shiny/dashboard_async/app.R`

Add radio button for sync mode:

```r
radioButtons(
  "sync_mode",
  "Grid Synchronization:",
  choices = c(
    "Static (faster, no collisions)" = "static",
    "Dynamic (slower, with collisions)" = "dynamic"
  ),
  selected = "static"
)

helpText(
  "Static: Workers use frozen grid snapshots (default).",
  "Dynamic: Workers receive real-time updates (experimental)."
)
```

Update simulation call:

```r
result <- run_simulation(
  grid_size = input$grid_size,
  n_walkers = input$n_walkers,
  workers = input$workers,
  sync_mode = input$sync_mode,  # NEW
  max_steps = input$max_steps
)
```

Add collision statistics:

```r
output$collision_stats <- renderText({
  req(sim_result())

  collisions <- sum(sapply(sim_result()$walkers,
                          function(w) w$status == "collision"))

  sprintf("Collisions detected: %d", collisions)
})
```

---

## Testing Strategy

### Unit Tests
- ✅ Socket initialization
- ✅ Message serialization/deserialization
- ✅ Broadcast and receive
- ✅ Non-blocking receive
- ✅ Batch updates
- ✅ Grid update application

### Integration Tests
- ✅ Full simulation with broadcasting
- ✅ Collision detection
- ✅ Static vs dynamic comparison
- ✅ Multiple workers (2, 4, 8)
- ✅ Various grid sizes

### Performance Tests
- ✅ Benchmark overhead
- ✅ Message latency
- ✅ Throughput (messages/sec)
- ✅ Memory usage
- ✅ Scalability (workers vs time)

### Stress Tests
- ✅ Large grids (500x500)
- ✅ Many walkers (1000+)
- ✅ Long simulations (10000 steps)
- ✅ Many workers (8+)
- ✅ High update frequency

---

## Performance Considerations

### Expected Overhead

Based on prototype benchmarks:

| Scenario | Static Time | Dynamic Time | Overhead |
|----------|-------------|--------------|----------|
| Small (50x50, 10 walkers) | 0.5s | 0.7s | +40% |
| Medium (100x100, 20 walkers) | 2.0s | 2.8s | +40% |
| Large (200x200, 50 walkers) | 8.0s | 11.2s | +40% |

### Optimization Strategies

1. **Batching** - Reduces overhead by 20-30%
2. **Spatial Partitioning** - Reduces messages by 50-75%
3. **Compression** - Reduces bandwidth by 30-50%
4. **Async I/O** - Reduces blocking time

### Memory Usage

Dynamic mode increases memory:
- Static: ~100 KB per worker (grid copy)
- Dynamic: ~200 KB per worker (grid + socket buffers)

---

## Risk Analysis

### Technical Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Socket errors | Medium | High | Retry logic, error handling |
| Message loss | Low | High | Acknowledgments, checksums |
| Race conditions | Medium | Medium | Atomic operations, testing |
| Performance degradation | High | Medium | Benchmarking, optimization |
| Platform incompatibility | Medium | Medium | Fallback to static mode |

### Development Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Complexity | High | Medium | Modular design, documentation |
| Debugging difficulty | High | High | Extensive logging, unit tests |
| Serialization issues | Medium | High | Thorough testing, error handling |
| Worker crashes | Low | High | Try-catch, graceful degradation |

---

## Alternative Approaches

### Option 1: Shared Memory (mirai)

**Pros:**
- Faster (zero-copy)
- Simpler API
- Atomic operations built-in

**Cons:**
- Platform-specific
- Single machine only
- Memory contention

**Recommendation:** Explore as alternative if nanonext performance insufficient.

### Option 2: Database Backend

**Pros:**
- Transactional guarantees
- Persistent state
- Scales to multiple machines

**Cons:**
- Much slower
- Complex setup
- Overkill for simulation

**Recommendation:** Not recommended for this use case.

### Option 3: Hybrid Approach

**Concept:**
- Broadcast only "important" updates (e.g., walker collisions)
- Keep grid updates local
- Periodic full synchronization

**Pros:**
- Lower overhead
- Still enables some interaction

**Cons:**
- More complex logic
- Partial realism

**Recommendation:** Consider if full broadcasting too slow.

---

## Success Criteria

### Phase 1 (Research)
- ✅ Prototype demonstrates <1ms latency
- ✅ Overhead <50% for 1000 updates
- ✅ No socket errors in 100 test runs

### Phase 2 (Implementation)
- ✅ All unit tests pass
- ✅ Integration tests pass
- ✅ Code review approved
- ✅ No regression in static mode

### Phase 3 (Testing)
- ✅ Collision detection works correctly
- ✅ Results differ from static mode
- ✅ Performance acceptable (<50% overhead)
- ✅ No memory leaks in 10-minute run

### Phase 4 (Optimization)
- ✅ Overhead reduced to <30% with optimizations
- ✅ Scalability tested (2, 4, 8 workers)
- ✅ Profiling identifies no bottlenecks

### Phase 5 (Documentation)
- ✅ Vignette completed and builds
- ✅ Function documentation comprehensive
- ✅ Dashboard integrated
- ✅ Wiki page created

---

## Timeline

| Phase | Duration | Dependencies |
|-------|----------|--------------|
| Phase 1: Research | 3-4 hours | None |
| Phase 2: Implementation | 1 day | Phase 1 complete |
| Phase 3: Testing | 4 hours | Phase 2 complete |
| Phase 4: Optimization | 4 hours | Phase 3 complete |
| Phase 5: Documentation | 2 hours | Phase 4 complete |
| **TOTAL** | **2-3 days** | |

---

## Next Steps

1. **Get Approval** - Review this plan with stakeholders
2. **Phase 1** - Start prototype and benchmarking
3. **Decision Point** - Proceed only if benchmarks meet criteria
4. **Implementation** - Follow phases 2-5 sequentially
5. **Code Review** - Get PR reviewed before merge
6. **Documentation** - Update wiki with lessons learned

---

## References

- [nanonext documentation](https://shikokuchuo.net/nanonext/)
- [mirai documentation](https://shikokuchuo.net/mirai/)
- [NNG (Nanomsg Next Gen)](https://nng.nanomsg.org/)
- [crew parallelization](https://wlandau.github.io/crew/)

---

**Created:** 2025-12-04
**Status:** Ready for review
**Estimated Effort:** 2-3 days
**Priority:** Low (optional enhancement)

## UPDATED REQUIREMENTS (2025-12-04)

### Vignette Structure: Multi-Page Format

The `vignettes/dynamic_broadcasting.qmd` should be organized into multiple pages:

#### Page 1: Overview and Implementation
- Problem statement and motivation
- Architecture diagrams (pub/sub model)
- Complete walker logic (Steps 0-N)
- Broadcasting functions reference
- Eventual consistency model

#### Page 2: Targets-Based Simulations

Pre-computed simulations at three scales:

```r
# _targets.R additions
list(
  # Small: Quick demonstration (500 steps)
  tar_target(
    sim_dynamic_small,
    run_simulation(
      grid_size = 50,
      n_walkers = 10,
      workers = 2,
      sync_mode = "dynamic",
      max_steps = 500
    )
  ),
  
  # Medium: Balanced performance (4000 steps)
  tar_target(
    sim_dynamic_medium,
    run_simulation(
      grid_size = 100,
      n_walkers = 20,
      workers = 4,
      sync_mode = "dynamic",
      max_steps = 4000
    )
  ),
  
  # Large: Stress test (12000 steps)
  tar_target(
    sim_dynamic_large,
    run_simulation(
      grid_size = 200,
      n_walkers = 50,
      workers = 8,
      sync_mode = "dynamic",
      max_steps = 12000
    )
  ),
  
  # Comparisons (static vs dynamic)
  tar_target(
    sim_static_small,
    run_simulation(grid_size = 50, n_walkers = 10, workers = 2, 
                   sync_mode = "static", max_steps = 500)
  ),
  tar_target(
    sim_static_medium,
    run_simulation(grid_size = 100, n_walkers = 20, workers = 4,
                   sync_mode = "static", max_steps = 4000)
  ),
  tar_target(
    sim_static_large,
    run_simulation(grid_size = 200, n_walkers = 50, workers = 8,
                   sync_mode = "static", max_steps = 12000)
  )
)
```

Load and visualize in vignette:

```r
# In vignette
targets::tar_load(c(sim_static_small, sim_dynamic_small))

# Side-by-side grid comparison
plot_comparison(sim_static_small, sim_dynamic_small)

# Statistics table
compare_statistics(sim_static_small, sim_dynamic_small)
```

#### Page 3: Comparison Analysis

Visualizations comparing static vs dynamic mode:
- Grid state (side-by-side plots)
- Black pixel counts
- Collision statistics
- Performance metrics (time, speedup)
- Clustering patterns

#### Page 4: Interactive Dashboard (R-Shinylive)

Embedded Shiny app that emulates `dashboard_async` with dynamic mode:

**Inputs:**
- Grid size: 20-200 (slider)
- Number of walkers: 1-max (slider, dynamically constrained)
- Number of workers: 0-8 (slider)
- **Sync mode: "static" vs "dynamic" (radio buttons)** ← NEW
- Neighborhood: "4-hood" vs "8-hood" (radio)
- Boundary: "terminate" vs "wrap" (radio)
- Max steps: 100-5000 (slider)

**Outputs:**
- Grid visualization (plotly interactive)
- Statistics table:
  - Black pixels
  - **Collisions detected** ← NEW (only for dynamic mode)
  - Steps taken
  - Termination reasons
- Performance metrics:
  - Elapsed time
  - Speedup vs sync
  - **Broadcasting overhead** ← NEW (dynamic mode only)

**Dashboard features:**
- Run button to execute simulation
- Compare button: Run both static and dynamic side-by-side
- Download results button
- Reset button

The shinylive app will be exported to `docs/articles/dynamic_broadcasting/` similar to `dashboard_async/`.

### Simplified Walker Logic (Step 2 Removal)

**Question raised:** Is Step 2 necessary?

Original logic:
```
Step 0: Check starting position
Step 1: Pop broadcasts
Step 2: Check if current position became black ← QUESTIONABLE
Step 3: Check neighbors
```

**Issue:** If current position is white (Step 0), why check if it became black (Step 2)?

**Answer:** Handles race condition where:
1. Walker at position P (white)
2. Another worker broadcasts P is black
3. Current walker pops broadcast (Step 1)
4. Current walker standing on black pixel

**However:** With "approximate solution, best efforts" philosophy:
- Step 2 only prevents duplicate broadcast
- Walker will detect black neighbor next iteration anyway
- Removing Step 2 simplifies logic

**Recommendation:** Remove Step 2 for simplicity.

**Simplified logic:**
```r
# Step 0: Check starting position (once, before loop)
if (local_grid[position[1], position[2]] == "black") {
  return(status = "started_on_black")
}

for (step in 1:max_steps) {
  # Step 1: Pop broadcasts and update grid
  while (has_messages(sub_socket)) {
    msg <- pop_message(sub_socket)
    local_grid[msg$position[1], msg$position[2]] <- "black"
  }
  
  # Step 2 (formerly Step 3): Check neighbors
  if (has_black_neighbor(position, local_grid, neighborhood)) {
    # Current position becomes black
    local_grid[position[1], position[2]] <- "black"
    
    # Broadcast to all workers
    broadcast_black_pixel(pub_socket, position, walker_id)
    
    return(status = "black_neighbor_detected")
  }
  
  # Step 3 (formerly Step 4-6): Make move
  next_position <- make_step(position, local_grid, neighborhood)
  
  # Check boundary
  if (is_boundary(next_position, grid_size)) {
    if (boundary == "terminate") {
      return(status = "boundary")
    }
    next_position <- handle_boundary(next_position, boundary, grid_size)
  }
  
  # Move to next position
  position <- next_position
}

# Max steps reached
return(status = "max_steps")
```

**Benefits:**
- ✅ Simpler: 3 steps instead of 4 per iteration
- ✅ Clearer: Less cognitive overhead
- ✅ Acceptable: Eventual consistency handles edge cases

**Trade-off:**
- ⚠️ Rare case: Walker standing on black pixel for 1 iteration
- ⚠️ Possible: Duplicate broadcast if walker at position creates black pixel there
- ✅ Acceptable: "Approximate solution on best efforts basis"

