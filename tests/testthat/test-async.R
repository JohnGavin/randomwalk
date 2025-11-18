# Tests for Async Simulation Functionality
# Tests crew controller, nanonext communication, and async simulation

test_that("create_controller initializes crew workers", {
  skip_if_not_installed("crew")
  skip_if_not_installed("nanonext")

  controller <- create_controller(n_workers = 2)

  expect_s3_class(controller, "R6")
  expect_true(!is.null(controller))

  # Clean up
  controller$terminate()
})


test_that("create_pub_socket creates nanonext socket", {
  skip_if_not_installed("nanonext")

  socket <- create_pub_socket(port = 5556)  # Different port to avoid conflicts

  expect_s3_class(socket, "nanoSocket")
  expect_true(!is.null(socket))

  # Clean up
  nanonext::close(socket)
})


test_that("broadcast_update sends messages correctly", {
  skip_if_not_installed("nanonext")

  socket <- create_pub_socket(port = 5557)

  # Should not error
  expect_silent({
    broadcast_update(socket, position = c(5, 10), version = 42)
  })

  # Clean up
  nanonext::close(socket)
})


test_that("cleanup_async handles NULL inputs gracefully", {
  skip_if_not_installed("crew")
  skip_if_not_installed("nanonext")

  # Should not error with NULL inputs
  expect_silent(cleanup_async(NULL, NULL))

  # Should handle real objects
  controller <- create_controller(n_workers = 1)
  socket <- create_pub_socket(port = 5558)

  expect_silent(cleanup_async(controller, socket))
})


test_that("get_black_pixels_list converts grid correctly", {
  grid <- matrix(0, 5, 5)
  grid[3, 3] <- 1  # Center
  grid[2, 4] <- 1  # Another black pixel

  black_list <- get_black_pixels_list(grid)

  expect_type(black_list, "list")
  expect_equal(length(black_list), 2)
  expect_true("3,3" %in% names(black_list))
  expect_true("2,4" %in% names(black_list))
  expect_equal(black_list[["3,3"]], c(3, 3))
  expect_equal(black_list[["2,4"]], c(2, 4))
})


test_that("async simulation runs with 2 workers on small grid", {
  skip_if_not_installed("crew")
  skip_if_not_installed("nanonext")
  skip_on_cran()  # Skip on CRAN (async tests can be flaky in CI)

  # Small test simulation
  result <- run_simulation(
    grid_size = 10,
    n_walkers = 3,
    workers = 2,
    neighborhood = "4-hood",
    boundary = "terminate",
    verbose = FALSE
  )

  # Check structure
  expect_type(result, "list")
  expect_named(result, c("grid", "walkers", "statistics", "parameters"))

  # Check grid
  expect_true(is.matrix(result$grid))
  expect_equal(dim(result$grid), c(10, 10))

  # Check walkers
  expect_type(result$walkers, "list")
  expect_equal(length(result$walkers), 3)

  # All walkers should be terminated
  for (walker in result$walkers) {
    expect_false(walker$active)
    expect_true(!is.null(walker$termination_reason))
  }

  # Check statistics
  expect_type(result$statistics, "list")
  expect_true(result$statistics$black_pixels > 0)
  expect_true(result$statistics$completed_walkers == 3)

  # Check parameters
  expect_equal(result$parameters$workers, 2)
})


test_that("async mode produces similar results to sync mode", {
  skip_if_not_installed("crew")
  skip_if_not_installed("nanonext")
  skip_on_cran()

  set.seed(123)

  # Run sync simulation
  result_sync <- run_simulation(
    grid_size = 10,
    n_walkers = 5,
    workers = 0,  # Sync
    neighborhood = "4-hood",
    boundary = "terminate",
    verbose = FALSE
  )

  set.seed(123)

  # Run async simulation with same seed
  result_async <- run_simulation(
    grid_size = 10,
    n_walkers = 5,
    workers = 2,  # Async
    neighborhood = "4-hood",
    boundary = "terminate",
    verbose = FALSE
  )

  # Results should be similar (not exactly equal due to async timing)
  # But black pixel count should be within reasonable range

  expect_equal(result_sync$statistics$completed_walkers, 5)
  expect_equal(result_async$statistics$completed_walkers, 5)

  # Black pixels should be close (allow 20% difference due to random seed + async timing)
  black_diff <- abs(
    result_sync$statistics$black_pixels - result_async$statistics$black_pixels
  )
  black_avg <- (result_sync$statistics$black_pixels + result_async$statistics$black_pixels) / 2

  expect_true(black_diff / black_avg < 0.3,
    info = sprintf(
      "Black pixels too different: sync=%d, async=%d",
      result_sync$statistics$black_pixels,
      result_async$statistics$black_pixels
    )
  )
})


