#!/bin/bash

# Script to upload wiki pages to GitHub
# Run this after initializing the wiki with at least one page via web interface

set -e  # Exit on error

echo "==============================================="
echo "Random Walk Wiki Upload Script"
echo "==============================================="
echo ""

# Check if wiki_content directory exists
if [ ! -d "wiki_content" ]; then
    echo "❌ Error: wiki_content/ directory not found"
    echo "   Please run this script from the random_walk directory"
    exit 1
fi

# Check if we have wiki pages
if [ ! -f "wiki_content/Home.md" ]; then
    echo "❌ Error: Wiki content files not found in wiki_content/"
    exit 1
fi

echo "📋 Found wiki content files:"
ls -1 wiki_content/*.md | sed 's/wiki_content\//   - /'
echo ""

# Clone wiki repository
echo "📥 Cloning wiki repository..."
if [ -d "wiki_repo" ]; then
    echo "   Removing existing wiki_repo directory..."
    rm -rf wiki_repo
fi

if ! git clone https://github.com/JohnGavin/randomwalk.wiki.git wiki_repo 2>/dev/null; then
    echo ""
    echo "❌ Failed to clone wiki repository"
    echo ""
    echo "The wiki needs to be initialized first:"
    echo ""
    echo "1. Visit: https://github.com/JohnGavin/randomwalk/wiki"
    echo "2. Click 'Create the first page'"
    echo "3. Enter title: 'Welcome'"
    echo "4. Enter content: 'Initializing wiki...'"
    echo "5. Click 'Save Page'"
    echo ""
    echo "After initialization, run this script again:"
    echo "   ./upload_wiki.sh"
    echo ""
    exit 1
fi

echo "✅ Wiki repository cloned"
echo ""

# Copy wiki pages
echo "📄 Copying wiki pages..."
cp wiki_content/*.md wiki_repo/
echo "✅ Copied $(ls -1 wiki_content/*.md | wc -l | tr -d ' ') wiki pages"
echo ""

# Navigate to wiki repo
cd wiki_repo

# Show what we're about to commit
echo "📝 Pages to upload:"
git status --short | sed 's/^/   /'
echo ""

# Add all pages
echo "➕ Adding pages to git..."
git add *.md
echo ""

# Commit
echo "💾 Creating commit..."
git commit -m "Add comprehensive wiki documentation

- Home page with navigation
- Troubleshooting Nix Environment guide
- Working with Claude Across Sessions guide
- Using Gemini CLI for Large Codebases guide
- Deploying Shinylive Dashboards guide

Migrated from repository markdown files for better discoverability."
echo ""

# Push
echo "🚀 Pushing to GitHub..."
git push origin master
echo ""

# Return to parent directory
cd ..

echo "✅ Wiki pages successfully uploaded!"
echo ""
echo "📖 Visit your wiki at:"
echo "   https://github.com/JohnGavin/randomwalk/wiki"
echo ""
echo "🔗 Individual pages:"
echo "   - Home: https://github.com/JohnGavin/randomwalk/wiki"
echo "   - Troubleshooting Nix: https://github.com/JohnGavin/randomwalk/wiki/Troubleshooting-Nix-Environment"
echo "   - Claude Sessions: https://github.com/JohnGavin/randomwalk/wiki/Working-with-Claude-Across-Sessions"
echo "   - Gemini CLI: https://github.com/JohnGavin/randomwalk/wiki/Using-Gemini-CLI-for-Large-Codebases"
echo "   - Dashboard Deploy: https://github.com/JohnGavin/randomwalk/wiki/Deploying-Shinylive-Dashboards"
echo ""

# Ask about cleanup
echo "🗑️  Cleanup"
echo ""
read -p "Remove wiki_repo directory? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf wiki_repo
    echo "✅ Removed wiki_repo/"
fi
echo ""

echo "==============================================="
echo "✨ Wiki setup complete!"
echo "==============================================="
