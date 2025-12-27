# R/setup/fix_issue_116.R
# Fix duplicate telemetry.qmd (Issue #116)

# 1. Initialize branch
usethis::pr_init("fix-duplicate-telemetry-116")

# 2. Remove stale file
# Note: Using fs::file_delete or standard file.remove
if (file.exists("inst/qmd/telemetry.qmd")) {
  file.remove("inst/qmd/telemetry.qmd")
  gert::git_add("inst/qmd/telemetry.qmd")
}

# 3. Fix title in vignettes/telemetry.qmd
# (This step is done manually via editor/tool, but logging the intent here)
# "hello Telemetry and Pipeline Statistics" -> "Telemetry and Pipeline Statistics"
gert::git_add("vignettes/telemetry.qmd")

# 4. Commit changes
gert::git_commit("Fix #116: Remove stale telemetry.qmd and fix title in vignettes")

# 5. Push to Cachix (Manual step in shell)
# nix-build default-ci.nix
# ../push_to_cachix.sh

# 6. Push PR
# usethis::pr_push()
