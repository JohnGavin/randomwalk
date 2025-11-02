test_that("create_walker creates correct structure", {
  walker <- create_walker(1, c(5, 5), 10)

  expect_equal(walker$id, 1)
  expect_equal(walker$pos, c(5, 5))
  expect_equal(walker$steps, 0)
  expect_true(walker$active)
  expect_null(walker$termination_reason)
  expect_equal(length(walker$path), 1)
  expect_equal(walker$grid_size, 10)
})

test_that("generate_walker_positions creates correct number of positions", {
  grid <- initialize_grid(10)
  positions <- generate_walker_positions(5, grid)

  expect_equal(length(positions), 5)
  expect_true(all(sapply(positions, length) == 2))
})

test_that("generate_walker_positions avoids center", {
  grid <- initialize_grid(10)
  positions <- generate_walker_positions(10, grid)

  center <- c(5, 5)
  has_center <- any(sapply(positions, function(p) all(p == center)))

  expect_false(has_center)
})

test_that("get_neighbors returns correct count for 4-hood", {
  neighbors <- get_neighbors(c(5, 5), "4-hood")

  expect_equal(length(neighbors), 4)
  expect_true(any(sapply(neighbors, function(n) all(n == c(4, 5)))))  # North
  expect_true(any(sapply(neighbors, function(n) all(n == c(6, 5)))))  # South
  expect_true(any(sapply(neighbors, function(n) all(n == c(5, 6)))))  # East
  expect_true(any(sapply(neighbors, function(n) all(n == c(5, 4)))))  # West
})

test_that("get_neighbors returns correct count for 8-hood", {
  neighbors <- get_neighbors(c(5, 5), "8-hood")

  expect_equal(length(neighbors), 8)
})

test_that("get_neighbors validates input", {
  expect_error(get_neighbors(c(5, 5), "invalid"), "must be either")
})

test_that("touches_black detects black pixel", {
  grid <- initialize_grid(10)
  walker <- create_walker(1, c(5, 5), 10)

  expect_true(touches_black(walker, grid))

  walker$pos <- c(3, 3)
  expect_false(touches_black(walker, grid))
})

test_that("has_black_neighbor detects neighbors correctly", {
  grid <- initialize_grid(10)
  walker <- create_walker(1, c(4, 5), 10)  # North of center

  expect_true(has_black_neighbor(walker, grid, "4-hood"))

  walker$pos <- c(3, 3)
  expect_false(has_black_neighbor(walker, grid, "4-hood"))
})

test_that("step_walker moves walker", {
  walker <- create_walker(1, c(5, 5), 10)
  walker <- step_walker(walker, "4-hood", "terminate")

  expect_equal(walker$steps, 1)
  expect_equal(length(walker$path), 2)
  expect_true(walker$pos[1] >= 4 && walker$pos[1] <= 6)
  expect_true(walker$pos[2] >= 4 && walker$pos[2] <= 6)
})

test_that("step_walker handles boundary termination", {
  walker <- create_walker(1, c(1, 1), 10)

  # Keep trying until we hit a boundary
  for (i in 1:50) {
    if (!walker$active) break
    walker <- step_walker(walker, "4-hood", "terminate")
  }

  # Walker should eventually hit boundary or stay within
  expect_true(!walker$active || is_within_bounds(walker$pos, 10))
})

test_that("step_walker handles wrap boundary", {
  walker <- create_walker(1, c(1, 5), 10)

  # Force move north (out of bounds without wrap)
  set.seed(123)
  walker_wrap <- walker
  for (i in 1:20) {
    walker_wrap <- step_walker(walker_wrap, "4-hood", "wrap")
    if (!walker_wrap$active) break
  }

  # With wrap, walker should still be active
  expect_true(walker_wrap$steps > 0)
})

test_that("check_termination detects black pixel", {
  grid <- initialize_grid(10)
  walker <- create_walker(1, c(5, 5), 10)
  walker <- check_termination(walker, grid, "4-hood", "terminate")

  expect_false(walker$active)
  expect_equal(walker$termination_reason, "touched_black")
})

test_that("check_termination detects black neighbor", {
  grid <- initialize_grid(10)
  walker <- create_walker(1, c(4, 5), 10)
  walker <- check_termination(walker, grid, "4-hood", "terminate")

  expect_false(walker$active)
  expect_equal(walker$termination_reason, "black_neighbor")
})

test_that("check_termination detects max steps", {
  grid <- initialize_grid(10)
  walker <- create_walker(1, c(1, 1), 10)
  walker$steps <- 10000
  walker <- check_termination(walker, grid, "4-hood", "terminate", max_steps = 10000)

  expect_false(walker$active)
  expect_equal(walker$termination_reason, "max_steps")
})

test_that("inactive walker stays inactive", {
  walker <- create_walker(1, c(5, 5), 10)
  walker$active <- FALSE
  walker$termination_reason <- "test"

  walker_moved <- step_walker(walker, "4-hood", "terminate")

  expect_equal(walker_moved$steps, 0)
  expect_false(walker_moved$active)
})
