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
run_dashboard()
```

## Simulation Parameters

- **Grid Size**: n×n simulation grid (default 10×10)
- **Walkers**: Number of simultaneous random walkers (1 to 60% of grid, default 5)
- **Neighborhood**: 4-hood (NSEW) or 8-hood (includes diagonals)
- **Boundary**: Wrap-around (torus) or terminate at edges (default)
- **Workers**: Number of parallel R processes (0-16, default 1)
- **Refresh Rate**: UI update interval in seconds (1-60, default 4)

## 📚 Vignettes & Documentation

The package includes comprehensive vignettes for different use cases:

### **[Interactive Dashboard](https://johngavin.github.io/randomwalk/articles/dashboard.html)** 🎮
Browser-based Shiny application running entirely client-side via WebAssembly. Features real-time parameter adjustment, multiple visualization tabs, and complete simulation statistics - no R installation required.

### **[Async/Parallel Simulation Dashboard](https://johngavin.github.io/randomwalk/articles/dashboard_async.html)** ⚡
Advanced dashboard demonstrating parallel processing with 0-12 workers using the `crew` package. Compare performance metrics between sync and async modes, with grid sizes from 20×20 to 400×400.

### **[Telemetry and Pipeline Statistics](https://johngavin.github.io/randomwalk/articles/telemetry.html)** 📊
Package performance metrics, targets pipeline visualization, git history, test coverage statistics, and session information. All data pre-computed using the `targets` package for reproducibility.

## 📋 Essential Documentation

Package-specific development and deployment documentation:

- **[Deployment Guide](inst/docs/DEPLOYMENT_GUIDE.md)** - Deploy randomwalk to GitHub Pages
  - GitHub Actions workflow configuration
  - Verification and troubleshooting steps
  - Tag-based version management

- **[Issues Grouped by Difficulty](ISSUES_GROUPED.md)** - Organized roadmap of open issues
  - Quick wins (⭐) to major features (⭐⭐⭐⭐⭐)
  - Estimated effort and dependencies
  - Prioritized implementation order

- **[Development Workflow](inst/docs/DEVELOPMENT_WORKFLOW.md)** - Package development in Nix
  - 9-step workflow (issue → PR → merge)
  - Testing and documentation requirements
  - Session logging for reproducibility

## 📁 Package Structure

```
randomwalk/
├── R/                          # Core package code
│   ├── simulation.R           # Main simulation functions
│   ├── walker.R               # Walker movement logic
│   ├── grid.R                 # Grid management
│   ├── plotting.R             # Visualization functions
│   ├── async_controller.R     # Crew controller management
│   ├── async_worker.R         # Worker process functions
│   └── shiny_modules.R        # Shiny UI/server modules
│
├── inst/                      # Installed package files
│   ├── shiny/                 # Shiny dashboard applications
│   │   ├── dashboard/         # Sync dashboard
│   │   └── dashboard_async/   # Async dashboard
│   ├── docs/                  # Additional documentation
│   └── qmd/                   # Source Quarto documents
│
├── vignettes/                 # Package vignettes
│   ├── dashboard.qmd          # Interactive dashboard
│   ├── dashboard_async.qmd    # Async/parallel dashboard
│   └── telemetry.qmd          # Telemetry statistics
│
├── tests/testthat/            # Test suite
├── man/                       # Generated documentation
└── _targets.R                 # Targets pipeline definition
```

## 📖 Documentation & Resources

### Package-Specific Documentation

- **[Package Wiki](https://github.com/JohnGavin/randomwalk/wiki)** - Guides specific to the randomwalk package:
  - [Deploying Shinylive Dashboards](https://github.com/JohnGavin/randomwalk/wiki/Deploying-Shinylive-Dashboards) - Deploy random walk dashboards to GitHub Pages

- **[Project Info](PROJECT_INFO.md)** - Quick reference and restore instructions
- **[R/setup/](R/setup/)** - Documented workflow scripts for reproducibility

### General Development Setup

For general development setup, Nix environment troubleshooting, and cross-project workflows, see the **[claude_rix wiki](https://github.com/JohnGavin/claude_rix/wiki)**:
  - Troubleshooting Nix Environment
  - Working with Claude Across Sessions
  - Using Gemini CLI for Large Codebases
  - Cachix Workflow and Binary Cache Management
  - General R Package Development Guides

## License

MIT
