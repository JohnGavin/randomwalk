# Dynamic Grid Broadcasting Algorithm

> ⚠️ **DEPRECATED**: Dynamic broadcasting via nanonext sockets is **no longer supported**. The nanonext sockets fail when created inside crew/mirai subprocesses, causing `sync_mode="dynamic"` and `sync_mode="mirai_dynamic"` to silently fall back to static behavior. Use `sync_mode="chunked"` instead for best collision detection.
>
> This document is preserved for historical reference and to document the known limitation.

This document describes the real-time grid synchronization algorithm that was *intended* for the `randomwalk` package for parallel walker simulations.

## Problem Statement

In async parallel mode, multiple workers simulate walkers independently. Without synchronization:
- Workers don't see each other's black pixels
- Walkers can't properly interact
- Results differ between sync (workers=0) and async (workers>0) modes

**Challenge:** How to share grid state efficiently without broadcasting the entire grid (~10,000 cells) every step?

## Solution: Event-Driven Broadcasting

Instead of broadcasting the full grid, only broadcast **when a pixel turns black** (typically 10-100 events per simulation vs 10,000+ cell updates).

```
┌─────────────────────────────────────────────────────────────┐
│                    STATIC MODE (Current)                    │
├─────────────────────────────────────────────────────────────┤
│  Workers get initial grid snapshot                          │
│  ➜ No updates during simulation                             │
│  ➜ ~0 messages                                              │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    DYNAMIC MODE (Broadcasting)              │
├─────────────────────────────────────────────────────────────┤
│  Workers subscribe to black pixel events                    │
│  ➜ Only ~10-100 broadcasts (when pixels turn black)         │
│  ➜ Eventual consistency model                               │
└─────────────────────────────────────────────────────────────┘
```

## Architecture

### Pub/Sub Pattern with nanonext

```
                    ┌───────────────────┐
                    │   PUBLISHER       │
                    │   (Controller)    │
                    │   Port 5555       │
                    └────────┬──────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
              ▼              ▼              ▼
        ┌──────────┐   ┌──────────┐   ┌──────────┐
        │ Worker 1 │   │ Worker 2 │   │ Worker N │
        │   SUB    │   │   SUB    │   │   SUB    │
        └──────────┘   └──────────┘   └──────────┘
              │              │              │
              └──────────────┼──────────────┘
                             │
                             ▼
                    ┌───────────────────┐
                    │   PUBLISHER       │
                    │   (Workers send   │
                    │    updates back)  │
                    └───────────────────┘
```

### Key Functions

| Function | Purpose |
|----------|---------|
| `init_publisher_socket()` | Creates nanonext PUB socket |
| `init_subscriber_socket()` | Creates nanonext SUB socket |
| `broadcast_black_pixel()` | Sends black pixel event |
| `update_grid_from_broadcasts()` | Non-blocking receive and apply |

## Walker Algorithm (Dynamic Mode)

```
simulate_walker_dynamic(walker_id, grid, pub_socket, sub_socket):

    position = random_start_position()

    if grid[position] == BLACK:
        return "started_on_black"  # No broadcast needed

    for step in 1..max_steps:

        # ─────────────────────────────────────────────
        # STEP 1: Pop ALL pending broadcasts
        # ─────────────────────────────────────────────
        local_grid = update_grid_from_broadcasts(sub_socket, local_grid)

        # ─────────────────────────────────────────────
        # STEP 2: Check neighbors for black pixels
        # ─────────────────────────────────────────────
        neighbors = get_neighbors(position, neighborhood)

        if any(local_grid[n] == BLACK for n in neighbors):
            # FOUND BLACK NEIGHBOR!
            local_grid[position] = BLACK
            broadcast_black_pixel(pub_socket, position, walker_id)  # <-- KEY
            return "black_neighbor_detected"

        # ─────────────────────────────────────────────
        # STEP 3: Random walk to next position
        # ─────────────────────────────────────────────
        position = random_choice(neighbors)

        if out_of_bounds(position):
            if boundary == "terminate":
                return "boundary"
            else:
                position = wrap(position)

    return "max_steps"
```

