# Audit Package Usage for Issue #34
# Purpose: Find all R packages actually used in the project

# Scan all R files for package usage
r_files <- list.files("R", pattern = "\\.R$", full.names = TRUE, recursive = TRUE)
test_files <- list.files("tests", pattern = "\\.R$", full.names = TRUE, recursive = TRUE)
vignette_files <- list.files("vignettes", pattern = "\\.(R|Rmd|qmd)$", full.names = TRUE, recursive = TRUE)
workflow_files <- list.files(".github/workflows", pattern = "\\.ya?ml$", full.names = TRUE, recursive = TRUE)

all_files <- c(r_files, test_files, vignette_files)

# Find library() calls
library_calls <- character()
for (file in all_files) {
  if (file.exists(file)) {
    content <- readLines(file, warn = FALSE)
    libs <- grep("library\\(|require\\(", content, value = TRUE)
    library_calls <- c(library_calls, libs)
  }
}

# Find :: namespace calls
namespace_calls <- character()
for (file in all_files) {
  if (file.exists(file)) {
    content <- readLines(file, warn = FALSE)
    ns <- grep("::", content, value = TRUE)
    namespace_calls <- c(namespace_calls, ns)
  }
}

# Extract package names from library() calls
extract_lib <- function(line) {
  matches <- regmatches(line, gregexpr("(?<=library\\(|require\\()['\"]?\\w+['\"]?(?=\\))", line, perl = TRUE))
  unlist(lapply(matches, function(x) gsub("['\"]", "", x)))
}

lib_packages <- unique(unlist(lapply(library_calls, extract_lib)))

# Extract package names from :: calls
extract_ns <- function(line) {
  matches <- regmatches(line, gregexpr("\\w+(?=::)", line, perl = TRUE))
  unlist(matches)
}

ns_packages <- unique(unlist(lapply(namespace_calls, extract_ns)))

# Combine and sort
all_packages <- sort(unique(c(lib_packages, ns_packages)))

# Also check DESCRIPTION for explicit dependencies
desc_file <- "DESCRIPTION"
if (file.exists(desc_file)) {
  desc <- read.dcf(desc_file)
  imports <- strsplit(desc[1, "Imports"], ",\\s*")[[1]]
  imports <- gsub("\\(.*\\)", "", imports)  # Remove version constraints
  imports <- trimws(imports)

  suggests <- if ("Suggests" %in% colnames(desc)) {
    strsplit(desc[1, "Suggests"], ",\\s*")[[1]]
  } else {
    character()
  }
  suggests <- gsub("\\(.*\\)", "", suggests)
  suggests <- trimws(suggests)
}

cat("\n=== PACKAGE AUDIT RESULTS ===\n\n")

cat("Packages found in code (library/require/::):\n")
cat(paste("-", all_packages), sep = "\n")
cat("\n")

cat("Packages in DESCRIPTION Imports:\n")
cat(paste("-", imports), sep = "\n")
cat("\n")

cat("Packages in DESCRIPTION Suggests:\n")
cat(paste("-", suggests), sep = "\n")
cat("\n")

# Minimal CI/CD package list
ci_packages <- unique(c(
  # Core package dependencies (from DESCRIPTION Imports)
  imports,
  # Testing
  "testthat", "covr",
  # Documentation
  "roxygen2", "pkgdown", "knitr", "rmarkdown",
  # CI tools
  "devtools", "rcmdcheck",
  # Shinylive export
  "shinylive"
))

ci_packages <- sort(ci_packages)

cat("\n=== MINIMAL CI/CD PACKAGE LIST ===\n")
cat("(", length(ci_packages), " packages)\n\n", sep = "")
cat(paste("-", ci_packages), sep = "\n")
cat("\n")

# Save for next step
saveRDS(ci_packages, "R/setup/ci_packages.rds")
cat("\n✅ Package list saved to R/setup/ci_packages.rds\n")
