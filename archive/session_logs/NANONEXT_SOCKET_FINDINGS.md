# Nanonext Socket Serialization Investigation

**Date**: 2025-11-19
**Status**: ✅ Root Cause Identified

## Key Finding: Sockets Cannot Be Serialized Between Processes

### The Problem

nanonext socket objects (`nanoObject` class) are **environment objects** that:
1. Cannot be serialized/deserialized for inter-process communication
2. Cannot be returned from crew workers to the main process
3. Cannot be passed as arguments to crew workers

### Test Results

#### Test 1: Simple Arithmetic
- **Status**: Timeout
- **Note**: First task often requires worker initialization time

#### Test 2: Load nanonext Package
- **Status**: ✅ Success
- **Result**: nanonext loads successfully in crew workers
- **Version**: 1.7.2

#### Test 3: Create Subscriber Socket
- **Status**: ✅ Success (but results offset due to timing)
- **Finding**: Socket can be created in worker

#### Test 4: Create Socket and Call subscribe()
- **Status**: ❌ Failed
- **Error**: `"cannot coerce type 'environment' to vector of type 'list'"`
- **Root Cause**: crew tries to serialize the socket object when returning it
- **Trace**: Error occurs in `as.list.default(socket)` when crew evaluates the result

#### Test 5: Pub/Sub Integration
- **Status**: ❌ Failed
- **Error**: `` `object` is not a valid Socket or Context``
- **Root Cause**: Socket object becomes invalid when crew tries to serialize it

## Technical Details

### What nano() Returns

```r
socket <- nano("sub", dial = "tcp://127.0.0.1:5555")

class(socket)       # "nanoObject"
typeof(socket)      # "environment"
is.environment(socket)  # TRUE
```

### Why Serialization Fails

1. **Environment Type**: nanoObject is implemented as an R environment
2. **External Pointers**: Contains C-level socket file descriptors
3. **Process-Specific**: Socket connections are tied to the OS process
4. **Serialization Attempt**: crew's result extraction calls `as.list()` on returned objects
5. **Failure Point**: R cannot coerce environments with external pointers to lists

### Error Chain

```
crew worker returns result
  ↓
crew tries to serialize return value
  ↓
crew calls as.list(socket)
  ↓
R attempts as.list.default(socket)
  ↓
ERROR: "cannot coerce type 'environment' to vector of type 'list'"
```

## Implications for randomwalk Package

### Current Architecture Issue

Our current async implementation tries to:
1. Create pub/sub sockets in the main process
2. Pass socket information to workers
3. Have workers create their own subscriber sockets
4. Workers subscribe to the publisher

### The Problem

Workers can create and use sockets locally, but:
- ❌ Cannot return socket objects to main process
- ❌ Cannot receive socket objects from main process
- ✅ CAN create sockets using connection strings (URLs)
- ✅ CAN send/receive DATA through those sockets

### Required Architecture Changes

#### Option 1: No Inter-Worker Communication (Simpler)
```
Main Process                Workers
-----------                 -------
Create walkers       →      Worker 1: process walker 1
Queue walkers        →      Worker 2: process walker 2
Collect results      ←      Worker 3: process walker 3
Update shared state
```

**Pros**:
- No socket serialization issues
- Simpler implementation
- Workers are truly independent

**Cons**:
- Workers don't see each other's state changes
- May lead to conflicts on shared grid

#### Option 2: Main Process as Message Broker
```
Main Process                     Workers
------------                     -------
Publisher socket (5555)          Worker 1:
Subscriber socket (5556)           - Create local sub socket (dial 5555)
                                   - Subscribe to updates
Message loop:                      - Process walker
  - Collect walker results  ←      - Return DATA (not socket!)
  - Update shared state            - Receive state via socket
  - Broadcast updates       →      - Continue processing
```

**Pros**:
- Real-time state synchronization
- Workers see each other's changes
- Preserves original async architecture vision

**Cons**:
- More complex
- Main process must run message loop
- Potential bottleneck at main process

#### Option 3: Shared State via DuckDB Only (Recommended)
```
Main Process              DuckDB              Workers
-----------              ------              -------
Create walkers     →                  ←     Worker reads grid state
Queue walkers      →                         Process walker
                         ← Write ←           Walker terminates
Collect results    ←                         Return path data
Update grid state  →     → Update
Queue next walker  →                  ←     Worker reads updated state
```

**Pros**:
- No socket serialization issues
- DuckDB handles concurrency
- Workers poll for state changes
- Simple and robust

**Cons**:
- Polling overhead
- Slight delay in state propagation
- More DuckDB queries

## Recommended Solution: Hybrid Approach

### Architecture

1. **Main Process**:
   - Manages walker queue
   - Coordinates DuckDB state
   - Collects results via crew

2. **Workers**:
   - Receive walker initial state (serializable data)
   - Poll DuckDB for grid state before each move
   - Return walker results (serializable data)
   - NO socket creation

3. **State Synchronization**:
   - DuckDB in-memory database
   - Workers query for black pixels before each move
   - Main process updates grid when walker terminates

### Implementation Changes Required

#### R/simulation.R

**Current (Broken)**:
```r
# Worker tries to create socket
controller$push(
  command = simulate_walker_async(walker, ...),
  data = list(walker = walker, ...)
)
```

**Fixed**:
```r
# Worker receives data, returns data
controller$push(
  command = simulate_walker_async(
    walker_id = walker_id,
    start_pos = start_pos,
    grid_bounds = grid_bounds,
    duckdb_conn = duckdb_conn  # Use DuckDB, not sockets
  ),
  data = list(
    walker_id = walker_id,
    start_pos = start_pos,
    grid_bounds = grid_bounds
  )
)
```

#### New Helper Function Needed

```r
#' Check grid state from DuckDB
#'
#' Called by worker before each walker move
#' @param conn DuckDB connection (created in worker)
#' @param x Position x
#' @param y Position y
#' @return TRUE if pixel is black
check_pixel_black <- function(conn, x, y) {
  result <- DBI::dbGetQuery(
    conn,
    "SELECT is_black FROM grid WHERE x = ? AND y = ?",
    params = list(x, y)
  )

  if (nrow(result) == 0) return(FALSE)
  result$is_black[1]
}
```

## Action Items

- [ ] Remove all nanonext socket creation code from workers
- [ ] Implement DuckDB-only state synchronization
- [ ] Update simulate_walker_async() to use DuckDB polling
- [ ] Add check_pixel_black() helper function
- [ ] Update tests to verify DuckDB approach
- [ ] Run benchmarks to measure polling overhead
- [ ] Document new architecture in PARALLEL_ARCHITECTURE.md

## References

- nanonext docs: https://shikokuchuo.net/nanonext/
- crew docs: https://wlandau.github.io/crew/
- Issue #21: https://github.com/JohnGavin/randomwalk/issues/21
- Test files:
  - R/setup/test_nanonext_in_crew.R
  - R/setup/test_socket_details.R
  - R/setup/test_nanonext_proper_wait.R
