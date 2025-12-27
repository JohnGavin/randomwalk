# R/setup/clean_vignette_output.R
# Cleans up generated vignette output files to resolve R CMD check NOTES.

# Ensure fs package is available
if (!requireNamespace("fs", quietly = TRUE)) {
  install.packages("fs")
}
library(fs)
library(logger)

log_info("Cleaning up generated vignette output files...")

vignettes_dir <- "vignettes"

# Directories to remove
dirs_to_remove <- c(
  file.path(vignettes_dir, ".quarto"),
  file.path(vignettes_dir, "dashboard_async_files"),
  file.path(vignettes_dir, "dashboard_files"),
  file.path(vignettes_dir, "dynamic_broadcasting_files"),
  file.path(vignettes_dir, "telemetry_files") # Include telemetry if it generates one
)

# Files to remove (built HTML)
files_to_remove <- c(
  file.path(vignettes_dir, "dashboard_async.html"),
  file.path(vignettes_dir, "dashboard.html"),
  file.path(vignettes_dir, "dynamic_broadcasting.html"),
  file.path(vignettes_dir, "telemetry.html")
)

# Remove directories
for (dir_path in dirs_to_remove) {
  if (dir_exists(dir_path)) {
    dir_delete(dir_path)
    log_info("Removed directory: {dir_path}")
  }
}

# Remove files
for (file_path in files_to_remove) {
  if (file_exists(file_path)) {
    file_delete(file_path)
    log_info("Removed file: {file_path}")
  }
}

log_info("Vignette cleanup complete.")
