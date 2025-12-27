# Commit Dashboard Links Fix
# Date: 2024-11-18
# Issue: #26
# Branch: fix-issue-26-dashboard-links

library(gert)

# Check what files were changed
cat("=== Files changed ===\n")
status <- gert::git_status()
print(status)

# Stage the changed file
cat("\n=== Staging _pkgdown.yml ===\n")
gert::git_add("_pkgdown.yml")

# Commit with descriptive message
commit_msg <- "Fix: Dashboard links pointing to directory not .html file (#26)

Changed dashboard links in _pkgdown.yml from articles/dashboard.html
to articles/dashboard/ to match the actual deployed structure.

The pkgdown workflow exports Shinylive to a directory, not a single HTML file,
so links must use the directory path with trailing slash."

cat("\n=== Committing changes ===\n")
commit_info <- gert::git_commit(commit_msg)
print(commit_info)

cat("\n✓ Changes committed successfully!\n")
cat("\n=== Next Steps ===\n")
cat("1. Run checks: devtools::document(), test(), check()\n")
cat("2. Build site: pkgdown::build_site()\n")
cat("3. Push: usethis::pr_push()\n")
