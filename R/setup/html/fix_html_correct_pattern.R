# Fix HTML vignette files with CORRECT pattern
# Replace GitHub releases URL with simple library() calls

fix_dashboard_async <- function() {
  file <- "docs/articles/dashboard_async.html"
  content <- readLines(file, warn = FALSE)

  # Find and replace the problematic webr::mount section
  # Replace from "webr::mount" to "library(randomwalk)" with correct pattern

  old_pattern <- 'source = "https://github.com/JohnGavin/randomwalk/releases/latest/download/library.data"'

  # Simple find/replace approach
  for (i in seq_along(content)) {
    if (grepl(old_pattern, content[i], fixed = TRUE)) {
      # Found the line - now need to replace the entire webr::mount block
      # We'll mark this line and search backwards/forwards for the block
      cat("Found GitHub releases URL at line", i, "\n")

      # Find the start of the block (webr::mount)
      start_line <- i
      while (start_line > 1 && !grepl("webr::mount", content[start_line])) {
        start_line <- start_line - 1
      }

      # Find the end of the block (library(randomwalk))
      end_line <- i
      while (end_line < length(content) && !grepl("library\\(randomwalk\\)", content[end_line])) {
        end_line <- end_line + 1
      }

      cat("Block spans lines", start_line, "to", end_line, "\n")

      # Replace the entire block with simple library() calls
      new_code <- c(
        "# Load required packages",
        "# Shinylive will automatically detect and bundle these packages",
        "library(shiny)",
        "library(randomwalk)"
      )

      # Remove old lines and insert new ones
      content <- c(
        content[1:(start_line-1)],
        new_code,
        content[(end_line+1):length(content)]
      )

      break  # Only fix first occurrence
    }
  }

  writeLines(content, file)
  cat("Fixed:", file, "\n\n")

  # Verify
  new_content <- readLines(file, warn = FALSE)
  has_correct <- any(grepl("Shinylive will automatically detect", new_content, fixed = TRUE))
  has_wrong <- any(grepl("github.com.*releases.*library.data", new_content))
  cat("  - Correct pattern present:", has_correct, "\n")
  cat("  - GitHub releases URL present:", has_wrong, "\n")
}

fix_dynamic_broadcasting <- function() {
  file <- "docs/articles/dynamic_broadcasting.html"
  content <- readLines(file, warn = FALSE)

  old_pattern <- 'source = "https://github.com/JohnGavin/randomwalk/releases/latest/download/library.data"'

  for (i in seq_along(content)) {
    if (grepl(old_pattern, content[i], fixed = TRUE)) {
      cat("Found GitHub releases URL at line", i, "\n")

      start_line <- i
      while (start_line > 1 && !grepl("webr::mount", content[start_line])) {
        start_line <- start_line - 1
      }

      end_line <- i
      while (end_line < length(content) && !grepl("library\\(randomwalk\\)", content[end_line])) {
        end_line <- end_line + 1
      }

      cat("Block spans lines", start_line, "to", end_line, "\n")

      new_code <- c(
        "# Load required packages",
        "# Shinylive will automatically detect and bundle these packages",
        "library(shiny)",
        "library(randomwalk)"
      )

      content <- c(
        content[1:(start_line-1)],
        new_code,
        content[(end_line+1):length(content)]
      )

      break
    }
  }

  writeLines(content, file)
  cat("Fixed:", file, "\n\n")

  new_content <- readLines(file, warn = FALSE)
  has_correct <- any(grepl("Shinylive will automatically detect", new_content, fixed = TRUE))
  has_wrong <- any(grepl("github.com.*releases.*library.data", new_content))
  cat("  - Correct pattern present:", has_correct, "\n")
  cat("  - GitHub releases URL present:", has_wrong, "\n")
}

cat("Fixing HTML files with correct pattern...\n\n")
fix_dashboard_async()
cat("\n")
fix_dynamic_broadcasting()
cat("\nDone!\n")
