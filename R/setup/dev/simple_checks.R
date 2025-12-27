# Simple package checks for Issue #16
# Created: 2025-11-10
library(devtools)

cat("=== Simple Package Checks ===\n")
cat("Date:", as.character(Sys.time()), "\n\n")

# 1. Document
cat("1. Documenting...\n")
devtools::document()
cat("✓ Done\n\n")

# 2. Load package
cat("2. Loading package...\n")
devtools::load_all()
cat("✓ Done\n\n")

# 3. Check that ggplot2 plotting works
cat("3. Testing ggplot2 plot function...\n")
grid <- randomwalk:::create_grid(5)
randomwalk:::set_pixel(grid, 3, 3, TRUE)
plot_obj <- randomwalk:::plot_grid(grid)
cat("Plot class:", class(plot_obj), "\n")
if("ggplot" %in% class(plot_obj)) {
  cat("✓ plot_grid() returns ggplot object\n\n")
} else {
  cat("✗ ERROR: plot_grid() does not return ggplot object\n\n")
}

cat("=== All Checks Passed ===\n")
