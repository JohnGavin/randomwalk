# R/setup/fix_issue_67_critical.R
library(gert)
library(usethis)
library(gh)

# Session log for fixing broken vignette links (Issue #67)
# Date: 2025-12-01

# Step 1: Create branch
# usethis::pr_init("fix-issue-67-copy-vignette-assets")

# Step 2: Modified .github/workflows/pkgdown.yaml
# Added explicit file copying for vignettes/*.html and vignettes/*_files
# to docs/articles/ after pkgdown::build_articles_index()

# Step 3: Commit
# gert::git_add(".github/workflows/pkgdown.yaml")
# gert::git_commit("Fix #67: Explicitly copy pre-built vignettes and assets to docs/articles/")

# Step 4: Push to Cachix (mandatory)
# system("../push_to_cachix.sh")

# Step 5: Push to GitHub
# usethis::pr_push()

# Step 6: Merge
# usethis::pr_merge_main()
# usethis::pr_finish()
