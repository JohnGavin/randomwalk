# R/setup/create_ci_issues.R
# Purpose: Raise issues for CI/CD caching improvements
# Date: 2025-11-29

# Issue 3: Enable Persistent Caching for Targets in CI
gh::gh(
  "POST /repos/JohnGavin/randomwalk/issues",
  title = "Enable persistent caching for targets in CI/CD",
  body = "## Context
Currently, `targets::tar_make()` is omitted from the Nix build pipeline to keep builds fast, meaning vignettes or outputs might not reflect the latest code changes in the CI artifact.

## Proposed Change
Integrate `targets::tar_make()` into the CI pipeline but utilize persistent caching (e.g., `actions/cache` or a remote bucket) so that only modified targets are rebuilt.

## Pros
- **Correctness:** Guarantees that documentation and vignettes are always in sync with the code.
- **Efficiency:** Avoids re-running expensive simulations if the relevant code hasn't changed.

## Cons
- **Complexity:** Requires configuring cache keys and restoring state within the Nix or GitHub Actions environment.
- **Hermeticity:** We need to ensure the cache restoration doesn't violate Nix purity rules (or run it as a post-build step).
"
)
