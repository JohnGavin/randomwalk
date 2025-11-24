# Test Failure Root Cause Analysis

**Date**: 2025-11-19
**Status**: 🔴 All async tests failing
**Symptoms**: Tests hang then timeout after 90+ seconds

## The Problem

### Symptom
```
ERROR: Invalid walker structure returned from crew worker
ERROR: Result status: error, error: `object` is not a valid Socket or Context
```

### Root Cause Chain

1. **Architecture Flaw**: Current async implementation uses nanonext pub/sub sockets
   - Main process: Creates publisher socket
   - Workers: Create subscriber sockets to receive grid updates
   - Location: `R/async_worker.R:41` - `socket <- nanonext::nano("sub", dial = pub_address)`

2. **Serialization Problem**: nanonext sockets cannot cross process boundaries
   - Socket type: `nanoObject` (R environment with C pointers)
   - Cannot be: serialized, deserialized, passed between processes
   - What happens: Worker creates socket successfully, but:
     - Socket operations fail with "object is not a valid Socket or Context"
     - crew cannot serialize results containing socket references
     - Worker returns error instead of completed walker

3. **Test Behavior**:
   - Workers fail immediately (within 1 second)
   - Simulation waits up to 90 seconds (timeout)
   - Tests fail with timeout error

## Why Namespace Prefixes Didn't Help (PR #31)

Adding `nanonext::` prefixes doesn't fix:
- Socket serialization issues
- Inter-process communication problems
- The fundamental architectural flaw

The socket can be *created* just fine. The problem is *using* it across process boundaries.

## The Solution: DuckDB State Synchronization

From `R/setup/NANONEXT_SOCKET_FINDINGS.md` - **Option 3: Shared State via DuckDB**

### Current (Broken) Flow
```
Main Process                Workers
-----------                 -------
Create pub socket    →      Create sub socket ❌ (fails)
Broadcast updates    →      Listen for updates ❌
Wait for results     ←      Return walker + socket ❌
```

### Fixed Flow with DuckDB
```
Main Process              DuckDB              Workers
-----------              ------              -------
Create walkers     →                  ←     Query black pixels
Queue tasks        →                         Check termination
                         ← Write ←           Walker terminates
Collect results    ←                         Return walker data ✅
Update grid state  →     → Update
Queue next walker  →                  ←     Query updated state
```

### Key Differences

**Removed**:
- nanonext publisher sockets
- nanonext subscriber sockets
- Socket serialization
- Real-time pub/sub messaging

**Added**:
- DuckDB in-memory database
- Polling-based state queries
- Atomic state updates
- Simpler worker code

### Implementation Changes Required

#### 1. Remove from R/async_worker.R
```r
# DELETE worker_init() - no more socket creation
# DELETE worker_check_updates() - no more socket polling
# UPDATE worker_run_walker() - no socket initialization
```

#### 2. Add to R/async_state.R (new file)
```r
# CREATE setup_duckdb_state() - initialize in-memory DB
# CREATE query_black_pixels() - workers read state
# CREATE update_black_pixels() - main process writes state
```

#### 3. Update R/async_worker.R
```r
# Worker just needs DuckDB connection string
# Query black pixels before each termination check
# No socket cleanup needed
```

#### 4. Update R/simulation.R
```r
# Replace create_pub_socket() with setup_duckdb_state()
# Replace broadcast_update() with update_black_pixels()
# Pass DuckDB connection path to workers
```

## Benefits of DuckDB Approach

✅ **Simple**: No socket management
✅ **Robust**: DuckDB handles concurrency
✅ **Serializable**: Workers only receive connection strings
✅ **Testable**: Easier to debug and verify
✅ **Fast Enough**: Polling overhead acceptable for our use case

## Performance Trade-offs

- **Latency**: ~1-10ms per DuckDB query vs ~0.1ms for socket message
- **Scalability**: 1000s of queries/sec vs millions of messages/sec
- **For our use case**: ✅ DuckDB is fast enough (walkers take seconds to terminate)

## Implementation Estimate

- Remove socket code: 15 minutes
- Add DuckDB infrastructure: 30 minutes
- Update tests: 15 minutes
- Total: ~1 hour

## References

- `R/setup/NANONEXT_SOCKET_FINDINGS.md` - Detailed investigation
- Issue #32 - Implementation tracking
- Issue #30 - Original namespace issue (incorrect)
- PR #31 - Closed (wrong solution)
