# test-webr-detection.R
# Tests for WebR environment detection

test_that("is_webr() returns FALSE in native R environment", {
  # In native R, neither .webr_env object nor WEBR=1 env var should exist
  # (unless we're actually running in WebR, which is unlikely for package tests)

  # Save current state
  old_webr_env <- Sys.getenv("WEBR")
  webr_obj_exists <- exists(".webr_env", envir = .GlobalEnv)

  # Ensure clean state
  if (webr_obj_exists) {
    skip("Test environment has .webr_env object - cannot test native R behavior")
  }
  Sys.unsetenv("WEBR")

  # Test
  expect_false(randomwalk:::is_webr())

  # Restore
  if (old_webr_env != "") {
    Sys.setenv(WEBR = old_webr_env)
  }
})

test_that("is_webr() returns TRUE when .webr_env exists", {
  # Save current state
  webr_obj_exists <- exists(".webr_env", envir = .GlobalEnv)
  old_webr_env <- NULL

  # Create .webr_env in global environment
  if (!webr_obj_exists) {
    assign(".webr_env", list(test = TRUE), envir = .GlobalEnv)
  }

  # Test
  expect_true(randomwalk:::is_webr())

  # Clean up - remove .webr_env if we created it
  if (!webr_obj_exists && exists(".webr_env", envir = .GlobalEnv)) {
    rm(.webr_env, envir = .GlobalEnv)
  }
})

test_that("is_webr() returns TRUE when WEBR=1 environment variable is set", {
  # Save current state
  old_webr_env <- Sys.getenv("WEBR")
  webr_obj_exists <- exists(".webr_env", envir = .GlobalEnv)

  # Ensure .webr_env doesn't interfere with env var test
  if (webr_obj_exists) {
    skip("Test environment has .webr_env object - cannot test WEBR env var alone")
  }

  # Set WEBR=1
  Sys.setenv(WEBR = "1")

  # Test
  expect_true(randomwalk:::is_webr())

  # Restore
  if (old_webr_env == "") {
    Sys.unsetenv("WEBR")
  } else {
    Sys.setenv(WEBR = old_webr_env)
  }
})

test_that("is_webr() returns FALSE when WEBR is set to non-'1' value", {
  # Save current state
  old_webr_env <- Sys.getenv("WEBR")
  webr_obj_exists <- exists(".webr_env", envir = .GlobalEnv)

  # Ensure .webr_env doesn't exist
  if (webr_obj_exists) {
    skip("Test environment has .webr_env object - cannot test WEBR env var alone")
  }

  # Set WEBR to non-"1" value
  Sys.setenv(WEBR = "0")

  # Test
  expect_false(randomwalk:::is_webr())

  # Set to empty string
  Sys.setenv(WEBR = "")
  expect_false(randomwalk:::is_webr())

  # Restore
  if (old_webr_env == "") {
    Sys.unsetenv("WEBR")
  } else {
    Sys.setenv(WEBR = old_webr_env)
  }
})
