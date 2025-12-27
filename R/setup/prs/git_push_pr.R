# Push to remote and create/update PR for Issue #16
# Created: 2025-11-10
# Purpose: Push changes and manage PR per context.md workflow

library(usethis)
library(gert)
library(gh)

cat("=== Pushing to Remote and Managing PR ===\n")
cat("Date:", as.character(Sys.time()), "\n")
cat("Branch:", gert::git_branch(), "\n\n")

# 1. Push to remote
cat("1. Pushing to remote...\n")
tryCatch({
  usethis::pr_push()
  cat("✓ Pushed to remote\n\n")
}, error = function(e) {
  cat("Error pushing:", conditionMessage(e), "\n")
  cat("Trying gert::git_push()...\n")
  gert::git_push()
  cat("✓ Pushed to remote\n\n")
})

# 2. Check if PR exists
cat("2. Checking for existing PR...\n")
prs <- gh::gh("/repos/{owner}/{repo}/pulls",
              owner = "JohnGavin",
              repo = "randomwalk",
              head = "JohnGavin:feature/fix-missing-visualizations-16",
              state = "open")

if(length(prs) > 0) {
  cat("✓ PR already exists: #", prs[[1]]$number, "\n")
  cat("  Title:", prs[[1]]$title, "\n")
  cat("  URL:", prs[[1]]$html_url, "\n\n")
  cat("The push will update the existing PR automatically.\n\n")
} else {
  cat("No existing PR found. You may need to create one manually or use usethis::pr_init()\n\n")
}

cat("=== Push Complete ===\n")
cat("Next steps:\n")
cat("1. Monitor GitHub Actions at: https://github.com/JohnGavin/randomwalk/actions\n")
cat("2. Wait for all workflows to pass\n")
cat("3. Merge PR when ready\n")
cat("4. Use usethis::pr_merge_main() and usethis::pr_finish() to complete\n")