## Message Format

Each broadcast contains minimal data:

```r
message_data <- list(
  type = "black_pixel",
  position = c(x, y),      # Just 2 integers
  walker_id = walker_id,
  timestamp = Sys.time()
)
```

**Size:** ~100 bytes per message (vs ~80KB for full 100x100 grid)

## Performance Characteristics

| Metric | Static Mode | Dynamic Mode | Overhead |
|--------|-------------|--------------|----------|
| Messages per simulation | 0 | ~10-100 | N/A |
| Message size | N/A | ~100 bytes | N/A |
| Total bandwidth | 0 | ~10KB | Negligible |
| Latency per message | N/A | <1ms | ~12% |

### Why Minimal Overhead?

1. **Sparse events:** Only ~1-2% of cells become black
2. **Small messages:** Just coordinates, not grid state
3. **Non-blocking receives:** Workers don't wait for messages
4. **Eventual consistency:** Brief inconsistencies are acceptable

## Eventual Consistency Model

Workers may briefly have stale views of the grid:

```
Time ─────────────────────────────────────────────────►

Worker 1:  ████ turns black ──► broadcasts ──────────►
Worker 2:  ░░░░░░░░░░░░░░░░░░░░░ receives ──► ████
                                   │
                                   └── Brief window where
                                       Worker 2 has stale view
```

**This is acceptable because:**
- Walkers check neighbors every step anyway
- Race conditions only affect edge cases (same-step collisions)
- Results are statistically equivalent to sync mode

## Why This Approach Failed

The dynamic broadcasting approach was designed but **does not work in practice** due to a fundamental limitation:

### nanonext Socket Failure in Subprocesses

When `nanonext::socket()` is called inside a crew/mirai worker subprocess, it fails silently:

```r
# In R/simulation.R:643-650
socket <- tryCatch(
  nanonext::socket(...),
  error = function(e) NULL  # Falls back to NULL = static mode
)
```

The socket creation fails because:
1. NNG (Nanomsg Next Gen) sockets cannot be inherited across fork boundaries
2. Crew/mirai use forked processes on Unix systems
3. The socket must be created in the main process, not the subprocess

### Recommended Alternative: Chunked Mode

Use `sync_mode = "chunked"` instead:
- Processes walkers in batches of 10
- Updates grid between batches
- Achieves ~15% collision detection (vs ~5% for static, ~0% for broken dynamic)
- No socket dependencies

## Original Limitations (Historical)

1. **Not available in WebR/browser** - nanonext requires native sockets
2. **Requires nanonext package** - Additional dependency
3. **Network overhead** - Minimal but non-zero
4. ⚠️ **CRITICAL: Sockets fail in crew/mirai subprocesses** - Makes this approach non-functional

## Related Issues

- **#51** - Original issue: Dynamic grid state broadcasting (DEPRECATED)
- **#89** - This documentation
- **#130** - Switch entirely to mirai (no longer relevant)
- **#144** - Cache coherency issue (now documented as known limitation)
- **#158** - WebR compatibility (nanonext not available in WASM)

## Files

| File | Description |
|------|-------------|
| `R/broadcasting.R` | Socket init, broadcast, receive functions |
| `R/walker_dynamic.R` | Walker simulation with broadcasting |
| `R/async_worker.R` | Worker integration |
| `R/async_controller.R` | Controller integration |

## Usage Example

```r
# Controller side
pub_socket <- init_publisher_socket(port = 5555)

# Worker side
sub_socket <- init_subscriber_socket(host = "localhost", port = 5555)

# In worker loop
local_grid <- update_grid_from_broadcasts(sub_socket, local_grid)

# When walker finds black neighbor
broadcast_black_pixel(pub_socket, position, walker_id)

# Cleanup
close_sockets(pub_socket, sub_socket)
```

## See Also

- [Step Distribution Analysis](step_distribution_analysis.html) - Statistical analysis
- [Telemetry](telemetry.html) - Performance metrics
- [Defensive Programming](defensive_programming.html) - Validation patterns
