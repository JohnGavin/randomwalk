# Reorganize R/setup files into logical subfolders
# Issue #84

library(fs)
library(dplyr)
library(purrr)

# Define organization structure
folders <- list(
  issues = "^fix_issue_",
  prs = "^(create_pr|monitor_pr|wait_pr|check_pr|push_and|git_push)",
  commits = "^commit_",
  github = "^(create_issue|update_issue|check_gh)",
  tests = "^test_",
  ci = "^(.*workflow.*|create_ci|trigger_|enable_custom)",
  nix = "^(.*nix.*|generate_nix)",
  vignettes = ".*vignette.*",
  sessions = "^session_",
  debug = "^debug_",
  plans = "^(PLAN_|plan_)",
  dashboard = "^fix_dashboard",
  analysis = "^(analyze_|audit_)",
  cleanup = "^(clean.*|apply_fixes)",
  dev = "^(dev_log|simple_checks|run_dev|verify|phase)",
  html = "^fix_html",
  shinylive = "^fix_shinylive",
  wasm = "^(wasm_|implement_rwasm)"
)

# Get all files in R/setup
setup_dir <- "R/setup"
all_files <- dir_ls(setup_dir, type = "file")

# Create target directories
target_dirs <- file.path(setup_dir, names(folders))
walk(target_dirs, dir_create)

# Categorize each file
categorize_file <- function(filename) {
  basename_file <- basename(filename)

  for (category in names(folders)) {
    pattern <- folders[[category]]
    if (grepl(pattern, basename_file, ignore.case = TRUE)) {
      return(category)
    }
  }

  # Uncategorized files go to misc
  return("misc")
}

# Create misc folder
dir_create(file.path(setup_dir, "misc"))

# Move files
file_moves <- tibble(
  source = all_files,
  basename = basename(all_files),
  category = map_chr(all_files, categorize_file),
  target = file.path(setup_dir, category, basename)
)

# Print summary
cat("\n=== File Organization Summary ===\n\n")
file_moves %>%
  count(category, sort = TRUE) %>%
  print()

cat("\n=== Moving files ===\n\n")

# Move files
for (i in seq_len(nrow(file_moves))) {
  src <- file_moves$source[i]
  dst <- file_moves$target[i]
  cat(sprintf("%s -> %s\n", basename(src), file_moves$category[i]))
  file_move(src, dst)
}

cat("\n=== Organization complete! ===\n")
cat(sprintf("Total files organized: %d\n", nrow(file_moves)))
cat(sprintf("Total categories: %d\n", n_distinct(file_moves$category)))
