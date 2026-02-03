# Validate Grid State for Isolated Pixels

Checks that no black pixel is completely isolated (has no black
neighbors). An isolated pixel indicates a bug in the simulation logic.
Also validates that the grid has at least one black pixel, as the number
of black pixels should increase monotonically from the initial center
pixel.

## Usage

``` r
validate_no_isolated_pixels(
  grid,
  neighborhood = "4-hood",
  boundary = "terminate",
  strict = FALSE,
  last_black_positions = NULL,
  walkers = NULL,
  step_count = NULL
)
```

## Arguments

- grid:

  Numeric matrix representing the grid.

- neighborhood:

  Character, "4-hood" or "8-hood" for neighbor checking. Default is
  "4-hood".

- boundary:

  Character. "terminate" or "wrap". Default "terminate".

- strict:

  Logical, if TRUE throws error on isolation, if FALSE logs warning.
  Default FALSE.

- last_black_positions:

  Matrix of previously validated black pixel positions (optional). Used
  for optimization - only checks NEW pixels since last validation.
  Default NULL (checks all pixels).

- walkers:

  List of walker objects (optional). Used for detailed debugging output
  when isolation detected. Default NULL.

- step_count:

  Integer simulation step count (optional). Used for detailed debugging
  output when isolation detected. Default NULL.

## Value

Logical, TRUE if valid (no isolated pixels), FALSE otherwise.

## Examples

``` r
grid <- initialize_grid(10)
#> INFO [2026-02-03 16:23:12] Initializing grid of size 10x10
validate_no_isolated_pixels(grid)  # TRUE for single center pixel initially
#> [1] TRUE

# Create invalid grid with isolated pixel
bad_grid <- initialize_grid(10, center_black = FALSE)
#> INFO [2026-02-03 16:23:12] Initializing grid of size 10x10
bad_grid[3, 3] <- 1
validate_no_isolated_pixels(bad_grid)  # FALSE - isolated pixel
#> [1] TRUE
```
