# randomwalk

<!-- badges: start -->
[![R-CMD-check](https://github.com/JohnGavin/randomwalk/actions/workflows/r-cmd-check.yaml/badge.svg)](https://github.com/JohnGavin/randomwalk/actions/workflows/r-cmd-check.yaml)
[![codecov](https://codecov.io/gh/JohnGavin/randomwalk/branch/main/graph/badge.svg)](https://codecov.io/gh/JohnGavin/randomwalk)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Project Status: Active](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
[![R-universe](https://johngavin.r-universe.dev/badges/randomwalk)](https://johngavin.r-universe.dev/randomwalk)
<!-- badges: end -->

Random Walk Simulation for Fractal Pattern Generation.

## Quick Links

- [Interactive Dashboard](https://johngavin.github.io/randomwalk/articles/dashboard_comprehensive.html) - Try simulation in your browser (WebR)
- [Package Documentation](https://johngavin.github.io/randomwalk/) - Full API reference and vignettes
- [Wiki](https://github.com/JohnGavin/randomwalk/wiki) - How-to guides, troubleshooting, and deployment docs
- [GitHub Repository](https://github.com/JohnGavin/randomwalk) - Source code and issues

## Overview

`randomwalk` implements parallel random walk simulations that create fractal graphs through asynchronous pixel walking on a grid. This is NOT a DLA (Diffusion-Limited Aggregation) simulation, but a simple random walk that builds fractal-like patterns.

## Features

- **Fast synchronous simulation** with vectorized neighbor checking
- **Optional parallel processing** with crew workers (native R only)
- **Comprehensive statistics tracking** with percentiles and formatting
- **Interactive Shiny dashboards** with real-time parameter adjustment
- **WebR/browser support** via Shinylive (synchronous mode)
- **Programmatic API** for scripted simulations
- **S3 plot methods** (`plot(result)` works directly)
- **Graceful fallback** to synchronous mode if parallel dependencies unavailable

## Installation

```r
# Option 1: Install from R-Universe (recommended - precompiled binaries)
install.packages("randomwalk",
  repos = c("https://johngavin.r-universe.dev", "https://cloud.r-project.org")
)

# Option 2: Install from GitHub
remotes::install_github("johngavin/randomwalk")

# Option 3: For development (after cloning repo)
# git clone https://github.com/JohnGavin/randomwalk.git
devtools::load_all()  # Load without installing
```


## Getting Started

### Quickstart Examples

Choose your preferred interface:

#### Option 1: Programmatic Usage (No GUI)

#### Basic Example

```r
library(randomwalk)

# Run a simulation (synchronous mode, fast)
result <- run_simulation(
  grid_size = 50,
  n_walkers = 100,
  neighborhood = c("4-hood", "8-hood"),  # First value is default
  boundary = c("terminate", "wrap")       # First value is default
)

# Access simulation results
# result$grid         # Final grid state (matrix) - avoid printing large grids!
result$statistics     # Statistics list
str(result$walkers, list.len = 2)  # Walker objects (limit output)

# Plot the result using S3 method
plot(result)                                    # Same as plot_grid(result)
plot_grid(result, main = "My Simulation")       # With custom title
plot_walker_paths(result)                       # Show walker trajectories
```

#### Async Parallel Processing

The package supports parallel walker processing when using `workers > 0`:

```r
library(randomwalk)

# RECOMMENDED: Chunked mode for best collision detection
# - Processes walkers in batches of 10
# - Grid updates between batches
# - ~15% collision detection rate
result_chunked <- run_simulation(
  grid_size = 50,
  n_walkers = 100,
  neighborhood = "4-hood",
  sync_mode = "chunked",  # RECOMMENDED
  workers = 4
)

# Static mode: Snapshot-based synchronization
# - Workers see frozen grid snapshots
# - Faster but lower collision detection (~5%)
result_static <- run_simulation(
  grid_size = 50,
  n_walkers = 100,
  sync_mode = "static",  # Snapshot mode
  workers = 4
)

# Check collision detection
cat("Chunked collisions:", result_chunked$statistics$black_pixels, "\n")
cat("Static collisions:", result_static$statistics$black_pixels, "\n")
```

**Note on WebR/Browser**: Browser demos use `workers = 0` (synchronous mode). Async parallel processing requires native R.


#### Comparing Sync Modes: Static vs Chunked (RECOMMENDED)

The `sync_mode` parameter controls how parallel workers share grid state. **Chunked mode is recommended** for better collision detection:

```r
library(randomwalk)

# STATIC MODE: All workers see frozen grid snapshot
# - Fast but workers can't see each other's black pixels
# - Lower collision detection rate
result_static <- run_simulation(
  grid_size = 50,
  n_walkers = 100,
  workers = 2,

  sync_mode = "static",
  quiet = TRUE
)

# CHUNKED MODE (RECOMMENDED): Near-real-time grid updates
# - Processes walkers in batches of 10
# - Grid updated between batches
# - Later batches see black pixels from earlier batches
# - ~3x more collisions detected
result_chunked <- run_simulation(
  grid_size = 50,
  n_walkers = 100,
  workers = 2,
  sync_mode = "chunked",
  quiet = TRUE
)

# Compare results
cat("Static mode:  ", result_static$statistics$black_pixels, "black pixels\n")
cat("Chunked mode: ", result_chunked$statistics$black_pixels, "black pixels\n")
# Typical output:
# Static mode:   5 black pixels
# Chunked mode:  15 black pixels  (3x more!)

# View detailed statistics
print(result_chunked$statistics$termination_reasons)
# black_neighbor_detected: 15, boundary: 84, started_on_black: 1

# Plot the final grid
plot_grid(result_chunked$grid)

# Plot walker paths (if available)
plot_walker_paths(result_chunked)
```

**Logging control:**
- `quiet = TRUE` - Suppress progress logs (recommended for scripts)
- `quiet = FALSE` (default) - Show batch progress
- `verbose = TRUE` - Show detailed debug logs

| Mode | Description | Collision Detection | Use Case |
|------|-------------|---------------------|----------|
| `static` | Frozen grid snapshot | Low (~5%) | Fast runs, boundary testing |
| `chunked` | Batched updates (10/batch) | High (~15%) | **Recommended for most uses** |

#### Option 2: Interactive Shiny Dashboard

```r
library(randomwalk)

# Launch the Shiny app
run_dashboard()

# In Nix shell or iTerm: disable auto-launch if browser fails
run_dashboard(launch.browser = FALSE)
# Then manually open http://127.0.0.1:4596 in your browser

# Or specify a custom browser function
run_dashboard(launch.browser = function(url) {
  system(paste0("open ", shQuote(url)))  # macOS default browser
})
```

**Note**: If you see `Error in utils::browseURL(appUrl): 'browser' must be a non-empty character string`, use `launch.browser = FALSE` and manually open the URL printed to the console.

#### Option 3: Browser Demo (WebR/Shinylive)

**[Launch Interactive Dashboard](https://johngavin.github.io/randomwalk/articles/dashboard_comprehensive.html)** - No installation required! Runs entirely in your browser via WebAssembly.

## Configuration & Environments

### Nix Environment

The package provides reproducible R environments via Nix. Two configurations are available depending on your needs.

### Using Nix Shell (Users)

For **users** who just want to run randomwalk (not develop it), use `shell.nix`:

```bash
# Clone the repository
git clone https://github.com/JohnGavin/randomwalk.git
cd randomwalk

# Enter the user environment (includes all runtime dependencies)
nix-shell shell.nix

# Start R
R -q --no-save
```

```r
# Install randomwalk (choose one):

# Option 1: From R-Universe (recommended - prebuilt binaries)
install.packages("randomwalk",
  repos = c("https://johngavin.r-universe.dev", "https://cloud.r-project.org"))

# Option 2: From GitHub (latest pushed version)
remotes::install_github("JohnGavin/randomwalk")

# Option 3: From local source (for development)
devtools::load_all(".")

# Then use the package:
library(randomwalk)
result <- run_simulation(grid_size = 20, n_walkers = 10)
plot(result)

# With parallel workers (use chunked mode for best results)
result <- run_simulation(grid_size = 30, n_walkers = 20,
                         workers = 2, sync_mode = "chunked")
```

### Using Nix Shell (Developers)

For **developers** who need devtools, pkgdown, etc., use `default.nix`:

```bash
# Start the nix shell (one-time per session)
caffeinate -i ~/docs_gh/rix.setup/default.sh

# Verify you're in the nix environment
echo $IN_NIX_SHELL  # Should output: 1 or impure
which R             # Should output: /nix/store/.../bin/R

# Install randomwalk from binary cache (recommended)
R --quiet --no-save
```

```r
# Inside R: Install from R-Universe (precompiled binaries)
install.packages("randomwalk",
  repos = c(
    "https://johngavin.r-universe.dev",  # R-Universe binary cache
    "https://cloud.r-project.org"        # CRAN fallback
  )
)

# Or install from GitHub source
# remotes::install_github("johngavin/randomwalk")

# Or for development, load from local source
# devtools::load_all(".")

# Use the package
library(randomwalk)
result <- run_simulation(grid_size = 20, n_walkers = 5)
plot_grid(result)
```

**Installation Options:**
1. **Binary cache (fastest)**: Install from `johngavin.r-universe.dev` - precompiled WASM binaries
2. **GitHub source**: Install with `remotes::install_github("johngavin/randomwalk")`
3. **Local development**: Use `devtools::load_all(".")` from the repository directory

**Note**: The nix shell provides a reproducible R environment. See the [Wiki Nix Troubleshooting](https://github.com/JohnGavin/randomwalk/wiki/Troubleshooting-Nix-Environment) guide.

### Nix Files Overview

| File | Purpose | Audience |
|------|---------|----------|
| `shell.nix` | Runtime environment with randomwalk from GitHub | End users |
| `default.nix` | Full dev environment (devtools, pkgdown, testing) | Developers |
| `default-ci.nix` | Minimal environment for CI/CD workflows | GitHub Actions |
| `package.nix` | Package definition for nix builds | Infrastructure |

## Advanced Topics

### Parallel Processing Architecture

The package uses a layered architecture for parallel execution:

```
Application Layer:    randomwalk::run_simulation()
                             ↓
Worker Management:    crew (worker pools, task distribution)
                             ↓
Async Framework:      mirai (parallel task execution)
                             ↓
Messaging Layer:      nanonext (NNG socket bindings)
```

### Package Dependencies

| Package | Purpose | Native R | WebR/WASM |
|---------|---------|----------|-----------|
| **crew** | Worker pool management | ✅ Available | ❌ Not available |
| **mirai** | Async task execution | ✅ Available | ✅ Available |
| **nanonext** | Low-level messaging (NNG) | ✅ Available | ✅ Available* |

*nanonext is available in WASM but sockets cannot be created inside forked subprocesses.

### Chunked Synchronization

The `sync_mode = "chunked"` mode processes walkers in batches of 10 and updates the grid between batches. This approach gives later batches visibility of black pixels from earlier batches, achieving superior collision detection (~15%) compared to static mode (~5%) without complex socket-based synchronization.

### Simulation Parameters

| Parameter | Description | Default | Range |
|-----------|-------------|---------|-------|
| `grid_size` | n×n simulation grid | 10 | 10-500 |
| `n_walkers` | Number of random walkers | 5 | 1 to 60% of grid cells |
| `neighborhood` | Movement pattern | "4-hood" | "4-hood" (NSEW), "8-hood" (diagonals) |
| `boundary` | Edge behavior | "terminate" | "terminate", "wrap" (torus) |
| `workers` | Parallel R processes | 0 | 0-16 |
| `sync_mode` | Grid synchronization | "static" | See table below |
| `max_steps` | Max steps per walker | 1000 | 100-50000 |

### Sync Mode Options

| Mode | Description | Collision Detection | Recommendation |
|------|-------------|---------------------|----------------|
| `static` | Frozen grid snapshots | Low (~5%) | Fast runs |
| `chunked` | Batched updates (10/batch) | High (~15%) | **RECOMMENDED** |

### Scalability

The package scales from quick tests to large simulations:

```r
# Quick test (< 1 second)
run_simulation(grid_size = 20, n_walkers = 10, workers = 0)

# Typical use (2-5 seconds with parallel)
run_simulation(grid_size = 100, n_walkers = 500, workers = 4, sync_mode = "chunked")

# Large scale (30-60 seconds)
run_simulation(grid_size = 200, n_walkers = 2000, workers = 4, sync_mode = "chunked")

# Stress test (several minutes)
run_simulation(grid_size = 400, n_walkers = 10000, workers = 8, sync_mode = "chunked")
```

**Performance Tips:**
- Use `workers = 4` for most systems (matches typical CPU cores)
- Use `sync_mode = "chunked"` for best collision detection with parallel workers
- Larger grids (200+) benefit most from parallelization
- Browser demos are limited to `workers = 0` (sync mode)

### WebR/Browser Restrictions

- **Async parallel processing (workers > 0) is only available in native R**. Browser demos use `workers = 0` (synchronous mode only).
- **Recommended approach for parallel processing**: Use `sync_mode = "chunked"` with `workers = 2-4` for best collision detection and performance in native R environments.

## Documentation

### Vignettes

- **[Interactive Dashboard](https://johngavin.github.io/randomwalk/articles/dashboard_comprehensive.html)** - Full-featured dashboard in-browser via WebR
- **[Step Distribution Analysis](https://johngavin.github.io/randomwalk/articles/step_distribution_analysis.html)** - Statistical analysis of path lengths
- **[Telemetry](https://johngavin.github.io/randomwalk/articles/telemetry.html)** - Pipeline performance and code coverage

### Deployment & Workflow

- **[Deployment Guide](inst/docs/DEPLOYMENT_GUIDE.md)** - Complete deployment workflow (GitHub Actions → GitHub Pages)
- **[Cachix Workflow](inst/docs/CACHIX_WORKFLOW.md)** - Binary cache management with rix
- **[Development Workflow](inst/docs/DEVELOPMENT_WORKFLOW.md)** - Complete guide for developing the randomwalk package
- **[WASM Async Status](inst/docs/WASM_ASYNC_STATUS.md)** - WebAssembly async compatibility status

### Critical Workflows

- **[Pkgdown/Quarto Workflow](inst/docs/PKGDOWN_QUARTO_WORKFLOW.md)** - CRITICAL: Build locally, deploy remotely (Nix + bslib incompatibility)
- **[Quarto-WebR Migration Plan](inst/docs/PLAN_quarto_webr_migration.md)** - Plan to migrate from Shinylive to Quarto-WebR

### Issue Tracking

- **[Open Issues](https://github.com/JohnGavin/randomwalk/issues)** - GitHub issue tracker (primary)
- **[Project Board](https://github.com/JohnGavin/randomwalk/projects)** - Visual progress tracking

### Package Structure

```
randomwalk/
├── R/                          # Core package code
│   ├── simulation.R           # Main simulation functions
│   ├── walker.R               # Walker movement logic
│   ├── grid.R                 # Grid management
│   ├── plotting.R             # Visualization functions
│   ├── async_controller.R     # Crew controller management
│   ├── async_worker.R         # Worker process functions
│   ├── shiny_modules.R        # Shiny UI/server modules
│   ├── setup/                 # Development workflow scripts
│   ├── log/                   # Git/GitHub operation logs
│   └── plans/                 # Targets pipeline plans
│
├── inst/                      # Installed package files
│   ├── shiny/                 # Shiny dashboard applications
│   │   ├── dashboard/         # Sync dashboard
│   │   └── dashboard_async/   # Async dashboard
│   ├── docs/                  # Additional documentation
│   │   └── DEVELOPMENT_WORKFLOW.md
│   └── qmd/                   # Source Quarto documents
│
├── vignettes/                 # Package vignettes
│   ├── dashboard_comprehensive.qmd # Interactive dashboard (✅ active)
│   ├── dashboard.qmd          # Interactive dashboard (⏸️ disabled, Issue #132)
│   ├── dashboard_async.qmd    # Async dashboard (⏸️ disabled, Issue #132)
│   └── telemetry.qmd          # Telemetry statistics (⏸️ disabled, Issue #132)
│
├── tests/                     # Test suite
│   └── testthat/              # testthat unit tests
│
├── man/                       # Generated documentation
├── _targets.R                 # Targets pipeline definition
├── _pkgdown.yml               # pkgdown configuration
├── default-ci.nix             # Nix environment for CI
└── default.nix                # Nix environment for development
```

### Guides & Troubleshooting

Visit the [project wiki](https://github.com/JohnGavin/randomwalk/wiki) for comprehensive guides:

- **[Troubleshooting Nix Environment](https://github.com/JohnGavin/randomwalk/wiki/Troubleshooting-Nix-Environment)** - Solutions for nix environment issues
- **[Deploying Shinylive Dashboards](https://github.com/JohnGavin/randomwalk/wiki/Deploying-Shinylive-Dashboards)** - Deployment guide with solutions to common issues
- **[Working with Claude Across Sessions](https://github.com/JohnGavin/randomwalk/wiki/Working-with-Claude-Across-Sessions)** - Preserve context when using Claude Code
- **[Using Gemini for Large Codebases](https://github.com/JohnGavin/randomwalk/wiki/Using-Gemini-CLI-for-Large-Codebases)** - Large context window codebase analysis

## License

MIT
