# Debug Crew API Integration
# Date: 2025-11-19
# Purpose: Understand crew controller API structure to fix walker extraction bug

library(crew)

# Test 1: Minimal crew example
cat("=== Test 1: Minimal Crew Example ===\n")

controller <- crew_controller_local(
  name = "test_controller",
  workers = 2,
  seconds_idle = 10
)

controller$start()
cat("Controller started:", controller$started, "\n")

# Test 2: Simple task - return a list
cat("\n=== Test 2: Simple Task ===\n")

controller$push(
  name = "simple_task",
  command = identity(list(id = 1, value = 42, name = "test"))
)

# Wait for task
controller$wait(mode = "all")

# Pop result
result <- controller$pop()
cat("Result structure:\n")
print(str(result))
cat("\nResult class:", class(result), "\n")

if (!is.null(result) && nrow(result) > 0) {
  cat("\nResult columns:", names(result), "\n")
  cat("\nFirst row:\n")
  print(result[1, ])

  # Try to extract the actual result
  cat("\nExtracted result (result[[1]]):\n")
  print(result$result[[1]])

  cat("\nExtracted result class:", class(result$result[[1]]), "\n")
}

# Test 3: Task that returns a walker-like object
cat("\n=== Test 3: Walker-like Object ===\n")

# Create a simple walker-like structure
test_walker <- list(
  id = 5,
  pos = c(10, 10),
  active = FALSE,
  path = list(c(5, 5), c(6, 6), c(10, 10)),
  termination_reason = "test"
)

controller$push(
  name = "walker_task",
  command = {
    walker <- list(
      id = 5,
      pos = c(10, 10),
      active = FALSE,
      path = list(c(5, 5), c(6, 6), c(10, 10)),
      termination_reason = "test"
    )
    walker
  }
)

controller$wait(mode = "all")
walker_result <- controller$pop()

cat("Walker result structure:\n")
print(str(walker_result))

if (!is.null(walker_result) && nrow(walker_result) > 0) {
  cat("\nExtracted walker:\n")
  extracted_walker <- walker_result$result[[1]]
  print(str(extracted_walker))

  cat("\nWalker ID:", extracted_walker$id, "\n")
  cat("Walker active:", extracted_walker$active, "\n")
}

# Test 4: Using scale parameter
cat("\n=== Test 4: Using scale = TRUE ===\n")

controller$push(
  name = "scale_test",
  command = list(id = 99, value = "scale test")
)

controller$wait(mode = "all")
scale_result <- controller$pop(scale = TRUE)

cat("Scale result structure:\n")
print(str(scale_result))

# Cleanup
controller$terminate()
cat("\n=== Cleanup Complete ===\n")
cat("Controller terminated\n")
