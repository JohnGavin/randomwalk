# Regenerate default.nix from default.R
# This script should be run from the project root directory
# Date: 2025-11-10
# Issue: #16 - Need to regenerate default.nix with ggplot2

# IMPORTANT: This must be run from the project root:
# cd /Users/johngavin/docs_gh/claude_rix/random_walk
# Rscript R/setup/regenerate_nix.R

# Verify we're in the right directory
if (!file.exists("default.R")) {
  stop("ERROR: default.R not found. Run this from the project root directory.")
}

# Check if rix is available
if (!requireNamespace("rix", quietly = TRUE)) {
  stop("ERROR: rix package is required. Install it with install.packages('rix')")
}

cat("Regenerating default.nix from default.R...\n")
cat("This ensures all dependencies (including ggplot2) are in the nix environment.\n\n")

# Source the default.R file which will regenerate default.nix
source("default.R")

cat("\n✓ default.nix regenerated successfully!\n")
cat("✓ Verify ggplot2 is now included in default.nix\n")
cat("\nNext steps:\n")
cat("1. Review the generated default.nix\n")
cat("2. git add default.nix\n")
cat("3. Commit both default.R and default.nix together\n")
