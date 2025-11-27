# package.nix - Builds randomwalk R package as a Nix derivation from local source
#
# Usage:
#   nix-build package.nix           # Build the package
#   nix-shell package.nix           # Enter environment with randomwalk installed
#
# This derivation can be cached in Cachix and installed by downstream users.
# It uses the same nixpkgs revision as default-ci.nix for consistency.
#
# This is the file that GitHub Actions should build and push to cachix.

{ pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/1482d00f8f658fd443526febba6c9fd9754cb356.tar.gz") {}
}:

pkgs.rPackages.buildRPackage rec {
  name = "randomwalk";
  version = "2.0.0.9000";

  # Build from local source (current directory)
  src = ./.;

  # Runtime dependencies (Imports from DESCRIPTION)
  # These are propagated to users who install randomwalk
  propagatedBuildInputs = with pkgs.rPackages; [
    logger
    ggplot2
    crew
    nanonext
  ];

  # Build-time dependencies
  # Needed for R CMD INSTALL to succeed
  nativeBuildInputs = with pkgs.rPackages; [
    knitr       # For building vignettes
    rmarkdown   # For building vignettes
  ];

  # Test dependencies (optional, available during check phase)
  checkInputs = with pkgs.rPackages; [
    testthat
    munsell
    dplyr
    duckdb
  ];

  # Enable tests during build
  doCheck = false;  # Disable for now - can enable when tests are hermetic

  # Meta information
  meta = with pkgs.lib; {
    description = "Asynchronous Pixel Walking Simulation with Parallel Processing";
    longDescription = ''
      Implements parallel random walk simulations that create fractal
      graphs through asynchronous pixel walking on a grid. Features include
      true asynchronous parallel processing with separate R worker processes,
      real-time grid state synchronization via DuckDB, comprehensive statistics
      tracking, and an optional Shiny interface for interactive visualization.
      Core simulation functions can be used programmatically without the GUI.
    '';
    homepage = "https://github.com/JohnGavin/randomwalk";
    license = licenses.mit;
    maintainers = [];
    platforms = platforms.unix;
  };
}
