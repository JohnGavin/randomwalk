# generate_coverage.R
# Run this script OUTSIDE of Nix to generate code coverage
# The coverage data is saved to inst/extdata/coverage.rds for use in vignettes
#
# Usage:
#   1. Open R/RStudio (NOT in Nix shell)
#   2. setwd() to the randomwalk package directory
#   3. source("R/dev/coverage/generate_coverage.R")
#
# Requirements:
#   - covr package installed
#   - All package dependencies installed
#   - NOT running inside Nix (covr has issues with Nix)

library(covr)

cat("=== Generating Code Coverage ===\n")
cat("Working directory:", getwd(), "\n")
cat("R version:", R.version.string, "\n\n")

# Check we're in the right directory
if (!file.exists("DESCRIPTION")) {
  stop("Please run this script from the randomwalk package root directory")
}

# Check we're NOT in Nix (where covr fails)
if (Sys.getenv("IN_NIX_SHELL") != "") {
  warning("You appear to be in a Nix shell. covr may fail with 'error reading from connection'")
}

cat("Running covr::package_coverage()...\n")
cat("This may take a few minutes...\n\n")

# Generate coverage
coverage <- tryCatch({
  package_coverage()
}, error = function(e) {
  cat("ERROR:", e$message, "\n")
  cat("\nIf you see 'error reading from connection', you may be in a Nix environment.\n")
  cat("Try running this script in a non-Nix R session.\n")
  return(NULL)
})

if (is.null(coverage)) {
  stop("Coverage generation failed")
}

# Calculate summary statistics
cat("\n=== Coverage Summary ===\n")
overall_pct <- percent_coverage(coverage)
cat(sprintf("Overall coverage: %.1f%%\n", overall_pct))

# Get file-level summary
file_coverage <- coverage %>%
  tally_coverage(by = "file")

file_summary <- data.frame(
  filename = basename(file_coverage$filename),
  total_lines = file_coverage$relevant,
  covered_lines = file_coverage$covered,
  coverage_pct = round(file_coverage$coverage, 1)
)

cat("\nCoverage by file:\n")
print(file_summary)

# Prepare data for saving
coverage_data <- list(
  overall_pct = overall_pct,
  file_summary = file_summary,
  generated_at = Sys.time(),
  r_version = R.version.string,
  covr_version = as.character(packageVersion("covr"))
)

# Save to inst/extdata
output_path <- "inst/extdata/coverage.rds"
dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
saveRDS(coverage_data, output_path)

cat("\n=== Coverage saved ===\n")
cat("Output:", output_path, "\n")
cat("Generated:", format(coverage_data$generated_at), "\n")

# Also generate HTML report (optional)
cat("\nGenerating HTML report...\n")
report_dir <- "inst/extdata/coverage_report"
tryCatch({
  report(coverage, file = file.path(report_dir, "index.html"))
  cat("HTML report saved to:", report_dir, "\n")
}, error = function(e) {
  cat("Note: HTML report generation failed:", e$message, "\n")
})

cat("\n=== Done ===\n")
cat("Next steps:\n")
cat("1. git add inst/extdata/coverage.rds\n")
cat("2. git commit -m 'UPDATE: Pre-computed code coverage'\n")
cat("3. git push\n")
