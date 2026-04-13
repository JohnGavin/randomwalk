# Changelog

## 2026-04-13

### Completed

- **Vectorized simulation engine**: Replaced per-walker R loops with matrix operations
  (10-50x faster). All walkers move simultaneously via `pos_mat`, padded grid eliminates
  bounds checking, adaptive batch sizing (200k walker-ops target).
- **Inline fallback engine**: Dashboard works without `randomwalk` WebR binary. Inline
  `initialize_grid()`, `generate_walker_positions()`, `plot_grid_enhanced()` when package
  unavailable (build-webr CI step failing due to upstream rwasm issue).
- **Quintile statistics with launch/termination toggle**: Radio button switches grouping.
  Fixed `cut()` "breaks not unique" error with ntile-style assignment.
- **Survival slider defaults to median** (50% alive step).
- **Removed Walker Paths tab** (no paths stored in vectorized mode).
- **Removed broken download button** (downloadHandler unsupported in Shinylive).
- **Wiki staleness review**: Updated 3/4 wiki pages with vectorized engine architecture.
- **Global rule**: `shinylive-webr-nonblocking` and `wiki-staleness-check` added.
- **Deploy workflow fix**: `if: always()` on deploy job so it runs when build-webr fails.
- **GitHub issues**: #197 (logo), #198 (batch tuning), #199 (wiki staleness).

### Failed Approaches

- **`invalidateLater(N)` for non-blocking sim**: Does NOT yield WebR's Web Worker thread.
  The R reactive loop stays busy without posting messages to the JS main thread.
  Workaround: JS round-trip via `sendCustomMessage` → `setTimeout` → `setInputValue`.
- **`proc.time()` time-budgeted batching**: Elapsed clock doesn't advance during WASM
  execution. The `repeat` loop with time-based exit runs all steps without yielding.
  Workaround: Fixed step count per batch.
- **Per-walker inlined fast functions**: 3-5x faster than exported functions but still
  too slow for 3000+ walkers (hours). Workaround: Full vectorization with matrix ops.
- **Serving from `docs/articles/`**: Shinylive service worker can't find WebR packages
  from that directory structure. Must render to temp dir and serve from there.

### Accuracy / Metrics

| Config | Before | After |
|--------|--------|-------|
| 100×100, 200 walkers | 53s (blocking) | ~35s (responsive UI) |
| 200×200, 5000 walkers | ~12 hours | ~minutes |
| UI responsiveness during sim | Frozen | Fully interactive |

### Known Limitations

- Walker paths not stored in vectorized mode (speed trade-off)
- `build-webr` CI step failing (upstream rwasm `res_one_row_df` error)
- Dark mode text contrast may need tuning for some Shiny widget types
- Very large sims (300×300, 10k+ walkers) still take several minutes in WebR

## 2026-04-12

### Completed

- Non-blocking WebR simulation via JS round-trip batching
- Dark mode toggle (outer page + Shiny iframe)
- pkgdown navbar restructured: Demos / Analysis / Documentation
- CHANGELOG.md created
- Project and global memory files for Shinylive patterns

### Lessons Learned

- `invalidateLater(N)` in WebR/Shinylive: Worker thread never yields to JS main thread
- `proc.time()[["elapsed"]]` does not advance during R/WASM execution
- Shinylive service workers cache aggressively — change port each test
- Dark mode in Shinylive apps needs custom CSS/JS (not bslib `light-switch`)
- `bootswatch` + `bslib: preset` conflict in `_pkgdown.yml` — remove bootswatch
