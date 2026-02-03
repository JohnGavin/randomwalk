# Detect WebR Environment

Checks if code is running in WebR/WebAssembly environment. Uses the same
detection as existing vignettes.

## Usage

``` r
is_webr()
```

## Value

Logical. TRUE if in WebR, FALSE otherwise

## Details

Detection methods:

1.  `.webr_env` object in global environment (set by WebR runtime)

2.  `WEBR="1"` environment variable

## References

- WebR documentation: https://docs.r-wasm.org/webr/latest/

- Existing usage: vignettes/dynamic_broadcasting.qmd:50-51

## Examples

``` r
if (FALSE) { # \dontrun{
if (is_webr()) {
  message("Running in WebR/browser environment")
} else {
  message("Running in native R")
}
} # }
```
