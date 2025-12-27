# R/setup/fix_issue_r_universe_removal_v2.R
library(gert)
library(usethis)
library(gh)

# Session log for removing R-Universe and posit-dev references
# Date: 2025-12-01

# Step 1: Create branch
# usethis::pr_init("fix-issue-johngavin-r-universe-removal-v2")

# Step 2: Modified vignettes/dashboard.qmd
# Removed references to johngavin.r-universe.dev
# Removed reference to posit-dev.github.io
# Updated WebR mount source to point to GitHub Releases

# Step 3: Commit
# gert::git_add(c("vignettes/dashboard.qmd", "R/setup/fix_issue_r_universe_removal_v2.R"))
# gert::git_commit("Fix: Remove R-Universe and posit-dev references from dashboard vignette")

# Step 4: Push to Cachix (mandatory)
# system("../push_to_cachix.sh")

# Step 5: Push to GitHub
# usethis::pr_push()

# Step 6: Merge
# usethis::pr_merge_main()
# usethis::pr_finish()
