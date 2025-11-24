# How to Trigger Run #97 - Alternative Methods

## Problem
The "Run workflow" button only appears if the workflow has `workflow_dispatch:` trigger in the YAML file. Our workflows don't have this, so the button isn't visible.

## Solution: Push a Small Change

Since we can't manually trigger, we need to push a commit to trigger the workflows automatically.

### Method 1: Use R (Simplest)

```r
# From R (in or out of nix shell)
writeLines("Run #97 test", "R/setup/.cachix_test_97")
library(gert)
gert::git_add("R/setup/.cachix_test_97")
gert::git_commit("Test full Cachix caching (Run #97)

Run #96 results:
- nix-builder: 6m 33s (was ~17 min)
- R-tests-via-nix: 7m 18s (was ~17 min)
- 62% speedup achieved!

Testing full cache pull. Expected: ~2-3 min")
gert::git_push()
```

### Method 2: Command Line (If git available)

```bash
echo "Run 97 test" > R/setup/.cachix_test_97
git add R/setup/.cachix_test_97
git commit -m "Test full Cachix caching (Run #97)"
git push
```

### Method 3: Add workflow_dispatch (For Future)

If you want the manual trigger button for future use, we can add this to the workflows:

**File: `.github/workflows/nix-builder.yaml`**

Change:
```yaml
on:
  push:
    branches: [main, master]
  pull_request:
    branches: [main, master]
```

To:
```yaml
on:
  push:
    branches: [main, master]
  pull_request:
    branches: [main, master]
  workflow_dispatch:  # ADD THIS LINE
```

Then the "Run workflow" button will appear at:
https://github.com/JohnGavin/randomwalk/actions/workflows/nix-builder.yaml

## Recommended: Use Method 1 (R)

It's the most reliable and doesn't depend on git being in PATH.

Just run this:
```r
writeLines("Run #97 test", "R/setup/.cachix_test_97")
library(gert)
gert::git_add("R/setup/.cachix_test_97")
gert::git_commit("Test full Cachix caching (Run #97)")
gert::git_push()
```

Then monitor: https://github.com/JohnGavin/randomwalk/actions

Expected:
- Run #97 starts within ~30 seconds
- Duration: ~2-3 minutes (if cache is working)
- Logs show: "copying path ... from randomwalk.cachix.org"
