# Cachix Workflow for R Packages (rix-Aligned)

**Based on official rix best practices and Cachix documentation**

## Core Principle: Layered Binary Caches

From the [rix binary cache vignette](https://cran.r-project.org/web/packages/rix/vignettes/z-binary_cache.html):

> "You can also use several caches at once, NixOS's public cache, our `rstats-on-nix` cache, and your own, so your cache will only end up holding the binaries not found in the other two caches!"

### Cache Layer Priority

When pulling (downloading) packages, Nix checks caches in order:

1. **cache.nixos.org** - NixOS public cache (system packages, base R)
2. **rstats-on-nix.cachix.org** - R packages (CRAN, Bioconductor)
3. **johngavin.cachix.org** - Project-specific packages (randomwalk)

**Key insight**: Users only download from your cache what's NOT already in upstream caches.

## Why Dependencies Get Pushed (And Why That's OK)

### The Reality

When you run:
```bash
cachix push johngavin /nix/store/.../r-randomwalk
```

Cachix pushes the **entire closure**:
- randomwalk (your package)
- ggplot2, logger, crew, nanonext (dependencies)
- All transitive dependencies

**You cannot prevent this.** It's how Nix binary caches work.

### Why This Isn't a Problem

From [Bruno Rodrigues' blog](https://brodrigues.co/posts/2024-04-04-nix_for_r_part_11.html):

> "packages that are already available from the usual, public, cache.nixos.org don't get rebuilt nor cached in mine; they simply continue getting pulled directly from there."

**Translation**:
- Your cache contains duplicates (storage overhead)
- Users pulling from your cache still get dependencies from upstream (correct behavior)
- Only your unique packages (randomwalk) actually get used from johngavin cache

## Automatic Garbage Collection

From [Cachix GC documentation](https://docs.cachix.org/garbage-collection):

### How It Works

1. **Trigger**: At **85% of storage limit**, you receive warning email
2. **Algorithm**: Sorts paths by **last accessed date** (or creation date if never accessed)
3. **Deletion**: Removes oldest paths first (unpinned only)
4. **Protection**: Pinned paths are **immune to GC**

### Key Points

- ✅ **Fully automatic** - no configuration needed
- ✅ **Access-based** - frequently used paths stay
- ✅ **Transparent** - view deletion queue at https://app.cachix.org/garbage-collection
- ❌ **No manual control** - triggered by storage limit only

## Recommended Workflow

### Step 1: Build and Push

```bash
# Build your package
nix-build package.nix

# Push to cachix (dependencies included automatically)
cachix push johngavin ./result

# View what was pushed
# https://app.cachix.org/cache/johngavin#search
```

### Step 2: Pin Your Package

```bash
# Get store path
STORE_PATH=$(nix-build package.nix --no-out-link)
PKG_VERSION=$(grep "^Version:" DESCRIPTION | awk '{print $2}' | tr -d '\r')

# Pin permanently
cachix pin johngavin "randomwalk-v${PKG_VERSION}" "$STORE_PATH" --keep-forever
```

**Why pin?**
- Protects your package from GC
- Dependencies (ggplot2, etc.) are NOT pinned → will be GC'd eventually
- Result: Cache stays small, your packages stay forever

### Step 3: Trust Automatic GC

**No action required!**

Cachix will:
1. Monitor storage usage
2. Email warning at 85%
3. Delete oldest **unpinned** paths when needed
4. Keep **pinned** paths forever

## Storage Management

### Current Setup

- **Free tier**: 5GB storage
- **Current usage**: Check at https://app.cachix.org/cache/johngavin
- **GC queue**: View at https://app.cachix.org/garbage-collection

### If Cache Fills Up

**Option 1: Do Nothing (Recommended)**
- Let GC delete old duplicate R packages automatically
- Your pinned randomwalk versions are safe

**Option 2: Manual Cleanup**
- Go to https://app.cachix.org/cache/johngavin
- Search for and delete individual R packages (ggplot2, logger, etc.)
- Keep randomwalk only

**Option 3: Upgrade Storage**
- Increase storage limit to delay GC trigger
- See pricing at https://cachix.org/pricing

## Updated push_to_cachix.sh

```bash
#!/usr/bin/env bash
#
# push_to_cachix.sh - Push randomwalk to johngavin cachix (rix-aligned)
#
# Based on rix best practices:
# - Pushes package + dependencies (expected behavior)
# - Pins package to prevent GC (protects your work)
# - Lets GC clean up duplicate dependencies automatically

set -euo pipefail

echo "=== Push randomwalk to johngavin cachix ==="
echo ""

# Get package info
PKG_NAME=$(grep "^Package:" DESCRIPTION | awk '{print $2}' | tr -d '\r')
PKG_VERSION=$(grep "^Version:" DESCRIPTION | awk '{print $2}' | tr -d '\r')
echo "📦 Package: $PKG_NAME v$PKG_VERSION"

# Build package
echo ""
echo "🔨 Building package.nix..."
RESULT=$(nix-build package.nix --no-out-link)
echo "✅ Built: $RESULT"

# Push to cachix (dependencies will be included - this is expected!)
echo ""
echo "📤 Pushing to johngavin cachix..."
echo "ℹ️  Note: Dependencies will be included (normal rix behavior)"
cachix push johngavin "$RESULT"

# Pin this version to protect from GC
echo ""
echo "📌 Pinning $PKG_NAME v$PKG_VERSION..."
PIN_NAME="randomwalk-v${PKG_VERSION}"
cachix pin johngavin "$PIN_NAME" "$RESULT" --keep-forever

echo ""
echo "✅ Success! Your cache now contains:"
echo "   ✓ $PKG_NAME v$PKG_VERSION (pinned forever)"
echo "   ✓ Dependencies (unpinned, will be GC'd when storage limit reached)"
echo ""
echo "📊 Monitor cache: https://app.cachix.org/cache/johngavin"
echo "🗑️  GC queue: https://app.cachix.org/garbage-collection"
echo ""
echo "💡 Tip: Users pulling will get dependencies from rstats-on-nix cache,"
echo "   and only randomwalk from johngavin cache (layered cache approach)."
```

## Common Questions

### Q: Why is my cache full of R packages?

**A**: Because Cachix pushes the entire closure (package + dependencies). This is expected and correct behavior.

### Q: Isn't this wasteful?

**A**: Slightly (storage overhead), but not problematic because:
- Users pulling get dependencies from upstream caches
- GC automatically cleans up old duplicates
- Storage is cheap (5GB free tier)

### Q: Should I manually delete duplicates?

**A**: No need! Just pin your packages and trust GC. Manual deletion is only useful if:
- You're near storage limit and need immediate space
- You want to minimize storage costs

### Q: How do I keep only specific randomwalk versions?

**A**: Use time-based or revision-based pins:

```bash
# Keep for 90 days
cachix pin johngavin randomwalk-v2.0.0 <store-path> --keep-days 90

# Keep last 5 versions only
cachix pin johngavin randomwalk-releases <store-path> --keep-revisions 5
```

## GitHub Actions Integration

From [rix documentation](https://cran.r-project.org/web/packages/rix/vignettes/z-binary_cache.html), use `rix::ga_cachix()` to generate workflows:

```r
# In R
rix::ga_cachix(
  cache_name = "johngavin",
  secrets_name = "CACHIX_AUTH_TOKEN"
)
```

This creates `.github/workflows/` that:
1. Builds your environment on every push
2. Pushes to johngavin cachix automatically
3. Layers with NixOS and rstats-on-nix caches

## Summary: The rix Philosophy

1. ✅ **Push freely** - Let dependencies be included
2. ✅ **Pin selectively** - Protect your packages from GC
3. ✅ **Trust GC** - Let Cachix clean up automatically
4. ✅ **Leverage layers** - Users pull from upstream caches first
5. ❌ **Don't micromanage** - GC is smarter than manual deletion

**Goal**: Reproducible builds with minimal cache management, aligned with rix best practices.

---

## References

- [rix binary cache vignette](https://cran.r-project.org/web/packages/rix/vignettes/z-binary_cache.html)
- [Bruno Rodrigues: Nix for R Part 11](https://brodrigues.co/posts/2024-04-04-nix_for_r_part_11.html)
- [Cachix Garbage Collection](https://docs.cachix.org/garbage-collection)
- [Cachix Pins Documentation](https://docs.cachix.org/pins)
- [Cachix Blog: Introducing Pins](https://blog.cachix.org/posts/2023-05-23-introducing-pins-permanent-nix-binary-storage/)
- [Cachix Blog: Changes to GC](https://blog.cachix.org/posts/2020-10-01-changes-to-garbage-collection/)
