# Nix environment for randomwalk R package
# Generated for development and CI/CD
let
  pkgs = import (fetchTarball "https://github.com/rstats-on-nix/nixpkgs/archive/2025-10-27.tar.gz") {
    config.allowUnfree = true;
  };

  rpkgs = builtins.attrValues {
    inherit (pkgs.rPackages)
      devtools
      usethis
      testthat
      logger
      dplyr
      duckdb
      nanonext
      shiny
      targets
      pkgdown
      covr
      gert
      roxygen2;
  };

  system_packages = builtins.attrValues {
    inherit (pkgs)
      quarto
      git
      R
      pandoc;
  };

  shell = pkgs.mkShell {
    LOCALE_ARCHIVE = if pkgs.system == "x86_64-linux" then "${pkgs.glibcLocales}/lib/locale/locale-archive" else "";
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";

    buildInputs = rpkgs ++ system_packages;
  };
in
  {
    inherit pkgs shell;
  }
