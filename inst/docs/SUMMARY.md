# Documentation Summary - Cachix Workflow Update (December 2025)

## What Changed

Updated all documentation to align with **rix best practices** for managing binary caches with Cachix.

### Key Insight from rix Documentation

From [rix binary cache vignette](https://cran.r-project.org/web/packages/rix/vignettes/z-binary_cache.html):

> "You can also use several caches at once, NixOS's public cache, our `rstats-on-nix` cache, and your own, so your cache will only end up holding the binaries not found in the other two caches!"

## The rix Philosophy: Layered Caches

### When Pulling (Downloading)

Nix checks caches in order:
1. cache.nixos.org (NixOS packages)
2. rstats-on-nix.cachix.org (R packages)  
3. johngavin.cachix.org (your packages)

**Result**: Users only download what's NOT in upstream caches.

### When Pushing (Uploading)

Cachix pushes **entire closure** (package + all dependencies):
- randomwalk ✓
- ggplot2, logger, crew, etc. ✓ (dependencies)

**This is expected and cannot be prevented.**

## Why Duplicates Are OK

From [Bruno Rodrigues' blog](https://brodrigues.co/posts/2024-04-04-nix_for_r_part_11.html):

> "packages that are already available from the usual, public, cache.nixos.org don't get rebuilt nor cached in mine; they simply continue getting pulled directly from there."

**Implication**:
- johngavin cache contains duplicates (storage overhead)
- Users still get dependencies from upstream caches (correct behavior)
- Only unique packages (randomwalk) are actually used from johngavin

## Automatic Garbage Collection

From [Cachix GC docs](https://docs.cachix.org/garbage-collection):

- **Trigger**: Automatic at 85% storage
- **Algorithm**: Deletes oldest unpinned paths by last access
- **Protection**: Pinned paths immune to GC
- **Configuration**: None needed (fully automatic)

## Updated Workflow

### Old Approach (Incorrect)
```bash
# ❌ Manually delete duplicate R packages from cache
# ❌ Worry about cache size
# ❌ Try to prevent dependencies from being pushed
```

### New Approach (rix-Aligned)
```bash
# ✅ Push package (dependencies included - expected!)
../push_to_cachix.sh

# ✅ Script automatically pins your package
cachix pin johngavin randomwalk-v2.0.0 <store-path> --keep-forever

# ✅ Trust automatic GC to clean up duplicates
# No manual action needed!
```

## Files Updated

### New Files

1. **`docs/CACHIX_WORKFLOW.md`** - Comprehensive guide
   - Layered cache philosophy
   - Automatic GC explanation
   - Best practices aligned with rix
   - All references included

### Updated Files

2. **`push_to_cachix.sh`** - Now pins packages automatically
   - Builds package.nix
   - Pushes to cachix (dependencies included)
   - Pins package to protect from GC
   - Shows helpful output

3. **`NIX_WORKFLOW.md`** - Updated Cachix Setup section
   - Added rix philosophy explanation
   - Added automatic GC details
   - Added cache management best practices
   - Included all references

4. **`NIX_QUICKSTART.md`** - Added understanding section
   - Explains why dependencies get pushed
   - Clarifies why it's not a problem
   - Links to detailed docs

## Current State

### johngavin Cache

- ✅ randomwalk v2.0.0.9000 (pinned, permanent)
- ✅ Dependencies (unpinned, will be GC'd when storage limit reached)

**Monitor**:
- Cache contents: https://app.cachix.org/cache/johngavin
- GC queue: https://app.cachix.org/garbage-collection

### What Happens Next

1. **Storage usage increases** as you push more versions
2. **At 85% of 5GB** you receive warning email
3. **Cachix automatically deletes** oldest unpinned paths
4. **Your pinned packages stay** forever

## References Included

All documentation now includes these official references:

- [rix binary cache vignette](https://cran.r-project.org/web/packages/rix/vignettes/z-binary_cache.html)
- [Bruno Rodrigues: Nix for R Part 11](https://brodrigues.co/posts/2024-04-04-nix_for_r_part_11.html)
- [Cachix Garbage Collection](https://docs.cachix.org/garbage-collection)
- [Cachix Pins Documentation](https://docs.cachix.org/pins)
- [Cachix Blog: Introducing Pins](https://blog.cachix.org/posts/2023-05-23-introducing-pins-permanent-nix-binary-storage/)
- [Cachix Blog: Changes to GC](https://blog.cachix.org/posts/2020-10-01-changes-to-garbage-collection/)

## Summary

**Problem**: johngavin cache was filling with duplicate R packages

**Root Cause**: Cachix automatically includes all dependencies when pushing

**Solution**: This is expected rix behavior! Trust the layered cache approach and automatic GC.

**Action Required**: None! Just use `push_to_cachix.sh` and let Cachix handle the rest.

**Result**: Reproducible builds, minimal manual cache management, aligned with rix philosophy.

---

**Last Updated**: December 2025
**Aligned with**: rix v0.17.2, Cachix CLI v1.7.9
