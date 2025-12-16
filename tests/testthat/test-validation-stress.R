# Stress test for grid validation
# Only runs locally (skipped on CRAN/CI)

test_that("grid validation passes on repeated medium simulations", {
  skip_on_cran()
  skip_on_ci()

  # Run same config 100 times
  n_runs <- 100
  grid_size <- 20
  n_walkers <- 15

  for (i in seq_len(n_runs)) {
    result <- run_simulation(quiet = TRUE, 
      grid_size = grid_size,
      n_walkers = n_walkers,
      validate_strict = TRUE,  # Would error on any isolation
      validate_percent = 5     # Validate every 5%
    )

    # Verify completed successfully
    expect_equal(length(result$walkers), n_walkers)
  }
})

test_that("grid validation passes on various grid sizes", {
  skip_on_cran()
  skip_on_ci()

  # Test different sizes with strict validation
  for (size in c(10, 20, 30, 50)) {
    for (workers in c(0, 1, 2)) {
      result <- run_simulation(quiet = TRUE, 
        grid_size = size,
        n_walkers = ceiling(size * 0.1),
        workers = workers,
        validate_strict = TRUE
      )

      expect_equal(result$parameters$grid_size, size)
    }
  }
})
