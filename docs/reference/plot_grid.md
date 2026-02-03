# Plot Final Grid State

Visualizes the final state of the simulation grid, showing black pixels
that formed during the random walk simulation. Returns a ggplot2 object
for display via targets pipeline.

## Usage

``` r
plot_grid(
  result,
  main = NULL,
  col_palette = c("white", "black"),
  show_legend = FALSE
)

# S3 method for class 'randomwalk_result'
plot(x, ...)
```

## Arguments

- result:

  A simulation result object returned by
  [`run_simulation`](https://johngavin.github.io/randomwalk/reference/run_simulation.md)

- main:

  Character string for the plot title. If NULL (default), generates an
  informative title with statistics: black pixels, collisions, walkers,
  time.

- col_palette:

  A vector of two colors for white (0) and black (1) pixels. Default is
  c("white", "black")

- show_legend:

  Logical. If FALSE, hides the legend. Default is FALSE to save space.

- x:

  A simulation result object (same as `result`)

- ...:

  Additional arguments passed to `plot_grid`

## Value

A ggplot2 object that can be displayed or saved

## Examples

``` r
if (FALSE) { # \dontrun{
result <- run_simulation(grid_size = 20, n_walkers = 8)
p <- plot_grid(result)
print(p)  # Display the plot with auto-generated title

# Custom title
p <- plot_grid(result, main = "My Custom Title")

# With legend
p <- plot_grid(result, show_legend = TRUE)
} # }
```
