# Regenerate default.nix from default.R
# Created: 2025-11-10
# Purpose: Fix Issue #16 - regenerate default.nix with ggplot2 included
# Log file for reproducibility

cat("=== Regenerating default.nix ===\n")
cat("Date:", as.character(Sys.time()), "\n")
cat("Working directory:", getwd(), "\n\n")

# Source the default.R file to regenerate default.nix
cat("Sourcing default.R...\n")
source("default.R")

cat("\n=== Verification ===\n")
if (file.exists("default.nix")) {
  cat("✓ default.nix generated successfully\n")
  cat("File size:", file.size("default.nix"), "bytes\n")
} else {
  cat("✗ ERROR: default.nix was not created\n")
}

cat("\n=== Next Steps ===\n")
cat("1. Review the generated default.nix\n")
cat("2. Enter the new nix shell: nix-shell default.nix\n")
cat("3. Run devtools::document(), devtools::test(), devtools::check()\n")
cat("4. Commit changes with gert::git_add() and gert::git_commit()\n")
