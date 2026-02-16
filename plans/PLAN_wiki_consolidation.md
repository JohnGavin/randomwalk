# Wiki Consolidation Plan

## Summary

Consolidate **randomwalk wiki** content into **llm wiki**, leaving only randomwalk-specific items with links to the central documentation.

---

## Part 1: Verified Incorrect Content in randomwalk Wiki

### Troubleshooting FAQ - Critical Errors

| Issue | Location | Problem | Correct Solution |
|-------|----------|---------|------------------|
| **1. Invalid cachix commands** | "How do I check my cachix storage usage?" | `cachix cache johngavin --info` and `cachix cache johngavin --list` do NOT exist | Use web interface: https://app.cachix.org/cache/johngavin OR curl individual narinfo files |
| **2. "Restart shell every 2-3 hours"** | Prevention advice for GC issues | This is a workaround, not a solution | Use GC roots via `nix-build --out-link nix-shell-root` or `default.sh` pattern with persistent symlink |
| **3. Missing GC root solution** | Nix Environment Issues section | No mention of the actual solution (GC roots) | Add: `nix-shell-root` symlink prevents GC from removing store paths |
| **4. Wrong file paths** | "How do I update Nix files after changing DESCRIPTION?" | References `R/setup/generate_nix_files.R` which doesn't exist | Should be `default.R` which generates `default.nix` |
| **5. Hardcoded paths** | Multiple locations | `/Users/johngavin/docs_gh/claude_rix/random_walk` | Use relative paths or correct project path |
| **6. Inconsistent redirects** | Troubleshooting-Nix-Environment page | Redirects to claude_rix wiki, not llm wiki | Should redirect to llm wiki (centralized location) |

### Cachix Commands - Verified Correct Syntax

