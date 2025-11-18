# Working with Claude Across Sessions

Claude Code doesn't remember previous conversations - each session starts fresh. This guide shows how to preserve context across sessions using file-based state.

## What Persists Automatically

✅ **Files you created/modified**
- All git commits
- All code changes
- Documentation (*.md files)
- Configuration files
- Everything in the filesystem

✅ **Git state**
- Branches
- Commits
- Uncommitted changes (git status)
- Stashes

✅ **File-based state**
- R targets cache (`_targets/`)
- Build artifacts
- Logs in `inst/logs/`

## What Does NOT Persist

❌ **Conversation history**
- Claude doesn't remember previous conversations
- Each session starts fresh
- No memory of what was discussed

❌ **Shell environment variables**
- R session variables
- Temporary environment settings
- In-memory data structures

❌ **Running processes**
- Background jobs
- R sessions
- Development servers

## Strategies for Preserving Context

### Strategy 1: Context Files (Recommended)

Create a running status file that Claude can read at the start of each session:

**File: `.claude/CURRENT_WORK.md`**
```markdown
# Current Focus: Dashboard deployment

## Active Branch
fix/shinylive-dashboard

## What I'm Doing
Fixing dashboard blank page issue using webr::mount()

## Progress
- [x] Identified issue (missing package loading)
- [x] Implemented webr::mount() solution
- [x] Pushed to branch
- [ ] Merge PR #19
- [ ] Publish release v0.1.1
- [ ] Verify deployment

## Blockers
- Nix environment degraded - need to restart shell

## Key Files Modified
- inst/shiny/dashboard/app.R
- vignettes/dashboard.qmd
- .github/workflows/pkgdown.yaml

## Next Session Should
1. Merge PR #19 to main
2. Wait for pkgdown deployment
3. Verify dashboard at URL
```

### Strategy 2: Session Checkpoints

Create a checkpoint before exiting each session:

**Checkpoint script: `~/bin/claude-checkpoint.sh`**
```bash
#!/bin/bash
PROJECT_DIR="${1:-.}"
CHECKPOINT_FILE="${PROJECT_DIR}/CLAUDE_CHECKPOINT.md"

cat > "$CHECKPOINT_FILE" << EOF
# Claude Session Checkpoint - $(date)

## Git Status
\`\`\`
$(git status)
\`\`\`

## Recent Commits
\`\`\`
$(git log --oneline -5)
\`\`\`

## Branch
$(git branch --show-current)

## Last 10 Modified Files
\`\`\`
$(ls -lt | head -10)
\`\`\`

## Session Notes
[Add manual notes about what you're working on]
EOF

echo "Checkpoint saved to $CHECKPOINT_FILE"
```

**Usage:**
```bash
# Before restarting shell
claude-checkpoint.sh

# After restarting, Claude can read CLAUDE_CHECKPOINT.md
# to understand exact state
```

### Strategy 3: Git-Based State Preservation

**Commit work-in-progress:**

```bash
# Save current state (even if incomplete)
git add -A
git commit -m "WIP: [what you're working on] - checkpoint"
git push

# After restart, continue:
git reset HEAD^  # Undo WIP commit but keep changes
# Or keep it and amend later
```

**Use git stash for uncommitted work:**
```bash
# Before restart
git stash push -m "Work in progress - $(date)"

# After restart
git stash list
git stash pop
```

### Strategy 4: Session Summary Documents

At the end of each significant session, create a summary:

**Template:**
```markdown
# Session Summary - [DATE]

## What Was Accomplished
1. [Task 1]
2. [Task 2]

## Current State
- Branch: [branch-name]
- Last commit: [commit-hash]
- Uncommitted changes: [list]

## Next Steps
1. [Next task]
2. [Next task]

## Blockers/Issues
- [Issue 1]
- [Issue 2]

## Notes for Next Session
- [Important context]
- [Decisions made]
```

## Recommended Workflow

### End of Session Checklist

