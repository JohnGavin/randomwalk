# Move Walker One Step

Moves the walker one random step in the neighborhood.

## Usage

``` r
step_walker(
  walker,
  neighborhood = c("4-hood", "8-hood"),
  boundary = c("terminate", "wrap")
)
```

## Arguments

- walker:

  List. Walker object.

- neighborhood:

  Character. "4-hood" or "8-hood".

- boundary:

  Character. "terminate" or "wrap".

## Value

Modified walker object.
