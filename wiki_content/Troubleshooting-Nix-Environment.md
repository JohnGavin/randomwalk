# Troubleshooting Nix Environment Issues

## Common Symptoms

During long sessions (several hours), the nix environment may degrade with these symptoms:

- ✅ → ❌ Commands taking longer than usual
- ✅ → ❌ "command not found" for tools that worked earlier (`gh`, `git`, `curl`, `python3`, `which`)
- ✅ → ❌ R packages that loaded before won't load
- ✅ → ❌ Git operations failing
- ✅ → ❌ Symlinks in PATH pointing to non-existent nix store paths
- ✅ → ❌ Error: `/nix/store/XXX-tool/bin/tool: No such file or directory`

**When you see these: Restart the shell immediately**

## Root Causes

### 1. Nix Garbage Collection During Active Session

**What Happened:**
- The nix store paths in `$PATH` at session start got garbage collected
- Nix's garbage collector removed unused store paths
- The session's `$PATH` still referenced the old, now-deleted paths
- Result: "command not found" even though tools are in PATH

**Example:**
```bash
# At session start:
$PATH includes: /nix/store/rd1mj7c2lrhxy0dbyzgpll7qi4p3wjw9-gh-2.82.1/bin

# Hours later, nix garbage collection runs:
nix-collect-garbage  # Removes unused paths

# Old path deleted from /nix/store/
# But $PATH still references it!
# Result: "No such file or directory"
```

### 2. Long-Running Shell Sessions

**Contributing Factors:**
- Session lasted several hours
- Multiple nix operations during session
- No shell restart to pick up new environment
- PATH became stale as nix store changed

## Prevention Strategies

### Strategy 1: Use Direnv (Recommended)

**What it does:** Automatically loads/unloads nix environments when you change directories

**Setup:**

1. **Install direnv:**
   ```bash
   # On macOS
   brew install direnv

   # Or via nix
   nix-env -iA nixpkgs.direnv
   ```

2. **Configure shell:**
   ```bash
   # Add to ~/.zshrc or ~/.bashrc
   eval "$(direnv hook zsh)"  # or bash
   ```

3. **Create .envrc in project:**
   ```bash
   # In random_walk directory
   echo "use nix" > .envrc
   direnv allow
   ```

**Benefits:**
- Environment loads automatically when entering directory
- Environment unloads when leaving
- No stale PATH issues
- Handles multiple projects cleanly

### Strategy 2: Periodic Shell Restart

**Simple approach for current setup:**

**When to restart:**
- Every 2-3 hours
- After any `nix-collect-garbage`
- When you see "command not found"
- Between major tasks

**Restart script:**
```bash
# Exit current shell and re-enter
exit
cd /Users/johngavin/docs_gh/claude_rix/random_walk
nix-shell default.nix
```

### Strategy 3: Monitor Environment Health

**Check environment health:**
```bash
check_nix_health() {
  echo "Checking nix environment..."

  # Count broken paths
  broken=0
  for path in $(echo $PATH | tr ':' '\n' | grep /nix/store); do
    if [ ! -d "$path" ]; then
      echo "BROKEN: $path"
      ((broken++))
    fi
  done

  if [ $broken -gt 0 ]; then
    echo "❌ $broken broken paths found - restart shell!"
    return 1
  else
    echo "✅ Environment healthy"
    return 0
  fi
}

# Run periodically
check_nix_health
```

## Recovery Procedures

### Immediate Recovery (When Environment Breaks)

**Option 1: Exit and Re-enter**
```bash
# Exit broken shell
exit

# Re-enter nix shell
cd /Users/johngavin/docs_gh/claude_rix/random_walk
nix-shell default.nix
```

**Option 2: Find Working Binaries** (Temporary workaround)
```bash
# Find what's actually available
find /nix/store -name "gh" -type f 2>/dev/null | head -1

# Use full path temporarily
/nix/store/XXXXX-gh-2.82.1/bin/gh run list ...
```

### Clean Rebuild

**When environment is completely broken:**

```bash
# 1. Exit all nix shells
exit

# 2. Clean up (optional - removes cached environments)
nix-collect-garbage -d

# 3. Rebuild environment from scratch
cd /Users/johngavin/docs_gh/claude_rix
nix-shell default.nix

# 4. Verify tools available
which git gh R
```

## Best Practices for Long Sessions

### 1. Use tmux for Session Persistence

**Ultimate solution:**

```bash
# Start tmux session
tmux new -s claude-work

# Inside tmux: start nix-shell
nix-shell default.nix

# Work...

# Detach (keeps shell running)
Ctrl+B, D

# Later: re-attach
tmux attach -t claude-work

# Shell is EXACTLY as you left it
```

**Advantages:**
- Shell never exits
- Can disconnect/reconnect
- Survives terminal close
- Survives system sleep

**Disadvantages:**
- Still vulnerable to GC (combine with direnv)
- Must be on same machine

### 2. Logging

**Track when issues occur:**
```bash
# Add to shell startup
echo "$(date): Nix shell started" >> ~/.nix-session.log
echo "PATH: $PATH" >> ~/.nix-session.log
```

## Why This Matters

**For long AI coding sessions:**
- Multiple hours of work
- Multiple git operations
- R package development
- CI/CD workflows
- Reproducibility critical

**Impact of degradation:**
- Lost work time (debugging environment)
- Potential data loss (interrupted git operations)
- Broken CI/CD (if pushing with broken git)
- Reproducibility compromised

## Summary

**The Issue:**
- Nix garbage collection removed store paths during active session
- PATH became stale, pointing to deleted paths
- Long sessions more susceptible

**The Solutions:**
1. **Best**: Use direnv for automatic environment management
2. **Good**: Restart shell periodically (every 2-3 hours)
3. **Alternative**: Use tmux + direnv combination for long sessions

**This is not a nix bug** - it's expected behavior when GC runs during a session. The solution is proper environment management tooling.

## Related Resources

- **Direnv**: https://direnv.net/
- **Nix Flakes**: https://nixos.wiki/wiki/Flakes
- **rix Package**: https://docs.ropensci.org/rix/
- **Nix GC**: https://nixos.org/manual/nix/stable/command-ref/nix-collect-garbage.html
