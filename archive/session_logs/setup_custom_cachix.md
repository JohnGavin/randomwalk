# Setup Custom Cachix Cache for randomwalk

## Why We Need This

The `rstats-on-nix` Cachix cache is read-only for us. We need our own cache where we can:
- PUSH our built packages (first build)
- PULL cached packages (subsequent builds)
- Reduce build time from 17 min → ~2-3 min

## Steps to Setup Custom Cachix Cache

### 1. Create Cachix Account (Free)

1. Go to: https://app.cachix.org/
2. Sign in with GitHub account
3. Free tier allows:
   - 5GB storage
   - Unlimited public caches
   - Perfect for this project!

### 2. Create a New Cache

1. Click "Create cache"
2. Cache name: `randomwalk` (or `johngavin` for all your repos)
3. Keep it **Public** (free tier)
4. Click "Create"

### 3. Get Auth Token

1. Go to cache settings
2. Click "Auth tokens" tab
3. Click "Create token"
4. Name: `github-actions-randomwalk`
5. Permissions: **Write** (to push builds)
6. Copy the token (starts with `eyJ...`)

### 4. Add Token to GitHub Secrets

1. Go to: https://github.com/JohnGavin/randomwalk/settings/secrets/actions
2. Click "New repository secret"
3. Name: `CACHIX_AUTH_TOKEN`
4. Value: Paste the token from step 3
5. Click "Add secret"

### 5. Update Workflow Files

Update both workflows to use our cache with auth:

**File: `.github/workflows/nix-builder.yaml`**
```yaml
- uses: cachix/cachix-action@v15
  with:
    name: randomwalk  # Or johngavin
    authToken: '${{ secrets.CACHIX_AUTH_TOKEN }}'
```

**File: `.github/workflows/tests-r-via-nix.yaml`**
```yaml
- uses: cachix/cachix-action@v14
  with:
    name: randomwalk  # Or johngavin
    authToken: '${{ secrets.CACHIX_AUTH_TOKEN }}'
```

### 6. Test the Setup

1. Push the updated workflows
2. First build: ~17 min (builds and PUSHES to cache)
3. Second build: ~2-3 min (PULLS from cache)
4. Monitor at: https://app.cachix.org/cache/randomwalk

## Expected Results

### First Build (after setup)
- Duration: ~17 min (same as now)
- Cachix: PUSHING packages to our cache
- Log: `copying path ... to 'https://randomwalk.cachix.org'`

### Second Build (using cache)
- Duration: ~2-3 min (85% faster!)
- Cachix: PULLING packages from our cache
- Log: `copying path ... from 'https://randomwalk.cachix.org'`

### Future Builds
- All future builds: ~2-3 min
- Cache persists across branches
- Only rebuild when default-ci.nix changes

## Benefits

- ✅ 85% faster CI/CD (17 min → 2-3 min)
- ✅ Full control over cache
- ✅ Free (public cache, 5GB limit)
- ✅ Works across all branches
- ✅ Can be used for other projects

## Alternative: Multi-Cache Strategy

Use BOTH caches for best performance:

```yaml
- uses: cachix/cachix-action@v15
  with:
    name: rstats-on-nix  # Fallback cache (read-only)

- uses: cachix/cachix-action@v15
  with:
    name: randomwalk     # Our cache (read-write)
    authToken: '${{ secrets.CACHIX_AUTH_TOKEN }}'
```

This way:
- First try rstats-on-nix (might have some packages)
- Push to randomwalk (our cache)
- Future builds pull from randomwalk

## Next Steps

1. Create Cachix account
2. Create cache named `randomwalk` or `johngavin`
3. Get auth token
4. Add to GitHub secrets as `CACHIX_AUTH_TOKEN`
5. I'll update the workflow files
6. Test with a new push

Ready to proceed? I can update the workflows once you have the token set up!
