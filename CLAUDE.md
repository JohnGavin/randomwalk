# randomwalk — Random walk simulations

## ctx.yaml Package Context

**Central cache:** `~/docs_gh/proj/data/llm/content/inst/ctx/external/`

All ctx.yaml files are version-stamped (`{pkg}@{version}.ctx.yaml`) and stored centrally. To check coverage:

```r
source("~/docs_gh/llm/R/tar_plans/plan_pkgctx.R")
ctx_audit("DESCRIPTION")   # report gaps
ctx_sync("DESCRIPTION")    # generate missing
```

**DO NOT** look for ctx files in `.claude/context/` or `inst/ctx/` — use the central cache only.

## Project Rules

- set.seed required, L'Ecuyer-CMRG for parallel, boundary conditions
- Vignettes: zero inline computation, all via `safe_tar_read()`
- DuckDB: use `duckplyr` not raw SQL
