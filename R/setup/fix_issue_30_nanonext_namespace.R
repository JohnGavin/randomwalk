# Fix Issue #30: Add nanonext namespace prefixes in worker code
# Date: 2025-11-19
# Issue: https://github.com/JohnGavin/randomwalk/issues/30
#
# Problem: Worker code failed with "object is not a valid Socket or Context"
# because nanonext functions were called without namespace prefix
#
# Solution: Add nanonext:: prefix to all nanonext function calls in R/async_worker.R

library(gert)
library(usethis)
library(devtools)

# 1. Created GitHub issue #30
# gh('POST /repos/JohnGavin/randomwalk/issues',
#    title = 'Fix missing nanonext namespace prefixes in worker code', ...)

# 2. Switched to async-v2-phase1 (where async code exists)
# gert::git_branch_checkout('async-v2-phase1')

# 3. Created development branch from async-v2-phase1
# gert::git_branch_create('fix-issue-30-nanonext-namespace', checkout = TRUE)

# 4. Applied 4 fixes to R/async_worker.R:
#    Line 41:  nano()      -> nanonext::nano()
#    Line 44:  subscribe() -> nanonext::subscribe()
#    Line 96:  recv()      -> nanonext::recv()
#    Line 344: close()     -> nanonext::close()

# 5. Run checks
devtools::document()
devtools::test()
devtools::check()

# 6. Stage and commit
gert::git_add("R/async_worker.R")
gert::git_add("R/setup/fix_issue_30_nanonext_namespace.R")
gert::git_commit("Fix: Add nanonext namespace prefixes in worker code (#30)

- Add nanonext:: prefix to nano(), subscribe(), recv(), close()
- Fixes 'object is not a valid Socket or Context' error
- Workers can now properly create and use subscriber sockets
- Matches publisher code pattern in async_controller.R

Closes #30")

# 7. Push to remote (will trigger GitHub Actions)
# gert::git_push()

# 8. After checks pass, merge via PR
# usethis::pr_merge_main()
# usethis::pr_finish()
