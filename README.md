# randomwalk

Asynchronous Pixel Walking Simulation with Parallel Processing

## 🚀 Quick Links

- **📊 [Live Dashboard](https://johngavin.github.io/randomwalk/articles/dashboard/)** - Try the simulation in your browser (no installation needed)
- **📚 [Package Documentation](https://johngavin.github.io/randomwalk/)** - Full API reference and vignettes
- **📖 [Wiki](https://github.com/JohnGavin/randomwalk/wiki)** - How-to guides, troubleshooting, and deployment docs
- **🐙 [GitHub Repository](https://github.com/JohnGavin/randomwalk)** - Source code and issues
- **🏷️ [Latest Release](https://github.com/JohnGavin/randomwalk/releases/latest)** - Download and release notes

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

## Interactive Dashboard

Try the simulation directly in your browser (no installation required):

**[Launch Interactive Dashboard](https://johngavin.github.io/randomwalk/articles/dashboard/)**

The dashboard runs entirely in your browser using WebAssembly via [Shinylive](https://posit-dev.github.io/r-shinylive/). Features include:

- Real-time parameter adjustment with sliders and dropdowns
- Multiple visualization tabs (Grid State, Walker Paths, Statistics, Raw Data)
- Start points (green circles) and end points (red triangles) on path plots
- Complete simulation statistics and detailed walker information
- No R installation or server required

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

## 📖 Documentation & Resources

### Wiki Guides

Visit the [project wiki](https://github.com/JohnGavin/randomwalk/wiki) for comprehensive guides:

- **[Troubleshooting Nix Environment](https://github.com/JohnGavin/randomwalk/wiki/Troubleshooting-Nix-Environment)** - Solutions for nix environment degradation during long development sessions
- **[Working with Claude Across Sessions](https://github.com/JohnGavin/randomwalk/wiki/Working-with-Claude-Across-Sessions)** - How to preserve context when using Claude Code
- **[Using Gemini CLI for Large Codebases](https://github.com/JohnGavin/randomwalk/wiki/Using-Gemini-CLI-for-Large-Codebases)** - Leverage Gemini's large context window for codebase analysis
- **[Deploying Shinylive Dashboards](https://github.com/JohnGavin/randomwalk/wiki/Deploying-Shinylive-Dashboards)** - Complete deployment guide with solutions to common issues

### Additional Resources

- [Project Info](PROJECT_INFO.md) - Quick reference with restore instructions
- [R/setup/](R/setup/) - Development workflow scripts for reproducibility
- [.github/workflows/](.github/workflows/) - CI/CD workflow configurations

## License

MIT
