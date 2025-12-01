# Git Hooks for randomwalk Development

This directory contains git hooks that automate repetitive development tasks and ensure consistency.

## Available Hooks

### `pre-commit`

**Purpose:** Automatically regenerate nix files when `DESCRIPTION` changes

**Behavior:**
1. Detects if `DESCRIPTION` file is being committed
2. Runs `R/setup/generate_nix_files.R` to regenerate:
   - `package.nix` (package derivation)
   - `default-ci.nix` (CI/dev environment)
   - `default.nix` (symlink to default-ci.nix)
3. Stages the updated nix files for commit
4. **Aborts commit if regeneration fails**

**Why This Matters:**
- Prevents out-of-sync nix files (common source of CI/CD failures)
- Eliminates manual regeneration step
- Ensures reproducibility between local and CI environments
- Catches nix syntax errors before pushing to GitHub

## Installation

### Quick Install

From the project root:

```bash
bash hooks/install_hooks.sh
```

### Manual Install

```bash
# Copy hook to .git/hooks/
cp hooks/pre-commit .git/hooks/pre-commit

# Make it executable
chmod +x .git/hooks/pre-commit
```

## Testing the Hook

1. Make a change to `DESCRIPTION` (e.g., add a comment)
2. Stage and commit:
   ```bash
   git add DESCRIPTION
   git commit -m "Test pre-commit hook"
   ```
3. You should see:
   ```
   🔍 DESCRIPTION changed - regenerating nix files...
   ✅ Nix files regenerated successfully
   ✅ Updated nix files staged for commit
   ```

## Troubleshooting

### Hook doesn't run

**Check if installed:**
```bash
ls -la .git/hooks/pre-commit
```

**Reinstall:**
```bash
bash hooks/install_hooks.sh
```

### Hook fails on commit

**View error log:**
```bash
cat /tmp/nix_gen.log
```

**Common causes:**
- Invalid R syntax in DESCRIPTION
- Missing R packages (desc, rix, glue, logger)
- Nix syntax errors in generated files

**Fix:**
1. Fix the error shown in log
2. Try commit again
3. Hook will re-run automatically

### Bypass hook (NOT RECOMMENDED)

**Only use in emergencies:**
```bash
git commit --no-verify -m "Emergency commit"
```

**⚠️ Warning:** Skipping the hook can cause nix files to become out of sync!

## For New Contributors

After cloning the repository:

1. Install hooks:
   ```bash
   bash hooks/install_hooks.sh
   ```

2. Test installation:
   ```bash
   echo "# Test" >> DESCRIPTION
   git add DESCRIPTION
   git commit -m "Test"
   git reset HEAD~1  # Undo test commit
   git restore DESCRIPTION
   ```

## Removing Hooks

```bash
rm .git/hooks/pre-commit
```

## Related Documentation

- **[R/setup/generate_nix_files.R](../R/setup/generate_nix_files.R)** - Nix generation script
- **[Troubleshooting Nix Environment](https://github.com/JohnGavin/randomwalk/wiki/Troubleshooting-Nix-Environment)** - Wiki guide
- **[inst/docs/DEPLOYMENT_GUIDE.md](../inst/docs/DEPLOYMENT_GUIDE.md)** - Full deployment workflow

## Implementation Details

- **Hook type:** Bash script
- **Runs:** Before commit (pre-commit phase)
- **Requires:** R, Rscript in PATH (provided by nix-shell)
- **Logs to:** `/tmp/nix_gen.log`
- **Exit codes:**
  - `0`: Success (commit proceeds)
  - `1`: Failure (commit aborted)

---

**Created:** December 2024
**Issue:** #78
**PR:** TBD
