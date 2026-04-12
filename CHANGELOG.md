# Changelog

## Unreleased (2026-04-12)

### Fixed

- **Dashboard UI freeze during simulation**: Replaced blocking `run_simulation()` call
  with JS round-trip batched execution. The browser UI (dropdowns, tabs, progress display)
  now remains fully interactive during simulation. Root cause: `invalidateLater()` does
  not yield the WebR Web Worker thread — only a JS `sendCustomMessage` → `setTimeout` →
  `setInputValue` round-trip forces a true yield to the browser event loop.

- **PNG device error in WebR**: Added `tryCatch` fallback around `plot_grid_enhanced()`
  with `image()` fallback for environments where ggplot2 rendering fails. Download handler
  falls back to SVG if PNG device unavailable.

- **Debug page and Simulation Status not updating**: Both caused by the blocking simulation.
  Now update in real-time between batches via reactive values.

### Added

- **Dark mode toggle**: Moon/sun button (top-right) for all dashboard pages and tabs.
  Respects OS `prefers-color-scheme`, persists via `localStorage`.

- **Tips section in Notes tab**: Moved from outside the Shinylive app (where it was
  inaccessible during simulation) to the top of the Notes tab.

### Changed

- **pkgdown site layout**: Split single "Articles" dropdown into three navbar items:
  Demos, Analysis, Documentation. Added dark/light theme toggle (`light-switch: true`).
  Removed dead `dla_theory.html` link, added missing `targets_pipeline.html`.

### Lessons Learned

- `invalidateLater(N)` in WebR/Shinylive: schedules within R's reactive loop but the
  Worker thread never yields to the JS main thread. UI stays frozen.
- `proc.time()[["elapsed"]]` does not advance during R/WASM execution.
- Shinylive service workers cache aggressively — use a different HTTP port for each
  test iteration to avoid stale cached content.
- Dark mode for Shinylive apps requires custom CSS/JS inside the Shiny app — bslib's
  `light-switch: true` only applies to the outer Quarto/pkgdown page, not the iframe.
