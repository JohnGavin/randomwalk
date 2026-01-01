# shell.nix - User-focused environment for running randomwalk package
#
# This provides a minimal environment for USERS (not developers) to run
# the randomwalk package with all its features.
#
# Usage:
#   nix-shell shell.nix              # Enter shell with R + dependencies
#   nix-shell shell.nix --run R      # Start R directly
#   nix-shell shell.nix --run "Rscript -e 'library(randomwalk); run_simulation()'"
#
# For development (devtools, pkgdown, etc.), use default.nix instead.
#
# Note: Uses same nixpkgs revision as package.nix for consistency.

{ pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/1482d00f8f658fd443526febba6c9fd9754cb356.tar.gz") {}
}:

let
  # Core dependencies (from DESCRIPTION Imports)
  coreDeps = with pkgs.rPackages; [
    logger
    ggplot2
  ];

  # Async/parallel dependencies (from DESCRIPTION Suggests)
  # These enable workers > 0 for parallel simulations
  asyncDeps = with pkgs.rPackages; [
    crew
    mirai
    nanonext
  ];

  # Shiny dashboard dependencies (optional, for run_dashboard())
  shinyDeps = with pkgs.rPackages; [
    shiny
  ];

  # Data dependencies (optional, for advanced features)
  dataDeps = with pkgs.rPackages; [
    dplyr
    duckdb
  ];

  # All user-facing dependencies
  allDeps = coreDeps ++ asyncDeps ++ shinyDeps ++ dataDeps;

  # R with packages
  rWithPackages = pkgs.rWrapper.override {
    packages = allDeps;
  };

in pkgs.mkShell {
  name = "randomwalk-user";

  buildInputs = [
    rWithPackages
  ];

  shellHook = ''
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║              randomwalk User Environment                       ║"
    echo "╠════════════════════════════════════════════════════════════════╣"
    echo "║ Core packages:  logger, ggplot2                                ║"
    echo "║ Async packages: crew, mirai, nanonext (for parallel sims)      ║"
    echo "║ Shiny:          shiny (for run_dashboard())                    ║"
    echo "║ Data:           dplyr, duckdb                                  ║"
    echo "╠════════════════════════════════════════════════════════════════╣"
    echo "║ Quick Start:                                                   ║"
    echo "║   R                                                            ║"
    echo "║   > library(randomwalk)                                        ║"
    echo "║   > result <- run_simulation(grid_size = 20, n_walkers = 10)   ║"
    echo "║   > plot_grid(result)                                          ║"
    echo "║                                                                ║"
    echo "║ For async parallel (native R only):                            ║"
    echo "║   > result <- run_simulation(workers = 2)                      ║"
    echo "║                                                                ║"
    echo "║ For interactive dashboard:                                     ║"
    echo "║   > run_dashboard()                                            ║"
    echo "╠════════════════════════════════════════════════════════════════╣"
    echo "║ For development tools, use: nix-shell default.nix              ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
  '';

  # Environment variables
  R_LIBS_USER = "";  # Don't use user library (use nix packages only)
}
