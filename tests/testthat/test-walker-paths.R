# Tests for walker path plotting stability

test_that("walker colors remain stable across different selections", {
  # Create mock walkers with termination orders
  walkers <- list(
    list(id = 1, termination_order = 18, path = list(c(1,1), c(1,2), c(1,3)), pos = c(1,3), active = FALSE),
    list(id = 2, termination_order = 19, path = list(c(2,1), c(2,2), c(2,3)), pos = c(2,3), active = FALSE),
    list(id = 3, termination_order = 20, path = list(c(3,1), c(3,2), c(3,3)), pos = c(3,3), active = FALSE)
  )

  # Define color mapping function (matching dashboard logic)
  get_walker_color <- function(termination_order) {
    distinct_colors <- c("red", "blue", "darkgreen", "purple", "orange")
    color_index <- ((termination_order - 1) %% length(distinct_colors)) + 1
    distinct_colors[color_index]
  }

  # Test that walker 20 gets same color regardless of selection
  color_20_alone <- get_walker_color(20)
  color_20_with_19 <- get_walker_color(20)
  color_20_with_all <- get_walker_color(20)

  expect_equal(color_20_alone, color_20_with_19)
  expect_equal(color_20_alone, color_20_with_all)
  expect_equal(color_20_alone, "orange")  # (20-1) %% 5 + 1 = 5

  # Test that different walkers get different colors
  color_18 <- get_walker_color(18)
  color_19 <- get_walker_color(19)

  expect_equal(color_18, "darkgreen")  # (18-1) %% 5 + 1 = 3
  expect_equal(color_19, "purple")     # (19-1) %% 5 + 1 = 4
  expect_false(color_18 == color_19)
  expect_false(color_19 == color_20_alone)
})

test_that("walker path data is correctly extracted", {
  # Create test walker with known path
  walker <- list(
    id = 1,
    termination_order = 1,
    path = list(c(10, 20), c(11, 21), c(12, 22)),
    pos = c(12, 22),
    active = FALSE
  )

  # Extract path matrix
  path_matrix <- do.call(rbind, walker$path)

  # Verify dimensions
  expect_equal(nrow(path_matrix), 3)
  expect_equal(ncol(path_matrix), 2)

  # Verify coordinates (note: row is Y, column is X in plotting)
  expect_equal(path_matrix[1, 1], 10)  # First Y
  expect_equal(path_matrix[1, 2], 20)  # First X
  expect_equal(path_matrix[3, 1], 12)  # Last Y
  expect_equal(path_matrix[3, 2], 22)  # Last X
})

test_that("walker selection indices are calculated correctly", {
  n_walkers <- 20

  # Test first_n selection
  first_n <- 5
  last_n <- 0
  indices <- unique(c(
    if(first_n > 0) 1:first_n else NULL,
    if(last_n > 0) (n_walkers - last_n + 1):n_walkers else NULL
  ))
  expect_equal(indices, 1:5)

  # Test last_n selection
  first_n <- 0
  last_n <- 3
  indices <- unique(c(
    if(first_n > 0) 1:first_n else NULL,
    if(last_n > 0) (n_walkers - last_n + 1):n_walkers else NULL
  ))
  expect_equal(indices, 18:20)

  # Test combined selection with overlap
  first_n <- 15
  last_n <- 10
  indices <- unique(c(
    if(first_n > 0) 1:first_n else NULL,
    if(last_n > 0) (n_walkers - last_n + 1):n_walkers else NULL
  ))
  expect_equal(indices, 1:20)  # All walkers due to overlap

  # Test no overlap
  first_n <- 5
  last_n <- 5
  indices <- unique(c(
    if(first_n > 0) 1:first_n else NULL,
    if(last_n > 0) (n_walkers - last_n + 1):n_walkers else NULL
  ))
  expect_equal(indices, c(1:5, 16:20))  # First 5 and last 5
})

test_that("path plotting data structure is valid", {
  # Create multiple test walkers
  walkers <- list(
    list(termination_order = 1, path = list(c(1,1), c(1,2)), pos = c(1,2)),
    list(termination_order = 2, path = list(c(2,1), c(2,2)), pos = c(2,2)),
    list(termination_order = 3, path = NULL, pos = c(3,3))  # Walker without path
  )

  # Process walkers into plot data
  all_paths <- list()
  all_ends <- list()

  for (walker in walkers) {
    key <- paste0("walker_", walker$termination_order)

    if (!is.null(walker$path) && length(walker$path) > 0) {
      path_matrix <- do.call(rbind, walker$path)
      all_paths[[key]] <- list(
        x = path_matrix[, 2],
        y = path_matrix[, 1]
      )
    }

    if (!is.null(walker$pos)) {
      all_ends[[key]] <- list(
        x = walker$pos[2],
        y = walker$pos[1]
      )
    }
  }

  # Verify structure
  expect_equal(length(all_paths), 2)  # Only 2 walkers have paths
  expect_equal(length(all_ends), 3)   # All 3 have end positions
  expect_true("walker_1" %in% names(all_paths))
  expect_true("walker_2" %in% names(all_paths))
  expect_false("walker_3" %in% names(all_paths))  # No path
  expect_true("walker_3" %in% names(all_ends))    # But has end position
})