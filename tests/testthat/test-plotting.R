test_that("plot_grid creates a plot without errors", {
  # Create a simple simulation result
  result <- run_simulation(
    grid_size = 10,
    n_walkers = 3,
    neighborhood = "4-hood",
    boundary = "terminate",
    workers = 1
  )
  
  # Test that plot_grid runs without error
  expect_silent(plot_grid(result))
  
  # Test with custom parameters
  expect_silent(plot_grid(result, 
                          main = "Custom Title",
                          col_palette = c("lightblue", "darkred"),
                          add_grid = FALSE))
})

test_that("plot_grid validates input", {
  # Test with invalid input
  expect_error(plot_grid(list()), "Invalid result object")
  expect_error(plot_grid(NULL), "Invalid result object")
  expect_error(plot_grid(matrix(0, 10, 10)), "Invalid result object")
})

test_that("plot_walker_paths creates a plot without errors", {
  # Create a simple simulation result
  result <- run_simulation(
    grid_size = 10,
    n_walkers = 3,
    neighborhood = "4-hood",
    boundary = "terminate",
    workers = 1
  )
  
  # Test that plot_walker_paths runs without error
  expect_silent(plot_walker_paths(result))
  
  # Test with custom parameters
  expect_silent(plot_walker_paths(result,
                                  main = "Custom Title",
                                  colors = c("red", "blue", "green"),
                                  add_grid = FALSE,
                                  legend = FALSE))
})

test_that("plot_walker_paths handles color recycling", {
  result <- run_simulation(
    grid_size = 10,
    n_walkers = 5,
    neighborhood = "4-hood",
    boundary = "terminate",
    workers = 1
  )
  
  # Test with fewer colors than walkers (should recycle and log warning)
  expect_output(plot_walker_paths(result, colors = c("red", "blue")),
                "Not enough colors provided, recycling colors")
})

test_that("plot_walker_paths validates input", {
  # Test with invalid input
  expect_error(plot_walker_paths(list()), "Invalid result object")
  expect_error(plot_walker_paths(NULL), "Invalid result object")
})

test_that("plot_simulation creates combined plots without errors", {
  result <- run_simulation(
    grid_size = 10,
    n_walkers = 3,
    neighborhood = "4-hood",
    boundary = "terminate",
    workers = 1
  )
  
  # Test combined plot
  old_par <- plot_simulation(result)
  
  # Check that par settings were returned
  expect_type(old_par, "list")
  expect_true("mfrow" %in% names(old_par))
})

test_that("plotting functions work with different grid sizes", {
  # Small grid
  result_small <- run_simulation(grid_size = 5, n_walkers = 2, workers = 1)
  expect_silent(plot_grid(result_small))
  expect_silent(plot_walker_paths(result_small))
  
  # Larger grid
  result_large <- run_simulation(grid_size = 30, n_walkers = 10, workers = 1)
  expect_silent(plot_grid(result_large))
  expect_silent(plot_walker_paths(result_large))
})

test_that("plotting functions work with different boundary conditions", {
  # Terminate boundary
  result_term <- run_simulation(
    grid_size = 10,
    n_walkers = 3,
    boundary = "terminate",
    workers = 1
  )
  expect_silent(plot_walker_paths(result_term))
  
  # Wrap boundary
  result_wrap <- run_simulation(
    grid_size = 10,
    n_walkers = 3,
    boundary = "wrap",
    workers = 1
  )
  expect_silent(plot_walker_paths(result_wrap))
})

test_that("plot_walker_paths handles walkers with different termination reasons", {
  # Run simulation that should produce both termination types
  result <- run_simulation(
    grid_size = 15,
    n_walkers = 5,
    boundary = "terminate",
    workers = 1
  )
  
  # Check that we have mixed termination reasons
  termination_reasons <- sapply(result$walkers, function(w) w$termination_reason)
  
  # Plot should handle both types
  expect_silent(plot_walker_paths(result))
})

test_that("plotting functions handle edge cases", {
  # Single walker
  result_single <- run_simulation(grid_size = 10, n_walkers = 1, workers = 1)
  expect_silent(plot_grid(result_single))
  expect_silent(plot_walker_paths(result_single))
  expect_silent(plot_simulation(result_single))
})
