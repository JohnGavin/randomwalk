# R/setup/remove_r_universe_refs.R
library(gert)

# Check if we are on the correct branch
current_branch <- git_branch()
if (current_branch != "fix-issue-johngavin-r-universe-removal") {
  stop("Not on the correct branch!")
}

# Add files
git_add("vignettes/dashboard.qmd")
git_add("R/setup/remove_r_universe_refs.R")

# Commit
git_commit("Fix: Remove R-Universe references from dashboard vignette")
