test_that("initialize_grid creates correct grid size", {
  grid <- initialize_grid(10)
  expect_equal(nrow(grid), 10)
  expect_equal(ncol(grid), 10)
})

test_that("initialize_grid sets center pixel to black by default", {
  grid <- initialize_grid(10)
  expect_equal(grid[5, 5], 1)
})

test_that("initialize_grid can create grid without center black", {
  grid <- initialize_grid(10, center_black = FALSE)
  expect_equal(sum(grid), 0)
})

test_that("initialize_grid validates input", {
  expect_error(initialize_grid(2), "Grid size must be")
  expect_error(initialize_grid(-1), "Grid size must be")
  expect_error(initialize_grid("10"), "Grid size must be")
})

test_that("is_within_bounds works correctly", {
  expect_true(is_within_bounds(c(1, 1), 10))
  expect_true(is_within_bounds(c(10, 10), 10))
  expect_true(is_within_bounds(c(5, 5), 10))

  expect_false(is_within_bounds(c(0, 5), 10))
  expect_false(is_within_bounds(c(11, 5), 10))
  expect_false(is_within_bounds(c(5, 0), 10))
  expect_false(is_within_bounds(c(5, 11), 10))
})

test_that("wrap_position wraps correctly", {
  expect_equal(wrap_position(c(0, 5), 10), c(10, 5))
  expect_equal(wrap_position(c(11, 5), 10), c(1, 5))
  expect_equal(wrap_position(c(5, 0), 10), c(5, 10))
  expect_equal(wrap_position(c(5, 11), 10), c(5, 1))
  expect_equal(wrap_position(c(5, 5), 10), c(5, 5))
})

test_that("get_pixel retrieves correct values with terminate boundary", {
  grid <- initialize_grid(10)

  expect_equal(get_pixel(grid, c(5, 5)), 1)
  expect_equal(get_pixel(grid, c(1, 1)), 0)
  expect_true(is.na(get_pixel(grid, c(0, 5))))
  expect_true(is.na(get_pixel(grid, c(11, 5))))
})

test_that("get_pixel handles wrap boundary", {
  grid <- initialize_grid(10)
  grid[10, 5] <- 1

  pixel <- get_pixel(grid, c(0, 5), boundary = "wrap")
  expect_equal(pixel, 1)
})

test_that("set_pixel_black works correctly", {
  grid <- initialize_grid(10)
  grid <- set_pixel_black(grid, c(3, 3))

  expect_equal(grid[3, 3], 1)
  expect_equal(count_black_pixels(grid), 2)  # center + new
})

test_that("set_pixel_black handles out of bounds with terminate", {
  grid <- initialize_grid(10)
  grid_modified <- set_pixel_black(grid, c(11, 5))

  expect_equal(count_black_pixels(grid_modified), 1)  # unchanged
})

test_that("set_pixel_black handles wrap boundary", {
  grid <- initialize_grid(10)
  grid <- set_pixel_black(grid, c(0, 5), boundary = "wrap")

  expect_equal(grid[10, 5], 1)
})

test_that("count_black_pixels counts correctly", {
  grid <- initialize_grid(10)
  expect_equal(count_black_pixels(grid), 1)

  grid[1, 1] <- 1
  grid[2, 2] <- 1
  expect_equal(count_black_pixels(grid), 3)
})

test_that("get_black_percentage calculates correctly", {
  grid <- initialize_grid(10)
  expect_equal(get_black_percentage(grid), 1)

  grid[1:10, 1:5] <- 1  # Half the grid
  expect_equal(get_black_percentage(grid), 50)
})
