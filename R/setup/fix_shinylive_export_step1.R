# Fix: Re-enable Shinylive Dashboard Export
# Date: 2025-11-23
# Related to Issue #33
#
# This script logs all commands used to re-enable Shinylive export
# in the pkgdown workflow so the dashboard shows updated parameters

library(gh)
library(gert)
library(usethis)

# ============================================================================
# STEP 1: CREATE GITHUB ISSUE
# ============================================================================

issue_title <- "Re-enable Shinylive export in pkgdown workflow to deploy updated dashboard"

issue_body <- "## Problem

Issue #33 was closed and PR #36 merged with updated dashboard parameters:
- Workers: 0-12 (was 0-4)
- Grid Size: 20-400 (was 5-50)
- Walkers: Dynamic max at 70% of grid pixels

However, the live dashboard at https://johngavin.github.io/randomwalk/articles/dashboard_async/ still shows the OLD parameters.

## Root Cause

The Shinylive export steps were disabled in PR #34 (commit 50e45f0) in `.github/workflows/pkgdown.yaml` lines 78-113 due to a package installation issue:

```yaml
# Temporarily skip shinylive export - requires randomwalk package to be installed
# TODO: Re-enable after resolving package installation in nix environment
```

The `shinylive::export()` function needs the `randomwalk` package to be **installed**, but in the Nix CI environment it's only available in the shell environment, not installed.

**Result**: Even though `inst/shiny/dashboard_async/app.R` has the correct code, it's never exported to the live site.

## Solution

1. Add a step to install the randomwalk package in the pkgdown workflow before export
2. Re-enable the commented-out Shinylive export steps
3. Deploy the updated dashboard

## Implementation

```yaml
# Add before shinylive export:
- name: Install randomwalk package
  run: |
    nix-shell default-ci.nix --run \"R CMD INSTALL .\"

# Then uncomment and enable:
- name: Export async dashboard with R shinylive
  run: |
    nix-shell default-ci.nix --run \"Rscript -e '
      if (dir.exists(\\\"docs/articles/dashboard_async\\\")) {
        unlink(\\\"docs/articles/dashboard_async\\\", recursive = TRUE)
      }
      shinylive::export(
        appdir = \\\"inst/shiny/dashboard_async\\\",
        destdir = \\\"docs/articles/dashboard_async\\\"
      )
    '\"
```

## Verification

After deployment, verify at https://johngavin.github.io/randomwalk/articles/dashboard_async/:
- ✅ Workers slider: min=0, max=12, default=2
- ✅ Grid Size slider: min=20, max=400, step=20, default=100
- ✅ Walkers: Dynamic constraint message visible

## References

- Issue #33: Improve async dashboard UI and parameter ranges
- PR #36: Fix: Improve dashboard filters with built-in Shiny dropdowns
- PR #34: Optimize Nix environment for CI/CD workflows
- Commit 50e45f0: Skip shinylive export temporarily
- Commit 43b2371: Updated app.R with new parameters
"

# Create the issue
cat("Creating GitHub issue...\n")
issue_response <- gh(
  "POST /repos/JohnGavin/randomwalk/issues",
  title = issue_title,
  body = issue_body,
  labels = list("bug", "deployment", "enhancement")
)

cat("✅ Issue created: #", issue_response$number, "\n", sep = "")
cat("   URL:", issue_response$html_url, "\n")

issue_number <- issue_response$number

# Save issue number for later use
saveRDS(issue_number, "issue_number.rds")

# ============================================================================
# NEXT STEPS (to be executed after issue creation)
# ============================================================================

cat("\nNext: Create development branch with:\n")
cat("  usethis::pr_init('fix-issue-", issue_number, "-enable-shinylive-export')\n", sep = "")
