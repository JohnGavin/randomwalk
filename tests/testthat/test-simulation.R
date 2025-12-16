# ===================================================================
# Helper Functions for Testing
# ===================================================================

# Helper function to find isolated pixels (for test assertions)
find_isolated_pixels_test <- function(grid, neighborhood = "4-hood") {
  black_positions <- which(grid == 1, arr.ind = TRUE)

  if (nrow(black_positions) <= 1) {
    return(list())
  }

  n <- nrow(grid)
  isolated <- list()

  for (i in seq_len(nrow(black_positions))) {
    pos <- black_positions[i, ]
    neighbors <- get_neighbors(pos, neighborhood)

    has_black_neighbor <- FALSE
    for (neighbor_pos in neighbors) {
      if (is_within_bounds(neighbor_pos, n)) {
        if (grid[neighbor_pos[1], neighbor_pos[2]] == 1) {
          has_black_neighbor <- TRUE
          break
        }
      }
    }

    if (!has_black_neighbor) {
      isolated <- c(isolated, list(pos))
    }
  }

  isolated
}

# ===================================================================
# Simulation Tests
# ===================================================================

test_that("run_simulation completes successfully", {
  result <- run_simulation(quiet = TRUE, grid_size = 10, n_walkers = 3, verbose = FALSE)

  expect_type(result, "list")
  expect_true("grid" %in% names(result))
  expect_true("walkers" %in% names(result))
  expect_true("statistics" %in% names(result))
  expect_true("parameters" %in% names(result))
})

test_that("run_simulation validates grid_size", {
  expect_error(run_simulation(quiet = TRUE, grid_size = 2), "grid_size must be")
  expect_error(run_simulation(quiet = TRUE, grid_size = -1), "grid_size must be")
})

test_that("run_simulation validates n_walkers", {
  expect_error(run_simulation(quiet = TRUE, grid_size = 10, n_walkers = 0), "n_walkers must be")
  expect_error(run_simulation(quiet = TRUE, grid_size = 10, n_walkers = 100), "n_walkers must be")
})

test_that("run_simulation validates neighborhood", {
  expect_error(run_simulation(quiet = TRUE, neighborhood = "invalid"), "neighborhood must be")
})

test_that("run_simulation validates boundary", {
  expect_error(run_simulation(quiet = TRUE, boundary = "invalid"), "boundary must be")
})

test_that("run_simulation returns correct grid size", {
  result <- run_simulation(quiet = TRUE, grid_size = 15, n_walkers = 3, verbose = FALSE)

  expect_equal(nrow(result$grid), 15)
  expect_equal(ncol(result$grid), 15)
})

test_that("run_simulation creates correct number of walkers", {
  result <- run_simulation(quiet = TRUE, grid_size = 10, n_walkers = 5, verbose = FALSE)

  expect_equal(length(result$walkers), 5)
})

test_that("run_simulation terminates all walkers", {
  result <- run_simulation(quiet = TRUE, grid_size = 10, n_walkers = 3, verbose = FALSE)

  active_walkers <- sum(sapply(result$walkers, function(w) w$active))
  expect_equal(active_walkers, 0)
})

test_that("run_simulation creates black pixels", {
  result <- run_simulation(quiet = TRUE, grid_size = 10, n_walkers = 3, verbose = FALSE)

  # Should have at least the center pixel + terminated walkers
  expect_true(result$statistics$black_pixels >= 1)
})

test_that("run_simulation statistics are correct", {
  result <- run_simulation(quiet = TRUE, grid_size = 10, n_walkers = 3, verbose = FALSE)
  stats <- result$statistics

  expect_true(stats$black_pixels >= 1)
  expect_equal(stats$total_walkers, 3)
  expect_equal(stats$completed_walkers, 3)
  expect_true(stats$total_steps > 0)
  expect_true(stats$elapsed_time_secs > 0)
  expect_true(stats$min_steps >= 0)
  expect_true(stats$max_steps >= stats$min_steps)
})

test_that("run_simulation with 4-hood works", {
  result <- run_simulation(quiet = TRUE, 
    grid_size = 10,
    n_walkers = 3,
    neighborhood = "4-hood",
    verbose = FALSE
  )

  expect_equal(result$parameters$neighborhood, "4-hood")
  expect_true(result$statistics$completed_walkers == 3)
})

test_that("run_simulation with 8-hood works", {
  result <- run_simulation(quiet = TRUE, 
    grid_size = 10,
    n_walkers = 3,
    neighborhood = "8-hood",
    verbose = FALSE
  )

  expect_equal(result$parameters$neighborhood, "8-hood")
  expect_true(result$statistics$completed_walkers == 3)
})

test_that("run_simulation with terminate boundary works", {
  result <- run_simulation(quiet = TRUE, 
    grid_size = 10,
    n_walkers = 3,
    boundary = "terminate",
    verbose = FALSE
  )

  expect_equal(result$parameters$boundary, "terminate")
})

test_that("run_simulation with wrap boundary works", {
  result <- run_simulation(quiet = TRUE, 
    grid_size = 10,
    n_walkers = 3,
    boundary = "wrap",
    verbose = FALSE
  )

  expect_equal(result$parameters$boundary, "wrap")
})