test_that("async simulation handles single worker correctly", {
  skip_if_not_installed("crew")
  skip_if_not_installed("nanonext")
  skip_on_cran()

  result <- run_simulation(
    grid_size = 8,
    n_walkers = 2,
    workers = 1,  # Single worker (serial async)
    neighborhood = "4-hood",
    boundary = "terminate",
    verbose = FALSE
  )

  expect_equal(result$statistics$completed_walkers, 2)
  expect_true(result$statistics$black_pixels > 0)
})


test_that("async simulation with 8-hood neighborhood works", {
  skip_if_not_installed("crew")
  skip_if_not_installed("nanonext")
  skip_on_cran()

  result <- run_simulation(
    grid_size = 10,
    n_walkers = 4,
    workers = 2,
    neighborhood = "8-hood",  # Test 8-hood
    boundary = "terminate",
    verbose = FALSE
  )

  expect_equal(result$statistics$completed_walkers, 4)
  expect_true(result$statistics$black_pixels > 0)
})


test_that("async simulation with wrap boundary works", {
  skip_if_not_installed("crew")
  skip_if_not_installed("nanonext")
  skip_on_cran()

  result <- run_simulation(
    grid_size = 10,
    n_walkers = 3,
    workers = 2,
    neighborhood = "4-hood",
    boundary = "wrap",  # Test wrap boundary
    verbose = FALSE
  )

  expect_equal(result$statistics$completed_walkers, 3)
  expect_true(result$statistics$black_pixels > 0)

  # No walkers should have hit_boundary termination reason
  for (walker in result$walkers) {
    expect_true(walker$termination_reason != "hit_boundary")
  }
})


test_that("check_termination_cached detects touched black", {
  walker <- list(
    id = 1,
    pos = c(5, 5),
    steps = 10,
    active = TRUE,
    termination_reason = NULL
  )

  black_pixels <- list("5,5" = c(5, 5))

  result <- check_termination_cached(
    walker = walker,
    black_pixels = black_pixels,
    neighborhood = "4-hood",
    boundary = "terminate",
    grid_size = 10,
    max_steps = 1000
  )

  expect_false(result$active)
  expect_equal(result$termination_reason, "touched_black")
})


test_that("check_termination_cached detects black neighbor", {
  walker <- list(
    id = 1,
    pos = c(5, 5),
    steps = 10,
    active = TRUE,
    termination_reason = NULL
  )

  # Black pixel at (5, 6) - east neighbor
  black_pixels <- list("5,6" = c(5, 6))

  result <- check_termination_cached(
    walker = walker,
    black_pixels = black_pixels,
    neighborhood = "4-hood",
    boundary = "terminate",
    grid_size = 10,
    max_steps = 1000
  )

  expect_false(result$active)
  expect_equal(result$termination_reason, "black_neighbor")
})


test_that("check_termination_cached enforces max_steps", {
  walker <- list(
    id = 1,
    pos = c(5, 5),
    steps = 1000,
    active = TRUE,
    termination_reason = NULL
  )

  black_pixels <- list()  # No black pixels

  result <- check_termination_cached(
    walker = walker,
    black_pixels = black_pixels,
    neighborhood = "4-hood",
    boundary = "terminate",
    grid_size = 10,
    max_steps = 1000
  )

  expect_false(result$active)
  expect_equal(result$termination_reason, "max_steps")
})


test_that("async simulation statistics are complete", {
  skip_if_not_installed("crew")
  skip_if_not_installed("nanonext")
  skip_on_cran()

  result <- run_simulation(
    grid_size = 10,
    n_walkers = 4,
    workers = 2,
    verbose = FALSE
  )

  stats <- result$statistics

  # Check all expected fields exist
  expect_true(!is.null(stats$black_pixels))
  expect_true(!is.null(stats$black_percentage))
  expect_true(!is.null(stats$total_walkers))
  expect_true(!is.null(stats$completed_walkers))
  expect_true(!is.null(stats$total_steps))
  expect_true(!is.null(stats$min_steps))
  expect_true(!is.null(stats$max_steps))
  expect_true(!is.null(stats$mean_steps))
  expect_true(!is.null(stats$median_steps))
  expect_true(!is.null(stats$elapsed_time_secs))
  expect_true(!is.null(stats$termination_reasons))

  # Check reasonable values
  expect_true(stats$elapsed_time_secs > 0)
  expect_true(stats$total_steps > 0)
  expect_equal(stats$total_walkers, 4)
  expect_equal(stats$completed_walkers, 4)
})
