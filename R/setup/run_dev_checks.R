# Run development checks for Issue #16
# Created: 2025-11-10
# Purpose: Document, test, and check the package after fixing visualizations
# Log file for reproducibility per context.md

library(devtools)
library(logger)

cat("=== Package Development Checks ===\n")
cat("Date:", as.character(Sys.time()), "\n")
cat("Working directory:", getwd(), "\n")
cat("R version:", R.version.string, "\n\n")

# Step 1: Document
cat("=== Step 1: devtools::document() ===\n")
try({
  devtools::document()
  cat("✓ Documentation updated\n\n")
}, silent = FALSE)

# Step 2: Test
cat("=== Step 2: devtools::test() ===\n")
try({
  test_results <- devtools::test()
  print(test_results)
  cat("✓ Tests completed\n\n")
}, silent = FALSE)

# Step 3: Check
cat("=== Step 3: devtools::check() ===\n")
try({
  check_results <- devtools::check(error_on = "never")
  cat("\n✓ R CMD check completed\n")
  cat("Errors:", check_results$errors %>% length(), "\n")
  cat("Warnings:", check_results$warnings %>% length(), "\n")
  cat("Notes:", check_results$notes %>% length(), "\n\n")
}, silent = FALSE)

cat("=== Checks Complete ===\n")
cat("Review results above before committing\n")
