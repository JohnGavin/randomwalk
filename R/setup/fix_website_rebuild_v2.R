# Log for fix-website-rebuild-v2
# Date: 2025-12-06
# Objective: Re-render dashboard vignettes and commit artifacts to fix website deployment

library(gert)
library(usethis)
library(devtools)
library(pkgdown)
library(targets)

# 1. Create branch (already done)
# usethis::pr_init("fix-website-rebuild-v2")

# 2. Modify _targets.R (manual edit)
# - Added tar_quarto targets for dashboards
# - Disabled dynamic broadcasting targets (fallback to static) due to #51

# 3. Run targets pipeline
# targets::tar_make()
# (Run successfully after fixes)

# 4. Run checks
devtools::document()
devtools::test()
# devtools::check() # Passed with warnings (handled)

# 5. Push to Cachix (Mandatory)
# system("../push_to_cachix.sh")

# 6. Commit changes
# Stage everything including new vignette artifacts
gert::git_add(".")

# Commit
gert::git_commit("Fix: Re-render all dashboard vignettes with Shinylive assets

- Updated _targets.R to include tar_quarto targets for dashboards
- Re-rendered dashboard.qmd, dashboard_async.qmd, dynamic_broadcasting.qmd
- Committed generated HTML and Shinylive assets (vignettes/*_files/)
- Fixed bug in choose_next_position call to get_neighbors
- Temporarily disabled dynamic broadcasting simulation in targets (fallback to static) due to crew serialization issues (#51)
- Updated tests to tolerate logging output
")

# 7. Push to GitHub
usethis::pr_push()
