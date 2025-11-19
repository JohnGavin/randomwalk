# Test how crew evaluates commands with data and globals
# Date: 2025-11-19

library(crew)

# Create controller
controller <- crew_controller_local(name = "test", workers = 1, seconds_idle = 10)
controller$start()

# Test function to pass as global
my_func <- function(x, y) {
  list(sum = x + y, product = x * y, x = x, y = y)
}

# Test 1: Call function with data variables
cat("=== Test 1: Function with data variables ===\n")
controller$push(
  name = "test1",
  command = {
    my_func(x, y)
  },
  data = list(x = 10, y = 20),
  globals = list(my_func = my_func)
)

controller$wait(mode = "all")
result1 <- controller$pop()

if (!is.null(result1) && nrow(result1) > 0) {
  cat("Status:", result1$status, "\n")
  if (result1$status == "success") {
    r <- result1$result[[1]]
    cat("Result:", paste(capture.output(str(r)), collapse = "\n"), "\n")
  } else {
    cat("Error:", result1$error, "\n")
    cat("Trace:", result1$trace, "\n")
  }
}

# Test 2: Directly create and return a list
cat("\n=== Test 2: Create list directly ===\n")
controller$push(
  name = "test2",
  command = {
    list(id = 5, value = "test", active = TRUE)
  }
)

controller$wait(mode = "all")
result2 <- controller$pop()

if (!is.null(result2) && nrow(result2) > 0) {
  cat("Status:", result2$status, "\n")
  if (result2$status == "success") {
    r <- result2$result[[1]]
    cat("Result:", paste(capture.output(str(r)), collapse = "\n"), "\n")
    cat("Can access r$id?", !is.null(r$id), "Value:", r$id, "\n")
  } else {
    cat("Error:", result2$error, "\n")
  }
}

# Test 3: Return input data as-is
cat("\n=== Test 3: Return input data ===\n")
test_walker <- list(id = 99, pos = c(5, 5), active = FALSE)
controller$push(
  name = "test3",
  command = {
    walker  # Just return the walker as-is
  },
  data = list(walker = test_walker)
)

controller$wait(mode = "all")
result3 <- controller$pop()

if (!is.null(result3) && nrow(result3) > 0) {
  cat("Status:", result3$status, "\n")
  if (result3$status == "success") {
    r <- result3$result[[1]]
    cat("Result:", paste(capture.output(str(r)), collapse = "\n"), "\n")
    cat("Can access r$id?", !is.null(r$id), "Value:", r$id, "\n")
  } else {
    cat("Error:", result3$error, "\n")
  }
}

controller$terminate()
cat("\nTests complete\n")
