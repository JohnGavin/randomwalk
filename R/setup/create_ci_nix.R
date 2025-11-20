# Create minimal default-ci.nix for Issue #34
# Purpose: Generate optimized Nix environment for CI/CD

library(rix)

# Load minimal package list from audit
ci_packages <- readRDS("R/setup/ci_packages.rds")

cat("Creating minimal default-ci.nix with", length(ci_packages), "packages...\n")
cat("Packages:", paste(ci_packages, collapse = ", "), "\n\n")

# Safety: Back up existing default.nix if it exists
if (file.exists("default.nix") && !file.exists("default-dev.nix")) {
  cat("Backing up existing default.nix to default-dev.nix...\n")
  file.copy("default.nix", "default-dev.nix")
}

# Create temp directory for generation
tmp_dir <- tempdir()
tmp_project <- file.path(tmp_dir, "ci_nix")
dir.create(tmp_project, showWarnings = FALSE, recursive = TRUE)

# Generate minimal CI/CD nix environment in temp directory
rix::rix(
  r_ver = "latest-upstream",
  r_pkgs = ci_packages,
  system_pkgs = NULL,
  git_pkgs = NULL,
  ide = "none",
  project_path = tmp_project,
  overwrite = TRUE,
  print = FALSE,
  shell_hook = NULL
)

# Copy the generated file to project root as default-ci.nix
tmp_nix <- file.path(tmp_project, "default.nix")
if (file.exists(tmp_nix)) {
  file.copy(tmp_nix, "default-ci.nix", overwrite = TRUE)
  cat("\n✅ Created default-ci.nix\n")
  cat("   Location: ", normalizePath("default-ci.nix"), "\n", sep = "")
  cat("   Packages: ", length(ci_packages), "\n", sep = "")
  cat("   Size reduction: ~100+ packages → ", length(ci_packages), " packages\n\n", sep = "")

  # Show first few lines
  cat("Preview of default-ci.nix:\n")
  cat(paste(head(readLines("default-ci.nix"), 10), collapse = "\n"))
  cat("\n...\n\n")
} else {
  cat("\n❌ Failed to create default-ci.nix\n")
}

cat("Files:\n")
cat("- default.nix (development, ~100+ packages) - unchanged\n")
cat("- default-dev.nix (backup of original) - created\n")
cat("- default-ci.nix (CI/CD, ", length(ci_packages), " packages) - created\n\n", sep = "")

cat("Next: Update .github/workflows to use default-ci.nix\n")
