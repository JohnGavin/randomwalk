# Plan: Migrate from Shinylive to Quarto-WebR

## Executive Summary

Replace broken Shinylive dashboards with quarto-webr interactive code cells. This avoids Service Worker issues while maintaining browser-based interactivity.

## Current vs Proposed Approach

### Current (Shinylive - BROKEN)
- **Technology**: Shinylive for R (embedded Shiny apps in browser)
- **Package Loading**: webr::mount() from library.data files
- **Service Worker**: Required but registration failing
- **Build Process**: Can't rebuild from .qmd sources (Nix environment issues)
- **User Experience**: Complete failure - dashboards don't load

### Proposed (Quarto-WebR - SHOULD WORK)
- **Technology**: quarto-webr extension (interactive R code cells)
- **Package Loading**: YAML-based repository configuration
- **Service Worker**: Optional (works without it)
- **Build Process**: Can rebuild from .qmd sources
- **User Experience**: Code cells run in browser, packages pre-loaded

## Key Differences

### 1. Architecture

**Shinylive:**
```
User Browser
  ├─ Shinylive JS framework
  ├─ Service Worker (REQUIRED - BROKEN)
  ├─ WebR runtime
  ├─ Full Shiny app (UI + Server)
  └─ Package loading (webr::mount/install)
```

**Quarto-WebR:**
```
User Browser
  ├─ quarto-webr extension
  ├─ WebR runtime (no Service Worker needed)
  ├─ Code cells (like Jupyter)
  ├─ Packages pre-loaded from YAML config
  └─ Interactive widgets via shiny.ui
```

### 2. Vignette Structure

**Current (Shinylive):**
```qmd
---
title: Dashboard
filters:
  - shinylive
---

```{shinylive-r}
webr::mount(...)
library(shiny)
library(randomwalk)

ui <- fluidPage(...)
server <- function(input, output) {...}
shinyApp(ui, server)
```
```

**Proposed (Quarto-WebR):**
```qmd
---
title: Dashboard
webr:
  packages: ['shiny', 'randomwalk']
  repos:
    - https://johngavin.github.io/randomwalk/
filters:
  - webr
---

```{webr-r}
#| context: setup
# Packages pre-loaded via YAML, no webr:: calls needed!
library(shiny)
library(randomwalk)
```

```{webr-r}
# Interactive code cell - users can modify and re-run
simulation <- run_simulation(
  grid_size = 20,
  n_walkers = 5,
  neighborhood = "4-hood"
)
```

```{webr-r}
# Plot results
plot_grid(simulation)
```

```{webr-r}
# Interactive UI widget
shiny.ui::input_slider("n_walkers", "Walkers:", 1, 20, 5)
```
```

### 3. Package Loading

**Shinylive:**
- Requires explicit `webr::mount()` or `webr::install()` calls
- Calls happen at runtime in browser
- Can fail due to CORS, Service Worker issues
- No pre-loading available

**Quarto-WebR:**
- Configured in YAML frontmatter
- Packages downloaded and cached during page load
- No runtime webr:: calls needed
- Supports custom repositories via `repos:` config

### 4. User Experience

**Shinylive:**
- ✅ Full Shiny app experience
- ✅ Reactive UI (sliders, buttons)
- ❌ All-or-nothing (entire app loads or fails)
- ❌ Can't inspect intermediate steps
- ❌ Can't modify code easily

**Quarto-WebR:**
- ✅ Interactive code cells (like Jupyter)
- ✅ Can modify and re-run code
- ✅ See intermediate results
- ✅ Progressive enhancement (cells load independently)
- ⚠️ Limited reactive UI (shiny.ui widgets only)

## Migration Steps

### Phase 1: Setup (30 minutes)

1. **Install quarto-webr extension:**
   ```bash
   quarto add coatless/quarto-webr
   ```

2. **Configure webR repository in _quarto.yml:**
   ```yaml
   webr:
     base-url: https://repo.r-wasm.org
     packages:
       - shiny
     repos:
       - https://johngavin.github.io/randomwalk/
   ```

3. **Test basic webR cell:**
   ```qmd
   ---
   title: Test
   filters:
     - webr
   ---

   ```{webr-r}
   1 + 1
   ```
   ```

### Phase 2: Convert dynamic_broadcasting.qmd (2-3 hours)

**Current structure:**
- Single Shinylive app with 500+ lines
- Full reactive Shiny UI
- Server-side logic

**Proposed structure:**
- Introduction section (markdown)
- Setup cell (load packages)
- Parameter configuration cells
- Simulation execution cell
- Visualization cells
- Explanation cells between code

**Example conversion:**

```qmd
---
title: "Dynamic Grid Broadcasting"
format:
  html:
    code-fold: false
    toc: true
webr:
  packages: ['randomwalk', 'shiny']
  repos:
    - https://johngavin.github.io/randomwalk/
filters:
  - webr
---

# Dynamic Grid Broadcasting

## Setup

```{webr-r}
#| context: setup
library(randomwalk)
library(shiny)
```

## Configure Parameters

Try different values and re-run the cells below:

```{webr-r}
# Simulation parameters
grid_size <- 20
n_walkers <- 5
neighborhood <- "4-hood"
max_steps <- 10000
```

## Run Simulation

```{webr-r}
result <- run_simulation_async_dynamic(
  grid_size = grid_size,
  n_walkers = n_walkers,
  neighborhood = neighborhood,
  max_steps = max_steps,
  workers = 2,
  sync_mode = "dynamic"
)
```

## Visualize Results

```{webr-r}
plot_grid(result)
```

```{webr-r}
plot_walker_paths(result)
```

## Interactive Widget

```{webr-r}
shiny.ui::input_slider("n_walkers_widget", "Number of Walkers:", 1, 20, 5)
```
```

