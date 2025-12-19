# Fix Issue #15: Shinylive Service Worker path mismatch in pkgdown articles
# Created: 2025-12-19
# Issue: https://github.com/JohnGavin/claude_rix/issues/15

# PROBLEM:
# - pkgdown puts articles in docs/articles/
# - Quarto shinylive extension sets meta tag: content=".."
# - Browser looks for /shinylive-sw.js (root)
# - File is actually at /articles/shinylive-sw.js
# - Result: "ServiceWorker controller was not found!" error

# SOLUTION:
# Copy shinylive-sw.js from docs/articles/ to docs/ (site root)

#' Copy Shinylive Service Worker to site root
#'
#' This function copies the shinylive-sw.js file from docs/articles/ to docs/
#' to fix the path mismatch issue with pkgdown + Quarto + Shinylive.
#'
#' @param docs_dir Path to docs directory (default: "docs")
#' @param verbose Print status messages (default: TRUE)
#' @return TRUE if successful, FALSE otherwise
copy_shinylive_sw_to_root <- function(docs_dir = "docs", verbose = TRUE) {
  source_path <- file.path(docs_dir, "articles", "shinylive-sw.js")
  dest_path <- file.path(docs_dir, "shinylive-sw.js")

  # Check if source file exists
  if (!file.exists(source_path)) {
    if (verbose) {
      message("⚠️  Source file not found: ", source_path)
      message("    This is expected if vignettes haven't been built yet.")
    }
    return(FALSE)
  }

  # Copy file
  success <- file.copy(
    from = source_path,
    to = dest_path,
    overwrite = TRUE
  )

  if (success && verbose) {
    message("✅ Copied shinylive-sw.js to site root")
    message("   From: ", source_path)
    message("   To:   ", dest_path)

    # Show file sizes
    source_size <- file.size(source_path)
    dest_size <- file.size(dest_path)
    message("   Size: ", format(source_size, big.mark = ","), " bytes")
  } else if (!success && verbose) {
    message("❌ Failed to copy shinylive-sw.js")
  }

  return(success)
}

# TEST: Run the fix
if (interactive() || identical(Sys.getenv("CI"), "")) {
  message("\n=== Testing Service Worker Copy ===\n")
  result <- copy_shinylive_sw_to_root(verbose = TRUE)
  message("\nResult: ", if (result) "SUCCESS ✅" else "FAILED ❌")
}

# INTEGRATION WITH BUILD PROCESS:
# Add this to your pkgdown build script or GitHub Actions workflow:
#
# After pkgdown::build_site():
# source("R/dev/issues/fix_issue_15_sw_path.R")
# copy_shinylive_sw_to_root()