```bash
# 1. Commit or stash work
git add -A
git commit -m "Progress update: [description]"
# OR
git stash push -m "WIP: [description]"

# 2. Update work status
vim .claude/CURRENT_WORK.md
# Mark what's done, what's next

# 3. Create checkpoint (optional)
claude-checkpoint.sh

# 4. Push to remote (backup)
git push

# 5. Now safe to exit shell
exit
```

### Start of New Session

```bash
# 1. Enter nix shell
cd /Users/johngavin/docs_gh/claude_rix/random_walk
nix-shell default.nix

# 2. First message to Claude:
"Please read .claude/CURRENT_WORK.md and continue where we left off"
```

**Claude will then:**
- Read the context file
- Understand current state
- Know what was done
- Know what to do next
- Resume from exactly where you left off

## One-Time Setup

```bash
# 1. Create context directory
mkdir -p .claude

# 2. Create checkpoint script
# Save claude-checkpoint.sh to ~/bin/
chmod +x ~/bin/claude-checkpoint.sh

# 3. Add to .gitignore (optional)
echo "CLAUDE_CHECKPOINT.md" >> .gitignore
# Keep CURRENT_WORK.md in git for sharing across machines
```

## Daily Workflow

**Morning (Start session):**
```bash
cd random_walk
nix-shell default.nix

# First Claude prompt:
"Read .claude/CURRENT_WORK.md and continue where we left off"
```

**During session (every 2-3 hours OR before shell restart):**
```bash
# Update status
vim .claude/CURRENT_WORK.md

# Commit progress
git add -A
git commit -m "Progress: [what you did]"
git push
```

**Evening (End session):**
```bash
# Update work status
vim .claude/CURRENT_WORK.md

# Commit everything
git add -A
git commit -m "End of day: [summary]"
git push

# Safe to exit
exit
```

## Multi-Machine Continuity

If you work across multiple machines:

**Setup on each machine:**
```bash
git clone https://github.com/JohnGavin/randomwalk.git
cd randomwalk

# Context files are in git:
# - .claude/CURRENT_WORK.md
# - SESSION_SUMMARY_*.md
```

**Workflow:**

**Machine A (morning):**
```bash
# Work...
# Update .claude/CURRENT_WORK.md
git add .claude/CURRENT_WORK.md
git commit -m "Update work status"
git push
```

**Machine B (evening):**
```bash
git pull
# Read .claude/CURRENT_WORK.md
# Continue exactly where you left off
```

## Advanced: tmux for True Persistence

**Ultimate solution for very long sessions:**

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
# Even after hours/days
```

**Advantages:**
- Shell never exits
- Can disconnect/reconnect
- Survives terminal close
- Survives system sleep

**Combine with direnv to prevent nix environment degradation**

## Git Aliases (Helpful Shortcuts)

Add to `~/.gitconfig`:
```bash
[alias]
    wip = !git add -A && git commit -m "WIP: $(date)"
    unwip = reset HEAD^
    snapshot = !git stash push -m \"Snapshot: $(date)\"
```

**Usage:**
```bash
git wip        # Quick save
git unwip      # Undo but keep changes
git snapshot   # Stash with timestamp
```

## Summary

### Best Practice for Session Continuity

**Use a combination:**

1. **Document liberally**
   - Session summaries
   - Fix documentation
   - Status files (`.claude/CURRENT_WORK.md`)

2. **Commit frequently**
   - Every 30-60 minutes
   - Use WIP commits
   - Push to backup remotely

3. **Use direnv** (prevents need to restart shell)
   - Auto-reload environment
   - Minimize shell restarts

4. **Create .claude/CURRENT_WORK.md**
   - Update throughout session
   - First thing Claude reads in new session
   - Lives in git

5. **Use tmux for long sessions**
   - Detach instead of exit
   - Re-attach when ready
   - True persistence

**This way, you can work for hours without losing context, and Claude can always resume exactly where you left off.**

## Related Resources

- See [[Troubleshooting Nix Environment]] for environment persistence
- See project's `PROJECT_INFO.md` for quick reference links
