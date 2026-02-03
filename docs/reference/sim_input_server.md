# Simulation Input Module Server

Server logic for handling simulation input parameters and validation.

## Usage

``` r
sim_input_server(id)
```

## Arguments

- id:

  Character string. Module namespace ID.

## Value

A reactive list containing:

- params:

  Reactive list of validated simulation parameters

- run_trigger:

  Reactive trigger for simulation execution
