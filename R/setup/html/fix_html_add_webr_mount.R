# Fix HTML to add webr::mount() code for package loading
# Issue #127: Shinylive needs explicit package installation

library(stringr)

fix_html_with_webr_mount <- function(file_path) {
  cat("Fixing:", file_path, "\n")

  content <- readLines(file_path, warn = FALSE)

  # Find the simple library() pattern
  pattern <- "# Shinylive will automatically detect and bundle these packages"

  for (i in seq_along(content)) {
    if (grepl(pattern, content[i], fixed = TRUE)) {
      cat("  Found at line", i, "\n")

      # Replace the comment and library calls with webr::mount() + library calls
      new_code <- c(
        "# Mount WebAssembly filesystem from GitHub release",
        "# The wasm-release.yaml workflow builds library.data",
        "webr::mount(",
        "  mountpoint = \"/randomwalk-lib\",",
        "  source = \"https://github.com/JohnGavin/randomwalk/releases/latest/download/library.data\"",
        ")",
        "",
        "# Add mounted library to library paths",
        ".libPaths(c(\"/randomwalk-lib\", .libPaths()))",
        "",
        "# Load required packages",
        "library(shiny)",
        "library(randomwalk)"
      )

      # Find next two lines (should be library(shiny) and library(randomwalk))
      # We'll replace from the comment line through library(randomwalk)

      # Replace: comment + library(shiny) + library(randomwalk)
      # With: webr::mount() code + .libPaths() + library(shiny)

      # Just replace these 3 lines
      content <- c(
        content[1:(i-1)],
        new_code,
        content[(i+3):length(content)]
      )

      break
    }
  }

  writeLines(content, file_path)
  cat("  ✅ Fixed\n\n")
}

# Fix all three vignette HTML files
fix_html_with_webr_mount("docs/articles/dynamic_broadcasting.html")
fix_html_with_webr_mount("docs/articles/dashboard_async.html")
fix_html_with_webr_mount("docs/articles/dashboard.html")

cat("Done! All HTML files updated with webr::mount() code.\n")
