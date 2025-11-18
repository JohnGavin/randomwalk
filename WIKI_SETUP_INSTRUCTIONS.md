# GitHub Wiki Setup Instructions

This file contains instructions for uploading the wiki content files to the GitHub wiki.

## Wiki Content Ready

All wiki pages have been prepared in the `wiki_content/` directory:

- `Home.md` - Wiki home page with navigation
- `Troubleshooting-Nix-Environment.md` - Nix troubleshooting guide
- `Working-with-Claude-Across-Sessions.md` - Session management guide
- `Using-Gemini-CLI-for-Large-Codebases.md` - Gemini CLI guide
- `Deploying-Shinylive-Dashboards.md` - Dashboard deployment guide

## Method 1: Initialize and Upload via Git (Recommended)

### Step 1: Initialize Wiki on GitHub (Web Interface)

1. Go to https://github.com/JohnGavin/randomwalk/wiki
2. Click "Create the first page"
3. Enter any title (e.g., "Welcome")
4. Enter any content (e.g., "Initializing wiki...")
5. Click "Save Page"

This creates the wiki git repository.

### Step 2: Clone and Add Wiki Pages

```bash
# From the random_walk directory
cd /Users/johngavin/docs_gh/claude_rix/random_walk

# Clone the wiki repository
git clone https://github.com/JohnGavin/randomwalk.wiki.git wiki_repo

# Copy wiki content files
cp wiki_content/*.md wiki_repo/

# Navigate to wiki repo
cd wiki_repo

# Add all pages
git add *.md

# Commit
git commit -m "Add wiki documentation pages

- Home page with navigation
- Troubleshooting Nix Environment guide
- Working with Claude Across Sessions guide
- Using Gemini CLI for Large Codebases guide
- Deploying Shinylive Dashboards guide"

# Push to GitHub
git push origin master

# Return to project directory
cd ..

# Clean up (optional)
rm -rf wiki_repo
```

### Step 3: Verify Wiki

Visit https://github.com/JohnGavin/randomwalk/wiki to see all pages.

## Method 2: Manual Upload via Web Interface

If you prefer to use the GitHub web interface:

### For Each Page:

1. Go to https://github.com/JohnGavin/randomwalk/wiki
2. Click "New Page"
3. Enter the page title (exactly as shown below)
4. Copy/paste the content from the corresponding file
5. Click "Save Page"

### Pages to Create:

| Page Title | Source File |
|------------|-------------|
| Home | `wiki_content/Home.md` |
| Troubleshooting Nix Environment | `wiki_content/Troubleshooting-Nix-Environment.md` |
| Working with Claude Across Sessions | `wiki_content/Working-with-Claude-Across-Sessions.md` |
| Using Gemini CLI for Large Codebases | `wiki_content/Using-Gemini-CLI-for-Large-Codebases.md` |
| Deploying Shinylive Dashboards | `wiki_content/Deploying-Shinylive-Dashboards.md` |

**Important**: Use the exact page titles shown above to ensure wiki links work correctly.

## Method 3: Using GitHub CLI (Alternative)

Unfortunately, `gh` CLI doesn't support wiki operations directly. Use Method 1 or 2 instead.

## After Setup

### Test All Links

After uploading, verify these links work:

**Wiki Home:**
- https://github.com/JohnGavin/randomwalk/wiki

**Individual Pages:**
- https://github.com/JohnGavin/randomwalk/wiki/Home
- https://github.com/JohnGavin/randomwalk/wiki/Troubleshooting-Nix-Environment
- https://github.com/JohnGavin/randomwalk/wiki/Working-with-Claude-Across-Sessions
- https://github.com/JohnGavin/randomwalk/wiki/Using-Gemini-CLI-for-Large-Codebases
- https://github.com/JohnGavin/randomwalk/wiki/Deploying-Shinylive-Dashboards

### Update README Links

The README.md already contains links to these wiki pages. They will work once the wiki is populated.

## Cleanup (After Successful Upload)

Once the wiki is successfully uploaded and verified:

```bash
# Remove source markdown files (content now in wiki)
rm -rf wiki_content/

# Remove these instructions
rm WIKI_SETUP_INSTRUCTIONS.md

# Commit the cleanup
git add -A
git commit -m "Clean up wiki setup files (content migrated to wiki)"
git push
```

## Source Files to Delete After Migration

The following files were migrated to the wiki and can be deleted from the repository:

**Top-level files** (already deleted):
- `context.md` ✅ (deleted - duplicate)
- `CLEANUP_Plan.md` ✅ (deleted - superseded)
- `RANDOM_WALK_PROJECT.md` ✅ (deleted - duplicate)

**Files moved to archive** (already done):
- `DASHBOARD_COMPLETE.md` → `archive/` ✅
- `FIXES_APPLIED.md` → `archive/` ✅
- `CORS_FIX.md` → `archive/` ✅
- `CLEANUP_SUMMARY.md` → `archive/` ✅
- `CLEANUP_SESSION_2025-11-18.md` → `archive/` ✅

**Note**: The original source files for wiki content (`NIX_ENVIRONMENT_DEGRADATION.md`, `CLAUDE_SESSION_PERSISTENCE.md`, `GEMINI.md`) are in the parent directory (`/Users/johngavin/docs_gh/claude_rix/`) and should remain there as master references.

## Troubleshooting

### Wiki Not Appearing
- Make sure you created at least one page through the web interface first
- Wait a few minutes for GitHub to initialize the wiki repository

### Clone Fails
- Ensure wiki is enabled (Settings → Features → Wikis checkbox)
- Ensure at least one page exists in the wiki

### Links Not Working
- Check that page titles exactly match (case-sensitive, spaces become hyphens)
- Example: "Troubleshooting Nix Environment" becomes `Troubleshooting-Nix-Environment`

## Summary

**Current Status:**
- ✅ 3 duplicate files deleted
- ✅ Archive directory created
- ✅ 5 historical files moved to archive
- ✅ 5 wiki pages prepared in `wiki_content/`
- ✅ README.md updated with wiki links
- ✅ PROJECT_INFO.md updated with wiki references

**Next Steps:**
1. Follow Method 1 above to upload wiki pages
2. Verify all wiki links work
3. Run cleanup commands to remove temporary files
4. Commit and push changes to repository

**Result:**
- Clean, organized repository structure
- Comprehensive wiki documentation
- Easy-to-find troubleshooting guides
- Better developer experience
