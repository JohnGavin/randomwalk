# Git commit for Issue #16 fix
# Created: 2025-11-10
# Purpose: Stage and commit changes per context.md workflow
# Using gert package as per context.md

library(gert)
library(usethis)

cat("=== Committing Issue #16 Fix ===\n")
cat("Date:", as.character(Sys.time()), "\n")
cat("Branch:", gert::git_branch(), "\n\n")

# 1. Check status
cat("1. Current git status:\n")
status <- gert::git_status()
print(status[, c("file", "status")])
cat("\n")

# 2. Stage all relevant changes
cat("2. Staging changes...\n")
files_to_add <- c(
  "DESCRIPTION",
  "R/plotting.R",
  "_targets.R",
  "vignettes/telemetry.qmd",
  "default.R",
  "default.nix",
  "R/setup/check_gh_issues.R",
  "R/setup/regenerate_default_nix.R",
  "R/setup/simple_checks.R",
  "R/setup/verify_fix.R",
  "R/setup/git_commit_issue_16.R"
)

for(f in files_to_add) {
  if(file.exists(f)) {
    gert::git_add(f)
    cat("  Added:", f, "\n")
  }
}
cat("\n")

# 3. Commit
cat("3. Creating commit...\n")
commit_msg <- "Fix Issue #16: Regenerate default.nix with ggplot2

- Converted plot_grid() from base R to ggplot2 (R/plotting.R)
- Updated DESCRIPTION: moved ggplot2 from Suggests to Imports
- Regenerated default.nix from default.R with ggplot2 included
- Fixed telemetry vignette rendering (vignettes/telemetry.qmd)
- Updated _targets.R to work with ggplot2 objects
- Added verification and logging scripts in R/setup/

All changes follow context.md guidelines for:
- Tidyverse preference over base R
- Reproducibility via rix/nix
- Logging all commands for audit trail

\U0001f916 Generated with Claude Code

Co-Authored-By: Claude <noreply@anthropic.com>"

gert::git_commit(commit_msg)
cat("✓ Commit created\n\n")

# 4. Show commit
cat("4. Latest commit:\n")
log <- gert::git_log(max = 1)
cat("  SHA:", substr(log$commit, 1, 7), "\n")
cat("  Author:", log$author, "\n")
cat("  Message:", strsplit(log$message, "\n")[[1]][1], "\n\n")

cat("=== Commit Complete ===\n")
cat("Next: Push to remote with usethis::pr_push()\n")
