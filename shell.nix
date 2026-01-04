# shell.nix - User environment with randomwalk installed from GitHub
#
# This builds randomwalk from GitHub (main branch) and provides all runtime
# dependencies. Uses fetchGit which always gets the latest from the branch.
#
# Usage:
#   nix-shell shell.nix              # Enter shell with randomwalk installed
#   nix-shell shell.nix --run "R -q --no-save -e 'library(randomwalk); run_simulation()'"
#
# For development (devtools, pkgdown, etc.), use default.nix instead.
#
# To pin to a specific version, uncomment and set the 'rev' field in fetchGit.

{ pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/1482d00f8f658fd443526febba6c9fd9754cb356.tar.gz") {}
}:

let
  # Fetch randomwalk source from GitHub using fetchGit (no sha256 needed)
  # Uses "main" branch by default - always gets latest
  gitRef = "main";  # Can be branch, tag, or commit SHA

  randomwalkSrc = builtins.fetchGit {
    url = "https://github.com/JohnGavin/randomwalk.git";
    ref = gitRef;
    # Uncomment to pin to specific commit:
    # rev = "abc123...";  # Full 40-char SHA
  };

  # Build randomwalk as a Nix package
  randomwalk = pkgs.rPackages.buildRPackage {
    name = "randomwalk";
    src = randomwalkSrc;

    # Runtime dependencies (from DESCRIPTION Imports)
    propagatedBuildInputs = with pkgs.rPackages; [
      logger
      ggplot2
    ];

    # Optional dependencies for full functionality
    buildInputs = with pkgs.rPackages; [
      crew
      mirai
      nanonext
      shiny
      dplyr
    ];
  };

  # Additional packages for the shell environment
  additionalPackages = with pkgs.rPackages; [
    devtools   # For development if needed
    remotes    # For installing other packages
  ];

  # R with all packages
  rWithPackages = pkgs.rWrapper.override {
    packages = [ randomwalk ] ++ additionalPackages;
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
    echo "║ randomwalk installed from GitHub (ref: ${gitRef})               ║"
    echo "║ Includes: logger, ggplot2, crew, mirai, nanonext, shiny, dplyr ║"
    echo "╠════════════════════════════════════════════════════════════════╣"
    echo "║ Quick Start:                                                   ║"
    echo "║   R -q --no-save                                               ║"
    echo "║   library(randomwalk)                                          ║"
    echo "║   result <- run_simulation(grid_size = 20, n_walkers = 10)     ║"
    echo "║   plot(result)                                                 ║"
    echo "║                                                                ║"
    echo "║ For parallel (use chunked mode):                               ║"
    echo "║   result <- run_simulation(workers = 2, sync_mode = 'chunked') ║"
    echo "║                                                                ║"
    echo "║ For dashboard:                                                 ║"
    echo "║   run_dashboard()                                              ║"
    echo "╠════════════════════════════════════════════════════════════════╣"
    echo "║ For development tools, use: nix-shell default.nix              ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
  '';

  # Don't use user library (use nix packages only)
  R_LIBS_USER = "";
}
