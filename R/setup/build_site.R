# Build script for randomwalk package website
# This script handles the complete workflow:
# 1. Run targets pipeline to pre-compute vignette objects
# 2. Render vignettes with access to targets data
# 3. Build pkgdown site

library(targets)
library(rmarkdown)
library(pkgdown)

# Step 1: Load package
message("Loading randomwalk package...")
devtools::load_all()

# Step 2: Run targets pipeline
message("Running targets pipeline...")
targets::tar_make(callr_function = NULL)

# Step 3: Pre-build vignettes
message("Pre-building vignettes...")
rmarkdown::render(
  input = "vignettes/telemetry.qmd",
  output_dir = "vignettes",
  knit_root_dir = getwd()
)

# Step 4: Copy pre-built vignette to docs/articles
message("Copying pre-built vignette to docs...")
dir.create("docs/articles", recursive = TRUE, showWarnings = FALSE)
file.copy(
  "vignettes/telemetry.html",
  "docs/articles/telemetry.html",
  overwrite = TRUE
)

# Step 5: Build pkgdown site (skip article building)
message("Building pkgdown reference and home...")
pkgdown::build_reference()
pkgdown::build_home()

# Step 6: Build article index
message("Building article index...")
pkgdown::build_articles_index()

message("Site build complete! Open docs/index.html to view.")
