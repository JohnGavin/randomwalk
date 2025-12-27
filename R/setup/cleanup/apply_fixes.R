# R/setup/apply_fixes.R
# Complete workflow to apply telemetry fixes
# Run this entire script in ONE nix shell session

library(logger)
library(targets)

# Setup logging
log_appender(appender_file("inst/logs/apply_fixes.log"))
log_info("=== Starting fix application workflow ===")

# Step 1: Invalidate affected targets
log_info("Invalidating affected targets: sim_large, stats_large, plot_large_grid")
targets::tar_invalidate(c("sim_large", "stats_large", "plot_large_grid"))

# Step 2: Rebuild targets pipeline
# The _targets.R file will handle loading the package via devtools::load_all()
log_info("Running targets pipeline - this will take 1-5 minutes due to large simulation")
log_info("Large simulation: 20 walkers, 100k max_steps, target >25% coverage")
targets::tar_make()
log_info("Targets pipeline complete")

# Step 3: Build pkgdown site
log_info("Building pkgdown site")
pkgdown::build_site()
log_info("pkgdown site built successfully")

log_info("=== Fix application workflow complete ===")
log_info("Next steps:")
log_info("1. Review changes in browser")
log_info("2. Commit using gert/gh packages")
log_info("3. Push to GitHub")