Per [cachix CLI documentation](https://docs.cachix.org/):

```bash
# CORRECT commands:
cachix push johngavin ./result     # Push to cache
cachix use johngavin               # Configure nix.conf to use cache
cachix authtoken <token>           # Set auth token
cachix pin johngavin <name> <path> # Pin a store path

# INCORRECT (from wiki):
cachix cache johngavin --info      # ERROR: 'cache' subcommand doesn't exist
cachix cache johngavin --list      # ERROR: same

# To check cache contents:
# 1. Use web: https://app.cachix.org/cache/johngavin
# 2. Use curl: curl https://johngavin.cachix.org/<hash>.narinfo
```

### GC Root Solution (Missing from Wiki)

The FAQ says "restart shell every 2-3 hours" but the ACTUAL solution is:

```bash
# In default.sh (correct pattern from CLAUDE.md):
#!/bin/bash
nix-build default.nix --out-link nix-shell-root
nix-shell default.nix "$@"
```

The `--out-link nix-shell-root` creates a GC root that PREVENTS garbage collection from removing the shell's dependencies. This is the proper solution, not periodic restarts.

---

## Part 2: Page-by-Page Analysis

### randomwalk Wiki Pages

| Page | Action | Reason |
|------|--------|--------|
| **Home** | REPLACE with links | General content should be in llm wiki |
| **Async Dashboard Approaches** | KEEP | randomwalk-specific (crew/mirai patterns) |
| **Deploying Shinylive Dashboards** | MOVE to llm | Generic guidance, not randomwalk-specific |
| **Dynamic Grid Broadcasting Algorithm** | KEEP | randomwalk-specific algorithm |
| **GitHub Actions and Cachix Optimization** | MOVE to llm | Generic workflow optimization |
| **How Async Dashboard Uses Crew and Targets** | KEEP | randomwalk-specific implementation |
| **Troubleshooting FAQ** | DELETE/MERGE | Most content incorrect or generic; merge valid parts to llm |
| **Troubleshooting Nix Environment** | Already redirected | Fix redirect to point to llm wiki |
| **Using Gemini CLI** | MOVE to llm | Generic tooling, not randomwalk-specific |
| **WebR Performance** | MOVE to llm | Generic WebR guidance |
| **Working with Claude** | MOVE to llm | Generic Claude usage |

### llm Wiki Pages (Keep As-Is)

| Page | Status |
|------|--------|
| Home | Keep - central hub |
| Code Coverage with Nix | Keep |
| Deployment Strategy | Keep |
| Nix Environment Guide | Keep - expand with corrected content |
| R-WASM Build Workflows | Keep |
| Shinylive Lessons Learned | Keep |
| Technical Notes | Keep - expand with corrected troubleshooting |
| Workflows and Best Practices | Keep |

---

## Part 3: Consolidation Actions

### Step 1: Fix llm Wiki (Add Missing Content)

Add to **Nix Environment Guide** or **Technical Notes**:

```markdown
## GC Root Solution (CRITICAL)

The proper solution for environment degradation is NOT restarting shells periodically.
Use GC roots to prevent garbage collection:

### Using default.sh Pattern

```bash
#!/bin/bash
# Creates GC root that prevents garbage collection
nix-build default.nix --out-link nix-shell-root
nix-shell default.nix "$@"
```

### Why This Works
- `nix-shell-root` symlink points to /nix/store/...
- Nix GC never removes paths referenced by symlinks
- Shell can run indefinitely without degradation

### Cachix CLI Reference

```bash
# Valid commands:
cachix push <cache> <path>     # Push store paths
cachix use <cache>             # Add to nix.conf
cachix authtoken <token>       # Set authentication
cachix pin <cache> <name> <path>  # Create pin

# Check cache via web: https://app.cachix.org/cache/<name>
```
```

### Step 2: Merge Generic Content to llm Wiki

Move these sections from randomwalk Troubleshooting FAQ to llm Technical Notes:
- Nix Environment Issues (corrected)
- GitHub Actions and CI/CD Issues
- Git and GitHub Issues

### Step 3: Replace randomwalk Wiki Pages

Replace these pages with redirect notices:

```markdown
# [Page Title]

This content has been moved to the centralized documentation.

**See:** [llm wiki - Page Name](https://github.com/JohnGavin/llm/wiki/Page-Name)

---

For randomwalk-specific documentation, see:
- [Async Dashboard Approaches](Async-Dashboard-Approaches)
- [Dynamic Grid Broadcasting Algorithm](Dynamic-Grid-Broadcasting-Algorithm)
- [How Async Dashboard Uses Crew and Targets](How-Async-Dashboard-Uses-Crew-and-Targets)
```

### Step 4: Delete Troubleshooting FAQ

After merging valid content, delete this page entirely - it has too many errors to maintain.

### Step 5: Update randomwalk Home Page

New Home page content:

```markdown
# randomwalk Wiki

Random walk simulation package for R.

## Project Documentation

- [Async Dashboard Approaches](Async-Dashboard-Approaches) - crew/mirai patterns
- [Dynamic Grid Broadcasting Algorithm](Dynamic-Grid-Broadcasting-Algorithm) - grid state algorithm
- [How Async Dashboard Uses Crew and Targets](How-Async-Dashboard-Uses-Crew-and-Targets) - implementation

## General Documentation

For generic R package development, Nix, and deployment:
**See [llm wiki](https://github.com/JohnGavin/llm/wiki)** which contains:
- Nix Environment Guide
- Deployment Strategy
- Shinylive & WebR
- GitHub Actions
- Troubleshooting
```

---

## Part 4: Code Examples to Test

Before finalizing, test these commands from the llm wiki:

### Must Work

```bash
# 1. GC root pattern
nix-build default.nix --out-link nix-shell-root
ls -la nix-shell-root  # Should be symlink to /nix/store/...

# 2. Cachix push
nix-build default.nix
cachix push johngavin ./result

# 3. Check deployment
curl -I https://johngavin.github.io/randomwalk/
```

### Must Fail (Verify Invalid)

```bash
# These should produce errors:
cachix cache johngavin --info   # Error: unknown command
cachix cache johngavin --list   # Error: unknown command
```

---

## Part 5: Final Structure

### randomwalk Wiki (3 pages)
1. **Home** - Links to project docs and llm wiki
2. **Async Dashboard Approaches** - randomwalk-specific
3. **Dynamic Grid Broadcasting Algorithm** - randomwalk-specific
4. **How Async Dashboard Uses Crew and Targets** - randomwalk-specific

### llm Wiki (8+ pages)
- All generic content (Nix, deployment, CI, troubleshooting)
- Corrected commands and solutions
- Central reference for all projects

---

## Approval Required

1. **Approve consolidation strategy above?**
2. **Should I test the invalid cachix commands to confirm they fail?**
3. **Proceed with wiki edits?**

---

## Sources

- [Cachix CLI documentation](https://docs.cachix.org/)
- [Cachix GitHub](https://github.com/cachix/cachix)
- [NixOS Wiki - Binary Cache](https://nixos.wiki/wiki/Binary_Cache)
