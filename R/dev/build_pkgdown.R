# Build pkgdown site with Shinylive Service Worker fix
# Created: 2025-12-19
# Related: Issue #15

#' Build pkgdown site and fix Shinylive Service Worker path
#'
#' This script:
#' 1. Builds the pkgdown site
#' 2. Copies shinylive-sw.js to site root (fixes Issue #15)
#'
#' Usage:
#'   source("R/dev/build_pkgdown.R")
#'
build_pkgdown_with_sw_fix <- function() {
  message("\n=== Building pkgdown site ===\n")

  # Build pkgdown site
  message("Step 1: Building pkgdown site...")
  pkgdown::build_site()

  # Fix Service Worker path
  message("\nStep 2: Fixing Shinylive Service Worker path...")
  source("R/dev/issues/fix_issue_15_sw_path.R")
  copy_shinylive_sw_to_root()

  message("\n=== Build complete! ===\n")
  message("Next steps:")
  message("1. Review changes: git status")
  message("2. Test locally: open docs/index.html")
  message("3. Commit and push to deploy")
}

# Run if sourced directly
if (!interactive()) {
  build_pkgdown_with_sw_fix()
}
