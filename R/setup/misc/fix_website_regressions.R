# R/setup/fix_website_regressions.R
library(gert)
library(usethis)
library(gh)

# Session log for fixing website regressions and adding dynamic dashboard content
# Date: 2025-12-01

# Step 1: Create branch
# usethis::pr_init("fix-website-regressions")

# Step 2: Modifications
# - vignettes/dashboard.qmd: Restored embedded Shinylive app (Issue #103)
# - _pkgdown.yml: Fixed link to dashboard_async (Issue #102)
# - inst/shiny/dashboard_dynamic/app.R: Created new app for dynamic broadcasting
# - vignettes/dynamic_broadcasting.qmd: Embedded new dynamic dashboard app (Issue #101)

# Step 3: Commit
# gert::git_add(c(
#   "vignettes/dashboard.qmd",
#   "_pkgdown.yml",
#   "inst/shiny/dashboard_dynamic",
#   "vignettes/dynamic_broadcasting.qmd",
#   "R/setup/fix_website_regressions.R"
# ))
# gert::git_commit("Fix: Restore dashboards and fix links (Issues #101, #102, #103)")

# Step 4: Push to Cachix (mandatory)
# system("../push_to_cachix.sh")

# Step 5: Push to GitHub
# usethis::pr_push()

# Step 6: Merge
# usethis::pr_merge_main()
# usethis::pr_finish()
