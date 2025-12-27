# Add Timeout Logic and Close PR #31
# Date: 2025-11-19
# Issue: GitHub Actions taking too long / hanging on async tests
# PR #31: https://github.com/JohnGavin/randomwalk/pull/31 (CLOSED - wrong solution)
# New Issue: #32 - https://github.com/JohnGavin/randomwalk/issues/32

# PROBLEM DISCOVERY
# =================
# User reported GitHub Actions workflow hanging with errors:
# - ERROR: Invalid walker structure returned from crew worker
# - ERROR: Result status: error, error: `object` is not a valid Socket or Context
# - Tests taking >15 minutes without completing

# INITIAL (WRONG) SOLUTION - PR #31
# ==================================
# Added nanonext:: namespace prefixes to worker functions
# - Lines changed in R/async_worker.R: 41, 44, 96, 344
# - Changed nano() → nanonext::nano()
# - Changed subscribe() → nanonext::subscribe()
# - Changed recv() → nanonext::recv()
# - Changed close() → nanonext::close()

# Created PR #31 but this didn't fix the root cause!

# ROOT CAUSE DISCOVERY
# ====================
# After reviewing R/setup/NANONEXT_SOCKET_FINDINGS.md, found that:
# 1. nanonext sockets are environment objects with C-level pointers
# 2. They CANNOT be serialized across crew worker processes
# 3. Namespace prefixes don't help - the fundamental architecture is broken
# 4. Recommended solution: Use DuckDB for state sync instead of nanonext pub/sub

# CORRECT SOLUTION
# ================

# 1. Close PR #31
library(gh)
gh::gh(
  "PATCH /repos/JohnGavin/randomwalk/pulls/31",
  state = "closed"
)
# Closed with explanation that namespace prefixes aren't the root cause

# 2. Add timeout logic to prevent infinite hangs
# Modified R/simulation.R lines 270-291:
# - Added timeout_secs = 30 * n_total (30 seconds per walker)
# - Added elapsed time check in polling loop
# - Throw error if timeout exceeded with clear message
#
# This prevents tests from hanging forever while we implement the real fix

# 3. Create new issue #32 for DuckDB solution
gh::gh(
  "POST /repos/JohnGavin/randomwalk/issues",
  title = "Replace nanonext pub/sub with DuckDB for async state synchronization",
  body = "... (see issue for full description) ..."
)
# Created: https://github.com/JohnGavin/randomwalk/issues/32

# CHANGES MADE
# ============
# Files modified:
# - R/simulation.R (added timeout logic at lines 277-288)
# - R/setup/add_timeout_and_close_pr31.R (this file)

# NEXT STEPS
# ==========
# 1. Implement DuckDB solution (issue #32)
# 2. Remove nanonext socket code from workers
# 3. Update async_controller.R to use DuckDB
# 4. Update tests
# 5. Benchmark polling overhead

# LESSONS LEARNED
# ===============
# - Always check existing investigation docs (NANONEXT_SOCKET_FINDINGS.md)
#   before proposing solutions
# - Namespace prefixes don't fix serialization issues
# - Test timeouts are essential for async/parallel code
# - DuckDB is a better fit for inter-process state sync than nanonext sockets

# STATUS
# ======
# - ✅ PR #31 closed
# - ✅ Timeout logic added
# - ✅ Issue #32 created
# - ⏳ Async tests will fail fast (instead of hanging)
# - 🔴 Async simulation still broken (needs DuckDB implementation)
