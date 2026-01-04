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

- [Basic Demo](https://johngavin.github.io/randomwalk/articles/dynamic_broadcasting.html) - Try simulation in your browser (WebR)
- [Full-Featured Dashboard](https://johngavin.github.io/randomwalk/articles/dashboard_comprehensive.html) - Walker paths, statistics, debug info
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

## Interactive Browser Demos

Try the simulation directly in your browser (no installation required):

### Basic Demo
**[Launch Basic Demo](https://johngavin.github.io/randomwalk/articles/dynamic_broadcasting.html)**

Minimal interactive demo - try random walks in your browser with basic controls.

### Full-Featured Dashboard
**[Launch Full-Featured Dashboard](https://johngavin.github.io/randomwalk/articles/dashboard_comprehensive.html)**

Complete dashboard for in-depth exploration:
- **Multiple visualizations**: Fractal plots, walker paths, step distributions
- **Detailed statistics**: Grid stats, walker stats, performance metrics
- **Debug panel**: Package versions, backend selection, diagnostic info

Both dashboards run entirely in your browser using WebAssembly via [WebR](https://docs.r-wasm.org/webr/). Features include:

- Real-time parameter adjustment with sliders and dropdowns
- Synchronous mode (workers=0) for reliable in-browser execution
- Complete simulation statistics and detailed walker information
- No R installation or server required

> **Note**: Browser dashboards use synchronous mode. Async parallel processing (workers > 0) is available in native R only.

## Usage

### Programmatic Usage (No GUI)

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

#### Async Parallel with Dynamic Broadcasting (nanonext)

The package supports two async synchronization modes when using `workers > 0`:

```r
library(randomwalk)

# Dynamic mode: Real-time grid broadcasting via nanonext pub/sub
# - Walkers receive grid updates as they happen
# - More realistic collision detection
# - Requires nanonext package
result_dynamic <- run_simulation(
  grid_size = 20,
  n_walkers = 8,
  neighborhood = "4-hood",
  sync_mode = "dynamic",  # Use nanonext broadcasting
  workers = 2
)

# Static mode: Snapshot-based synchronization (original)
# - Walkers work on grid snapshots
# - Faster but less accurate collision detection
# - Default async mode
result_static <- run_simulation(
  grid_size = 20,
  n_walkers = 8,
  sync_mode = "static",  # Snapshot mode
  workers = 2
)
```

**Note on WebR/Browser**: The browser demos currently use `workers = 0` (synchronous mode) due to mirai/nanonext compatibility issues in WebAssembly. Async parallel processing with nanonext works in native R.

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
| `dynamic` | ⚠️ DEPRECATED - falls back to static | Low (~5%) | Do not use |
| `mirai_dynamic` | ⚠️ DEPRECATED - falls back to static | Low (~5%) | Do not use |

> **Note**: `dynamic` and `mirai_dynamic` modes are deprecated. nanonext sockets fail in crew/mirai subprocesses, causing these modes to behave like `static` mode. Use `chunked` instead.

### Interactive Shiny Interface

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

## Simulation Parameters

- **Grid Size**: n×n simulation grid (default 10×10)
- **Walkers**: Number of simultaneous random walkers (1 to 60% of grid, default 5)
- **Neighborhood**: 4-hood (NSEW) or 8-hood (includes diagonals)
- **Boundary**: Wrap-around (torus) or terminate at edges (default)
- **Workers**: Number of parallel R processes (0-16, default 0)
  - 0 = Synchronous mode (single process)
  - 2+ = Async parallel mode (requires crew package)
- **Sync Mode**: Grid synchronization for async simulations (default "static")
  - "static" = Workers get frozen grid snapshots (fast, some rejections expected)
  - "dynamic" = Workers get real-time updates (slower, enables collision detection)
- **Log Interval**: Progress logging frequency (default 50 walkers)
  - Set to 100+ for less verbose output
  - Set to 5-10 for detailed progress tracking

### Async Parallel Processing Notes

When using `workers > 0` with `sync_mode = "static"` (default), workers operate on frozen grid snapshots. This means:

- **Position rejections are normal**: Workers may propose positions that would create isolated pixels (violating 4-hood connectivity). These are rejected by the main process during validation.
- **High rejection rates with many workers**: With `boundary="terminate"` and many workers, rejection rates can be 90%+ for "black_neighbor" terminations. This is expected behavior - workers see phantom black pixels on stale snapshots that are no longer valid by the time results return.
  - Example: 8000 walkers, 8 workers → 631 "black_neighbor" terminations, but only 4-5 black pixels created (99% rejected)
  - Most walkers still hit boundaries successfully (typically 75-80%)
- **When to use static vs dynamic mode**:
  - **Static (default)**: Best for large grids with `boundary="terminate"`. Fast, but expect high rejection rates.
  - **Dynamic**: Use when you need accurate collision detection or when rejection rates are unacceptable. ~10-15% slower but eliminates rejections.
- **Logging**: Rejection messages are logged at DEBUG level (use `verbose=TRUE` to see them). Use `log_interval=100` or higher to reduce progress log verbosity.

## 📚 Vignettes & Documentation

### Available Vignettes

### **[Basic Random Walk Demo](https://johngavin.github.io/randomwalk/articles/dynamic_broadcasting.html)**
Minimal interactive demo running entirely in-browser via WebR. Quick start with basic controls - no R installation required.

### **[Full-Featured Dashboard](https://johngavin.github.io/randomwalk/articles/dashboard_comprehensive.html)** ✨
Complete dashboard for in-depth exploration including walker paths, step distributions, detailed statistics, and debug panel.

### **[Step Distribution Analysis](https://johngavin.github.io/randomwalk/articles/step_distribution_analysis.html)** 📊
Comprehensive analysis of random walk step distributions, parallel execution performance benchmarks, and visualization of density plots conditional on grid size and worker count.

### **[Telemetry and Pipeline Performance](https://johngavin.github.io/randomwalk/articles/telemetry.html)** 📈
Pipeline performance metrics including code coverage analysis, longest-running targets, memory usage statistics, and network visualization of the targets dependency graph.

### Temporarily Disabled Vignettes

The following vignettes are temporarily disabled (see [Issue #132](https://github.com/JohnGavin/randomwalk/issues/132)):

- **Interactive Dashboard** (dashboard.html) - Service Worker errors, requires Shinylive/webR update
- **Async/Parallel Dashboard** (dashboard_async.html) - ⚠️ **Use [Comprehensive Dashboard](https://johngavin.github.io/randomwalk/articles/dashboard_comprehensive.html) instead** - Same Service Worker issues as dashboard

> **Note**: For async parallel dashboard functionality, use the [Comprehensive Dashboard](https://johngavin.github.io/randomwalk/articles/dashboard_comprehensive.html) which includes all features from dashboard_async plus additional visualizations and statistics.

## 📋 Essential Documentation

Key documentation for development and deployment workflows:

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
│   ├── dynamic_broadcasting.qmd # Async parallel demo (✅ active)
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

## 📖 Documentation & Resources

### Wiki Guides

Visit the [project wiki](https://github.com/JohnGavin/randomwalk/wiki) for comprehensive guides:

- **[Troubleshooting Nix Environment](https://github.com/JohnGavin/randomwalk/wiki/Troubleshooting-Nix-Environment)** - Solutions for nix environment degradation during long development sessions
- **[Working with Claude Across Sessions](https://github.com/JohnGavin/randomwalk/wiki/Working-with-Claude-Across-Sessions)** - How to preserve context when using Claude Code
- **[Using Gemini CLI for Large Codebases](https://github.com/JohnGavin/randomwalk/wiki/Using-Gemini-CLI-for-Large-Codebases)** - Leverage Gemini's large context window for codebase analysis
- **[Deploying Shinylive Dashboards](https://github.com/JohnGavin/randomwalk/wiki/Deploying-Shinylive-Dashboards)** - Complete deployment guide with solutions to common issues

### Additional Resources

- **[Agent Guidelines](AGENTS.md)** - Mandatory testing requirements and workflow for AI agents
- [R/setup/](R/setup/) - Development workflow scripts for reproducibility
- [.github/workflows/](.github/workflows/) - CI/CD workflow configurations
- [archive/](archive/) - Historical session logs and documentation

## License

MIT
