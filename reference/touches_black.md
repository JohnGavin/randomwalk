# Check if Walker Touches a Black Pixel

Checks if the walker's current position is on a black pixel.

## Usage

``` r
touches_black(walker, grid, boundary = "terminate")
```

## Arguments

- walker:

  List. Walker object.

- grid:

  Numeric matrix. The simulation grid.

- boundary:

  Character. Boundary condition ("terminate" or "wrap").

## Value

Logical. TRUE if walker is on a black pixel.
