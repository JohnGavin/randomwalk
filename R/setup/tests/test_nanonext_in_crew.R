# Test nanonext socket creation in crew workers
# Date: 2025-11-19
# Purpose: Isolate nanonext socket issue to understand what's failing

library(crew)
library(nanonext)
library(logger)

log_threshold(TRACE)

log_info("=== Testing nanonext in crew workers ===")

# Create controller
controller <- crew_controller_local(
  name = "nanonext_test",
  workers = 1,
  seconds_idle = 10
)

controller$start()
log_info("Controller started")

# Test 1: Simple command without nanonext
log_info("\n--- Test 1: Simple arithmetic ---")
controller$push(
  command = 2 + 2,
  data = list()
)

Sys.sleep(1)
result1 <- controller$pop()
if (!is.null(result1) && nrow(result1) > 0) {
  log_info("Test 1 result: {result1$result[[1]]}")
  log_info("Test 1 status: {result1$status}")
} else {
  log_error("Test 1: No result")
}

# Test 2: Load nanonext package
log_info("\n--- Test 2: Load nanonext package ---")
controller$push(
  command = {
    library(nanonext)
    "nanonext loaded"
  },
  packages = "nanonext"
)

Sys.sleep(1)
result2 <- controller$pop()
if (!is.null(result2) && nrow(result2) > 0) {
  log_info("Test 2 result: {result2$result[[1]]}")
  log_info("Test 2 status: {result2$status}")
  if (result2$status == "error") {
    log_error("Test 2 error: {result2$error}")
  }
} else {
  log_error("Test 2: No result")
}

# Test 3: Create nanonext socket (publisher)
log_info("\n--- Test 3: Create publisher socket ---")
controller$push(
  command = {
    library(nanonext)
    socket <- nano("pub", listen = "tcp://127.0.0.1:5556")
    class(socket)
  },
  packages = "nanonext"
)

Sys.sleep(1)
result3 <- controller$pop()
if (!is.null(result3) && nrow(result3) > 0) {
  log_info("Test 3 result: {result3$result[[1]]}")
  log_info("Test 3 status: {result3$status}")
  if (result3$status == "error") {
    log_error("Test 3 error: {result3$error}")
  }
} else {
  log_error("Test 3: No result")
}

# Test 4: Create nanonext socket (subscriber) - the one we're using
log_info("\n--- Test 4: Create subscriber socket ---")
controller$push(
  command = {
    library(nanonext)
    # First start a publisher in the main process
    socket <- nano("sub", dial = "tcp://127.0.0.1:5555")
    class(socket)
  },
  packages = "nanonext"
)

Sys.sleep(1)
result4 <- controller$pop()
if (!is.null(result4) && nrow(result4) > 0) {
  log_info("Test 4 result: {result4$result[[1]]}")
  log_info("Test 4 status: {result4$status}")
  if (result4$status == "error") {
    log_error("Test 4 error: {result4$error}")
    log_info("Test 4 trace: {result4$trace}")
  }
} else {
  log_error("Test 4: No result")
}

# Test 5: Use subscribe function
log_info("\n--- Test 5: Create socket and subscribe ---")
controller$push(
  command = {
    library(nanonext)
    socket <- nano("sub", dial = "tcp://127.0.0.1:5555")
    subscribe(socket, "")
    "subscribed"
  },
  packages = "nanonext"
)

Sys.sleep(1)
result5 <- controller$pop()
if (!is.null(result5) && nrow(result5) > 0) {
  log_info("Test 5 result: {result5$result[[1]]}")
  log_info("Test 5 status: {result5$status}")
  if (result5$status == "error") {
    log_error("Test 5 error: {result5$error}")
    log_info("Test 5 trace: {result5$trace}")
  }
} else {
  log_error("Test 5: No result")
}

# Cleanup
controller$terminate()
log_info("\n=== Tests complete ===")
