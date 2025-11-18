=== ASYNCHRONOUS PIXEL WALKING SIMULATION ===

=== SIMULATION ARCHITECTURE ===
• Main Process: Shiny app with UI and simulation management
• Worker Processes: Independent R processes running walker 
simulations
• Communication: nanonext sockets for job distribution and result 
collection
• State Management: DuckDB in-memory database for global state
• Real-time Updates: Publisher-Subscriber pattern for grid state 
sync

=== KEY FEATURES ===
✓ True asynchronous parallel processing with separate R worker processes
✓ Real-time grid state synchronization across all workers
✓ Comprehensive statistics tracking with percentiles and formatting
✓ Responsive UI that doesn't block simulation performance
✓ Automatic resource cleanup and process management
✓ Debug panel with detailed system monitoring
✓ Graceful fallback to synchronous mode if dependencies unavailable
✓ Background process execution to free up console

=== PERFORMANCE OPTIMIZATIONS ===
• Workers maintain local black pixel cache for fast neighbor checking
• Non-blocking communication to prevent worker stalls
• Batched grid updates to minimize communication overhead
• Periodic UI updates decoupled from simulation loop
• Memory-efficient grid storage and processing
• Automatic worker process lifecycle management

=== DEBUGGING FEATURES ===
• Real-time worker process status monitoring
• Communication socket health tracking
• Database connection and query status
• Memory usage and performance metrics
• Detailed console logging with timestamps
• Worker process log files for detailed debugging

=== SIMULATION PARAMETERS ===
Grid Size: Controls the n×n simulation grid (default 10×10)
Walkers: Number of simultaneous random walkers (1 to 60% of grid) default is 5.
Neighborhood: default is 4-hood (NSEW) or 8-hood (includes diagonals)
Boundary: Wrap-around (torus) or default is terminate at edges
Workers: Number of parallel R processes (0-16). default is 1
Refresh Rate: UI update interval in seconds (1-60). default is 4 seconds.

=== STATISTICS TRACKED ===
Current Simulation:
  • Black pixels (count and percentage)
  • Active and completed walkers
  • Total steps taken by all walkers
  • Step count percentiles (25th, 50th, 75th)
  • Elapsed time

All-time Statistics:
  • Total simulations run
  • Cumulative elapsed time
  • Average time per simulation
  • Simulation time percentiles

=== TERMINATION CONDITIONS ===
Walkers terminate when they:
  1. Touch a black pixel (become part of the aggregate)
  2. Have a black neighbor (become black and join aggregate)
  3. Hit grid boundary (if terminate mode selected)
  4. Reach maximum step limit (safety mechanism)

Simulation ends when:
  • All walkers have terminated
  • User stops simulation manually (plot current state of grid first and stats to date)
  • Grid size changes (triggers restart but plot current state of grid first and stats to date)

This is NOT a DLA simulation. It is a simple random walk that builds a fractal graph.
The async simulation is not exact, it is only an approximation, as the update of the global state is only near realtime.
Every step by every worker should include a check to see if the global state has changed. If so, the local state for that worker should read the global state to update the local cache before proceeding.
The GUI should also access updates about the global state frequently. This should inlcude info to plot the current state of the global state and to updates the statistics.

# Sample output

Async mode available: TRUE 
Worker processes available: TRUE 
Database: DuckDB in-memory
Communication: nanonext pub/sub + push/pull

=== USAGE ===
Standard mode: run_dashboard()


=== EXAMPLE SIMULATION OUTPUT ===
=== STARTUP CONDITIONS ===
Grid size: 20x20
Async mode: ENABLED
Worker processes: AVAILABLE
Communication ports: 5555, 5556, 5557, 5558

=== STARTING SIMULATION ===
Mode: Asynchronous
Grid: 20x20
Walkers: 8
Workers: 3
Neighborhood: 4-hood
Boundary: terminate

=== READY TO LAUNCH ===
Execute: run_dashboard()

Example first simulation step:
[14:23:15] STEP 1: Active=8, Black=1
Worker 1 processing walker 1 from (15, 8)
Worker 2 processing walker 2 from (3, 12)
Walker 1 completed with 23 steps at (10, 10) - 
touched_black_neighbor
...
=== SIMULATION ENDED AFTER 42 STEPS ===
Final black pixels: 9
Total steps: 187

