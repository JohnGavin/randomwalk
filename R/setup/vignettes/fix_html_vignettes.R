# Fix HTML vignette files directly
# Replaces old webr::mount() pattern with simple library() calls

files <- c(
  "docs/articles/dashboard.html",
  "docs/articles/dashboard_async.html",
  "docs/articles/dynamic_broadcasting.html"
)

for (file in files) {
  if (!file.exists(file)) {
    cat("File not found:", file, "\n")
    next
  }

  content <- readLines(file, warn = FALSE)

  # Pattern to find and replace:
  # From: source = "../wasm/library.data"
  # To: source = "https://github.com/JohnGavin/randomwalk/releases/latest/download/library.data"

  content <- gsub(
    'source = "../wasm/library.data"',
    'source = "https://github.com/JohnGavin/randomwalk/releases/latest/download/library.data"',
    content,
    fixed = TRUE
  )

  # Also fix library.js.metadata path
  content <- gsub(
    '../wasm/library.js.metadata',
    'https://github.com/JohnGavin/randomwalk/releases/latest/download/library.js.metadata',
    content,
    fixed = TRUE
  )

  writeLines(content, file)

  # Verify fix applied
  new_content <- readLines(file, warn = FALSE)
  has_github_url <- any(grepl("github.com/.*releases.*library.data", new_content))
  has_old_path <- any(grepl('../wasm/library', new_content, fixed = TRUE))

  cat("Fixed:", file, "\n")
  cat("  - GitHub releases URL present:", has_github_url, "\n")
  cat("  - Old ../wasm path remaining:", has_old_path, "\n")
  cat("\n")
}

cat("\nAll HTML files have been updated.\n")
