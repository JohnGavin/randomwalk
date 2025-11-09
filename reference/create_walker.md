# Create a Walker

Creates a walker object for the random walk simulation.

## Usage

``` r
create_walker(id, pos, grid_size)
```

## Arguments

- id:

  Integer. Unique identifier for the walker.

- pos:

  Integer vector of length 2 (row, col). Starting position.

- grid_size:

  Integer. Size of the grid.

## Value

A list representing the walker with components:

- id:

  Walker identifier

- pos:

  Current position

- steps:

  Number of steps taken

- active:

  Logical indicating if walker is still active

- termination_reason:

  Character string if terminated, NULL otherwise

- path:

  List of all positions visited

## Examples

``` r
walker <- create_walker(1, c(5, 5), 10)
```