### Phase 3: Handle Complex UI (if needed)

If full reactive Shiny UI is required, use hybrid approach:

**Option A: Static plots + Interactive sliders**
```qmd
```{webr-r}
#| context: interactive
shiny.ui::panel(
  shiny.ui::input_slider("size", "Grid Size:", 5, 50, 20),
  shiny.ui::output_plot("grid_plot")
)

@reactive.Calc
def simulation():
  return run_simulation(grid_size = input.size())

@output
@render.plot
def grid_plot():
  plot_grid(simulation())
```
```

**Option B: Link to deployed Shiny app**
```markdown
For full interactive dashboard, use the deployed Shiny app:
[Launch Dashboard](https://johngavin.shinyapps.io/randomwalk-dashboard/)

Or run locally:
```r
randomwalk::run_dashboard()
```
```

### Phase 4: Testing (1 hour)

1. **Test package loading:**
   ```qmd
   ```{webr-r}
   library(randomwalk)
   packageVersion("randomwalk")
   ```
   ```

2. **Test all functions:**
   ```qmd
   ```{webr-r}
   # Test basic simulation
   sim <- run_simulation(grid_size = 10, n_walkers = 3)
   plot_grid(sim)
   ```
   ```

3. **Test in multiple browsers:**
   - Chrome
   - Firefox
   - Safari

### Phase 5: Deploy (15 minutes)

1. **Rebuild vignettes:**
   ```bash
   quarto render vignettes/dynamic_broadcasting.qmd
   ```

2. **Commit and push:**
   ```r
   gert::git_add("vignettes/dynamic_broadcasting.qmd")
   gert::git_add("docs/articles/dynamic_broadcasting.html")
   gert::git_commit("Migrate dynamic_broadcasting to quarto-webr")
   gert::git_push()
   ```

3. **Verify deployment:**
   ```bash
   curl -s "https://johngavin.github.io/randomwalk/articles/dynamic_broadcasting.html" | \
     grep -A 5 "webr-r"
   ```

## Advantages of Quarto-WebR

### 1. No Service Worker Required
- ✅ Avoids registration failures
- ✅ No scope/CORS issues
- ✅ Simpler browser compatibility

### 2. Easier Package Management
- ✅ YAML configuration (no runtime webr:: calls)
- ✅ Pre-loading during page initialization
- ✅ Better error messages

### 3. Progressive Enhancement
- ✅ Each code cell independent
- ✅ Partial functionality if some cells fail
- ✅ Users can modify and experiment

### 4. Better Developer Experience
- ✅ Can rebuild from .qmd sources
- ✅ Clearer separation of concerns
- ✅ Easier to debug

### 5. Educational Value
- ✅ Users see actual code
- ✅ Can learn by modifying examples
- ✅ Step-by-step execution

## Disadvantages vs Shinylive

### 1. Limited Reactivity
- ❌ No full Shiny server-side logic
- ❌ Limited reactive UI components
- ⚠️ Workaround: Use shiny.ui widgets or link to deployed apps

### 2. Different UX Paradigm
- ❌ Not a "single app" experience
- ❌ Users need to understand code cells
- ⚠️ Workaround: Clear instructions, good defaults

### 3. Performance
- ❌ Re-running cells recomputes from scratch
- ❌ No server-side caching
- ⚠️ Workaround: Keep simulations small in examples

## Recommended Hybrid Strategy

### For randomwalk package:

1. **Simple vignettes (getting started, examples):**
   - Use quarto-webr
   - Interactive code cells
   - Focus on learning

2. **Complex dashboards:**
   - Deploy actual Shiny apps to shinyapps.io
   - Link from vignettes
   - Embed screenshots/demos

3. **dynamic_broadcasting.qmd specifically:**
   - Convert to quarto-webr with simplified examples
   - Add link to full dashboard on shinyapps.io
   - Keep code visible for education

## Implementation Checklist

- [ ] Install quarto-webr extension
- [ ] Configure _quarto.yml with webR repos
- [ ] Create test vignette to verify setup
- [ ] Convert dynamic_broadcasting.qmd
- [ ] Test in multiple browsers
- [ ] Deploy to GitHub Pages
- [ ] Update AGENTS.md with quarto-webr workflow
- [ ] Document in WIKI_SHINYLIVE_LESSONS_LEARNED.md
- [ ] Consider deploying full Shiny apps to shinyapps.io

## Resources

- **Quarto-WebR docs:** https://quarto-webr.thecoatlessprofessor.com/
- **Custom repos example:** https://quarto-webr.thecoatlessprofessor.com/demos/qwebr-custom-repository.html
- **Interactive widgets:** https://quarto-webr.thecoatlessprofessor.com/demos/qwebr-interactive-widgets.html
- **GitHub repo:** https://github.com/coatless/quarto-webr

## Estimated Timeline

- **Phase 1 (Setup):** 30 minutes
- **Phase 2 (Convert vignette):** 2-3 hours
- **Phase 3 (Handle UI):** 1-2 hours (if needed)
- **Phase 4 (Testing):** 1 hour
- **Phase 5 (Deploy):** 15 minutes

**Total: 4-6 hours** for complete migration

## Next Steps

1. Review this plan and approve approach
2. Install quarto-webr extension
3. Create proof-of-concept test vignette
4. Decide on full dashboard strategy (shinyapps.io vs simplified)
5. Proceed with migration