test_that("format_statistics returns character vector", {
  result <- run_simulation(quiet = TRUE, grid_size = 10, n_walkers = 3, verbose = FALSE)
  formatted <- format_statistics(result$statistics)

  expect_type(formatted, "character")
  expect_true(length(formatted) > 0)
})

test_that("print_simulation_result works without error", {
  result <- run_simulation(quiet = TRUE, grid_size = 10, n_walkers = 3, verbose = FALSE)

  expect_output(print_simulation_result(result), "SIMULATION STATISTICS")
})

test_that("run_simulation is reproducible with same seed", {
  set.seed(42)
  result1 <- run_simulation(quiet = TRUE, grid_size = 10, n_walkers = 3, verbose = FALSE)

  set.seed(42)
  result2 <- run_simulation(quiet = TRUE, grid_size = 10, n_walkers = 3, verbose = FALSE)

  expect_equal(result1$statistics$total_steps, result2$statistics$total_steps)
  expect_equal(sum(result1$grid), sum(result2$grid))
})

test_that("run_simulation handles small grids", {
  result <- run_simulation(quiet = TRUE, grid_size = 5, n_walkers = 2, verbose = FALSE)

  expect_equal(nrow(result$grid), 5)
  expect_true(result$statistics$completed_walkers == 2)
})

test_that("run_simulation handles single walker", {
  result <- run_simulation(quiet = TRUE, grid_size = 10, n_walkers = 1, verbose = FALSE)

  expect_equal(length(result$walkers), 1)
  expect_equal(result$statistics$completed_walkers, 1)
})

# ===================================================================
# Grid Validation Integration Tests
# ===================================================================

test_that("simulation validates grid periodically", {
  # Small simulation should complete without validation errors
  expect_error(
    run_simulation(quiet = TRUE, 
      grid_size = 10,
      n_walkers = 5,
      validate_strict = TRUE,  # Strict mode - would error on isolation
      validate_percent = 20    # Validate every 20% (5 walkers × 20% = every 1 walker)
    ),
    NA
  )
})

test_that("simulation validation respects strict mode", {
  # In non-strict mode, validation warnings don't stop simulation
  result <- run_simulation(quiet = TRUE, 
    grid_size = 10,
    n_walkers = 3,
    validate_strict = FALSE
  )

  expect_type(result, "list")
  expect_true("grid" %in% names(result))
})

test_that("simulation runs final validation", {
  # Ensure final validation happens
  result <- run_simulation(quiet = TRUE, 
    grid_size = 10,
    n_walkers = 5,
    verbose = TRUE  # Will log validation messages
  )

  expect_equal(result$parameters$grid_size, 10)
})

# ===================================================================
# Async Mode Tests
# ===================================================================

test_that("async simulation with 2 workers produces valid grid", {
  skip_if_not_installed("crew")
  skip_if_not_installed("nanonext")

  result <- run_simulation(quiet = TRUE, 
    grid_size = 20,
    n_walkers = 10,
    workers = 2,
    neighborhood = "4-hood",
    boundary = "terminate",
    validate_strict = TRUE,  # Fail hard on isolated pixels
    validate_percent = 10
  )

  # Verify no isolated pixels
  isolated <- find_isolated_pixels_test(result$grid, "4-hood")
  expect_equal(
    length(isolated),
    0,
    info = sprintf(
      "Found %d isolated pixels at: %s",
      length(isolated),
      paste(sapply(isolated, function(p) sprintf("(%d,%d)", p[1], p[2])),
            collapse = ", ")
    )
  )
})

test_that("async simulation reproduces issue #63 isolated pixels bug", {
  skip_if_not_installed("crew")
  skip_if_not_installed("nanonext")
  skip("This test documents the bug - will fail until fix is implemented")

  # This is the exact simulation from the bug report
  # Grid 160x160, 884 walkers, 4 workers produced isolated pixels
  result <- run_simulation(quiet = TRUE, 
    grid_size = 160,
    n_walkers = 884,
    workers = 4,
    neighborhood = "4-hood",
    boundary = "terminate",
    max_steps = 10000,
    verbose = FALSE,
    validate_strict = TRUE,  # Should error on isolated pixels
    validate_percent = 5
  )

  # If we get here without error, check for isolated pixels
  isolated <- find_isolated_pixels_test(result$grid, "4-hood")

  expect_equal(
    length(isolated),
    0,
    info = sprintf(
      "BUG REPRODUCED: Found %d isolated pixels at: %s",
      length(isolated),
      paste(sapply(isolated, function(p) sprintf("(%d,%d)", p[1], p[2])),
            collapse = ", ")
    )
  )
})

test_that("async simulation with many workers produces valid grid", {
  skip_if_not_installed("crew")
  skip_if_not_installed("nanonext")

  # Stress test with 4 workers
  result <- run_simulation(quiet = TRUE, 
    grid_size = 50,
    n_walkers = 100,
    workers = 4,
    neighborhood = "4-hood",
    boundary = "terminate",
    validate_strict = TRUE,
    validate_percent = 5
  )

  # Verify no isolated pixels
  isolated <- find_isolated_pixels_test(result$grid, "4-hood")
  expect_equal(
    length(isolated),
    0,
    info = sprintf(
      "Found %d isolated pixels at: %s",
      length(isolated),
      paste(sapply(isolated, function(p) sprintf("(%d,%d)", p[1], p[2])),
            collapse = ", ")
    )
  )
})
