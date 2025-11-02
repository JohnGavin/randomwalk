# randomwalk

Asynchronous Pixel Walking Simulation with Parallel Processing

## Overview

`randomwalk` implements parallel random walk simulations that create fractal graphs through asynchronous pixel walking on a grid. This is NOT a DLA (Diffusion-Limited Aggregation) simulation, but a simple random walk that builds fractal-like patterns.

## Features

- **True asynchronous parallel processing** with separate R worker processes
- **Real-time grid state synchronization** across all workers via DuckDB
- **Comprehensive statistics tracking** with percentiles and formatting
- **Responsive Shiny UI** that doesn't block simulation performance
- **Programmatic API** for use without GUI
- **Automatic resource cleanup** and process management
- **Debug panel** with detailed system monitoring
- **Graceful fallback** to synchronous mode if dependencies unavailable

## Installation

```r
# Install from GitHub (once published)
# remotes::install_github("johngavin/randomwalk")

# Or install locally
devtools::install()
```

## Usage

### Programmatic Usage (No GUI)

```r
library(randomwalk)

# Run a simulation directly
result <- run_simulation(
  grid_size = 20,
  n_walkers = 8,
  neighborhood = "4-hood",
  boundary = "terminate",
  workers = 3
)

# Access simulation results
result$grid           # Final grid state
result$statistics     # Statistics
result$walker_paths   # Walker trajectories
```

### Interactive Shiny Interface

```r
library(randomwalk)

# Launch the Shiny app
run_random_walk_app()

# Or run in background to free up console
bg_process <- run_app_in_bg()
```

## Simulation Parameters

- **Grid Size**: n×n simulation grid (default 10×10)
- **Walkers**: Number of simultaneous random walkers (1 to 60% of grid, default 5)
- **Neighborhood**: 4-hood (NSEW) or 8-hood (includes diagonals)
- **Boundary**: Wrap-around (torus) or terminate at edges (default)
- **Workers**: Number of parallel R processes (0-16, default 1)
- **Refresh Rate**: UI update interval in seconds (1-60, default 4)

## Development

See `vignettes/` for detailed documentation on:
- Usage examples
- Performance tuning
- Architecture details
- Telemetry statistics

## License

MIT
