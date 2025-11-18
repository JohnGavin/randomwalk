# Wiki Quick Start Guide

## Current Status

✅ **Completed**:
- Wiki content prepared (5 pages in `wiki_content/`)
- README.md updated with wiki links
- PROJECT_INFO.md updated with wiki references
- Upload script created (`upload_wiki.sh`)

⏳ **Remaining**:
- Initialize wiki on GitHub (requires manual step)
- Upload wiki pages (automated via script)

## 2-Step Wiki Setup

### Step 1: Initialize Wiki (1 minute, manual)

The wiki needs at least one page before we can upload content:

1. **Visit**: https://github.com/JohnGavin/randomwalk/wiki
2. **Click**: "Create the first page" button
3. **Enter**:
   - Title: `Welcome`
   - Content: `Initializing wiki...`
4. **Click**: "Save Page"

This creates the wiki git repository.

### Step 2: Upload All Pages (30 seconds, automated)

```bash
# Run the automated upload script
./upload_wiki.sh
```

The script will:
- Clone the wiki repository
- Copy all 5 wiki pages
- Commit and push to GitHub
- Show links to verify

**That's it!** ✅

## What Gets Uploaded

The script uploads these 5 pages:

1. **Home** - Wiki navigation and quick links
2. **Troubleshooting Nix Environment** - Nix troubleshooting guide
3. **Working with Claude Across Sessions** - Session management
4. **Using Gemini CLI for Large Codebases** - Gemini CLI guide
5. **Deploying Shinylive Dashboards** - Dashboard deployment guide

## Verify After Upload

Visit these URLs to confirm:

- **Home**: https://github.com/JohnGavin/randomwalk/wiki
- **Troubleshooting**: https://github.com/JohnGavin/randomwalk/wiki/Troubleshooting-Nix-Environment
- **Sessions**: https://github.com/JohnGavin/randomwalk/wiki/Working-with-Claude-Across-Sessions
- **Gemini**: https://github.com/JohnGavin/randomwalk/wiki/Using-Gemini-CLI-for-Large-Codebases
- **Dashboard**: https://github.com/JohnGavin/randomwalk/wiki/Deploying-Shinylive-Dashboards

## Cleanup After Successful Upload

```bash
# Remove temporary files
rm -rf wiki_content/
rm upload_wiki.sh
rm WIKI_SETUP_INSTRUCTIONS.md
rm WIKI_QUICK_START.md
rm MARKDOWN_RATIONALIZATION_SUMMARY.md

# Commit the cleanup
git add -A
git commit -m "Clean up: Wiki pages migrated to GitHub wiki"
git push
```

## Troubleshooting

**Script fails with "repository not found"**:
- Wiki not initialized yet → Complete Step 1 first

**Script fails with permission error**:
- Make script executable: `chmod +x upload_wiki.sh`

**Want to update a wiki page later**:
```bash
# Clone wiki
git clone https://github.com/JohnGavin/randomwalk.wiki.git

# Edit page
cd randomwalk.wiki
vim Page-Name.md

# Commit and push
git add Page-Name.md
git commit -m "Update page"
git push origin master
```

## Summary

**Time required**: ~2 minutes total
- Step 1 (manual): ~1 minute
- Step 2 (automated): ~30 seconds

**Ready to start?** → Go to Step 1 above!
