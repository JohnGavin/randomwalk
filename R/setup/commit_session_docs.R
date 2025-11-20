# Commit Session Documentation Before Restart
# Date: 2025-11-20

library(gert)

cat("Committing all session documentation...\n\n")

# Stage all new documentation files
files_to_add <- c(
  "R/setup/SESSION_2025-11-20_ISSUE_34_PROGRESS.md",
  "R/setup/update_issue_34.R",
  "R/setup/issue_34_comment.txt",
  "R/setup/commit_session_docs.R",
  "R/setup/test_full_caching.R",
  "R/setup/analyze_workflows.R",
  "R/setup/test_cachix_caching.R",
  "R/setup/trigger_caching_test.R",
  "R/setup/ci_packages.rds"
)

cat("Staging files:\n")
for (file in files_to_add) {
  if (file.exists(file)) {
    gert::git_add(file)
    cat("  ✓", file, "\n")
  } else {
    cat("  ✗", file, "(not found)\n")
  }
}

cat("\n")

# Commit
commit_msg <- "Document Issue #34 progress before session restart

Session 2025-11-20 progress documented for easy resume:
- Created SESSION_2025-11-20_ISSUE_34_PROGRESS.md
- Full session timeline and next steps
- Cachix setup complete, Run #96 successful (62% speedup)
- Ready for Run #97 to test full caching (~2-3 min expected)

All scripts and documentation logged in R/setup/ for reproducibility.

Related to #34, PR #35"

gert::git_commit(commit_msg)

cat("✅ Committed session documentation\n\n")

# Show commit
log <- gert::git_log(max = 1)
cat("Commit:", log$commit[1], "\n")
cat("Branch:", gert::git_branch(), "\n\n")

# Push
cat("Pushing to GitHub...\n")
gert::git_push()

cat("\n✅ All documentation pushed to GitHub!\n\n")

cat("=== SESSION SAVED ===\n\n")

cat("To resume after restart:\n\n")

cat("1. Start fresh nix shell:\n")
cat("   cd /Users/johngavin/docs_gh/claude_rix/random_walk\n")
cat("   nix-shell\n\n")

cat("2. Read session summary:\n")
cat("   cat R/setup/SESSION_2025-11-20_ISSUE_34_PROGRESS.md\n\n")

cat("3. Pull latest changes:\n")
cat("   git pull\n\n")

cat("4. Continue with Run #97 test (see session summary for options)\n\n")

cat("Key files:\n")
cat("- SESSION_2025-11-20_ISSUE_34_PROGRESS.md - Full status\n")
cat("- setup_custom_cachix.md - Cachix setup guide\n")
cat("- issue_34_comment.txt - GitHub comment ready to post\n\n")

cat("Current status: 62% speedup achieved, testing 85%+ next\n")
