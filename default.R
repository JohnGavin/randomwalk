# default.R for randomwalk package
# Generate default.nix using rix::rix()
# Per context.md: Use this file to define the Nix environment, then regenerate default.nix

library(rix)

# R packages required for randomwalk development
r_pkgs <- c(
  # Core dependencies (from DESCRIPTION Imports)
  "logger",

  # Suggested packages for functionality
  "dplyr",
  "duckdb",
  "ggplot2",
  "nanonext",
  "shiny",

  # Targets pipeline
  "targets",
  "tarchetypes",

  # Visualization
  "visNetwork",

  # Testing and coverage
  "testthat",
  "covr",

  # Development tools
  "devtools",  # Also installs usethis
  "gert",
  "roxygen2",

  # Documentation
  "pkgdown",
  "knitr",
  "rmarkdown",
  "quarto"
) |>
  unique() |>
  sort()

# System packages needed
system_pkgs <- c(
  "git",
  "gh",          # GitHub CLI
  "quarto",
  "pandoc",
  "tree"
) |>
  unique() |>
  sort()

# Get latest stable R version date
(latest <- available_dates() |> sort() |> tail(1))

# Generate default.nix
rix(
  date = "2025-10-27",  # Same as original for consistency
  r_pkgs = r_pkgs,
  system_pkgs = system_pkgs,
  git_pkgs = NULL,
  project_path = ".",
  overwrite = TRUE,
  ide = "none"  # Can be changed to "rstudio" or "positron" if desired
)

cli::cli_alert_success("Generated default.nix for randomwalk package")
cli::cli_alert_info("Review the generated default.nix and commit both default.R and default.nix")
