# Create Mirai-based Controller (WebAssembly Compatible)

Creates a mirai-based async controller for WebAssembly environments
where crew is not available. Provides crew-compatible interface.

## Usage

``` r
create_mirai_controller(n_workers = 2, seconds_idle = 60)
```

## Arguments

- n_workers:

  Integer. Number of mirai daemons to create (default: 2).

- seconds_idle:

  Numeric. Ignored (no mirai equivalent). Kept for interface
  compatibility with crew.

## Value

List with crew-compatible interface:

- `push(name, command, data, globals, packages)`: Submit task

- `pop(scale)`: Retrieve completed task

- `terminate()`: Shutdown daemons

## Details

This function provides a crew-compatible interface using mirai instead
of crew. It's automatically used when running in WebR/WebAssembly
(detected by
[`is_webr()`](https://johngavin.github.io/randomwalk/reference/is_webr.md)).

The mirai backend uses:

- [`mirai::daemons()`](https://mirai.r-lib.org/reference/daemons.html)
  for worker management

- [`mirai::mirai()`](https://mirai.r-lib.org/reference/mirai.html) for
  task submission

- Blocking `mirai[]` for task retrieval

## Examples

``` r
if (FALSE) { # \dontrun{
# Create mirai controller
controller <- create_mirai_controller(n_workers = 2)

# Submit task (crew-compatible interface)
controller$push(
  name = "task1",
  command = sum(x),
  data = list(),
  globals = list(x = 1:10),
  packages = character()
)

# Retrieve result
result <- controller$pop()

# Clean up
controller$terminate()
} # }
```
