# Walker Paths Plotting Analysis - Step by Step

## Current Implementation Problems

### The Code Flow (Lines 862-946):

1. **Walker Selection (Lines 862-865)**:
```r
walker_indices <- unique(c(
  if(first_n > 0) 1:first_n else NULL,
  if(last_n > 0) (n_walkers - last_n + 1):n_walkers else NULL
))
```
**PROBLEM**: When last_n changes, the indices change. For example:
- last_n=1: indices = [20]
- last_n=2: indices = [19, 20]
- last_n=3: indices = [18, 19, 20]

2. **Walker Filtering (Line 869)**:
```r
filtered_walkers <- walkers_ordered[walker_indices]
```
**PROBLEM**: The ORDER in filtered_walkers changes as indices change.

3. **Color Assignment (Line 889)**:
```r
path_colors <- rep(distinct_colors, length.out = length(filtered_walkers))
```
**CRITICAL BUG**: Colors are assigned by POSITION in filtered_walkers, not by walker ID!
- Walker 20 is color[1] when last_n=1
- Walker 20 is color[2] when last_n=2 (Walker 19 becomes color[1])
- Walker 20 is color[3] when last_n=3

This explains the color chaos!

## Why Paths Are Missing

Looking at lines 900-911:
```r
if (!is.null(walker$path) && length(walker$path) > 0) {
  path_matrix <- do.call(rbind, walker$path)
  all_paths[[i]] <- list(
    x = path_matrix[, 2],
    y = path_matrix[, 1],
    col = path_colors[i]
  )
}
```

**POTENTIAL ISSUE**: The list index `all_paths[[i]]` may have gaps if some walkers don't have paths, causing the for loop in lines 925-930 to skip entries.

## Why Only Some Paths Show

The path drawing uses dots:
```r
points(path_data$x, path_data$y, pch = 16, col = path_data$col, cex = 0.8)
```

**HYPOTHESIS**: In WebR/Shinylive, overlapping points might not render properly. If multiple walkers have similar paths, later points might overwrite earlier ones.

## The Fix Needed

### 1. Stable Color Assignment by Walker ID
```r
# Create a stable color map based on walker termination order
color_map <- list()
all_walker_orders <- sapply(walkers_ordered, function(w) w$termination_order)
for (i in seq_along(all_walker_orders)) {
  color_map[[all_walker_orders[i]]] <- distinct_colors[(i-1) %% length(distinct_colors) + 1]
}

# Use stable colors
for (i in seq_along(filtered_walkers)) {
  walker <- filtered_walkers[[i]]
  walker_color <- color_map[[walker$termination_order]]
  # ... use walker_color consistently
}
```

### 2. Ensure All Paths Render
```r
# Use named lists to avoid index issues
all_paths <- list()
for (i in seq_along(filtered_walkers)) {
  walker_id <- paste0("walker_", walker$termination_order)
  all_paths[[walker_id]] <- ...
}
```

### 3. Debug Path Data
Add logging to verify:
- How many walkers have paths?
- Are path matrices valid?
- Do coordinates fall within plot bounds?

## Unit Tests Needed

```r
test_that("walker colors remain stable when selection changes", {
  # Create mock walkers
  walkers <- list(
    list(termination_order = 1, path = list(c(1,1), c(1,2))),
    list(termination_order = 2, path = list(c(2,1), c(2,2))),
    list(termination_order = 3, path = list(c(3,1), c(3,2)))
  )

  # Get colors for last_n = 1
  colors1 <- get_walker_colors(walkers, last_n = 1)

  # Get colors for last_n = 2
  colors2 <- get_walker_colors(walkers, last_n = 2)

  # Walker 3 should have same color in both
  expect_equal(colors1[["3"]], colors2[["3"]])
})

test_that("all walker paths are included in plot data", {
  walkers <- create_test_walkers(n = 10)
  plot_data <- prepare_walker_plot_data(walkers, first_n = 5, last_n = 5)

  expect_equal(length(plot_data$paths), 10)
  expect_true(all(sapply(plot_data$paths, function(p) !is.null(p))))
})
```

## Next Steps

1. Implement stable color mapping by walker ID
2. Add comprehensive logging
3. Create minimal test case
4. Use lines() or segments() instead of points()
5. Test with different n_walkers values