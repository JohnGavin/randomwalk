# Test nanonext socket creation with proper result waiting
# Date: 2025-11-19
# Purpose: Fix timing issues in previous tests

library(crew)
library(nanonext)
library(logger)

log_threshold(INFO)

log_info("=== Testing nanonext with proper waiting ===")

# Create controller
controller <- crew_controller_local(
  name = "nanonext_test",
  workers = 1,
  seconds_idle = 30
)

controller$start()
log_info("Controller started")

# Helper function to wait for and retrieve result
wait_for_result <- function(ctrl, test_name, max_wait = 5) {
  log_info("\n--- {test_name} ---")

  start_time <- Sys.time()
  while (difftime(Sys.time(), start_time, units = "secs") < max_wait) {
    result <- ctrl$pop(scale = FALSE)
    if (!is.null(result) && nrow(result) > 0) {
      log_info("{test_name} - Status: {result$status}")
      if (result$status == "success") {
        log_info("{test_name} - Result: {paste(capture.output(str(result$result[[1]])), collapse = ', ')}")
        return(result$result[[1]])
      } else {
        log_error("{test_name} - Error: {result$error}")
        if (!is.null(result$trace)) {
          log_error("{test_name} - Trace: {result$trace}")
        }
        return(NULL)
      }
    }
    Sys.sleep(0.1)
  }
  log_error("{test_name} - Timeout after {max_wait}s")
  return(NULL)
}

# Test 1: Simple arithmetic
log_info("\n=== Test 1: Simple Command ===")
controller$push(
  command = 2 + 2
)
result1 <- wait_for_result(controller, "Simple arithmetic")

# Test 2: Load nanonext
log_info("\n=== Test 2: Load nanonext ===")
controller$push(
  command = {
    library(nanonext)
    packageVersion("nanonext")
  },
  packages = "nanonext"
)
result2 <- wait_for_result(controller, "Load nanonext")

# Test 3: Create subscriber socket
log_info("\n=== Test 3: Create subscriber socket ===")
controller$push(
  command = {
    library(nanonext)
    socket <- nano("sub", dial = "tcp://127.0.0.1:5555")
    list(
      class = class(socket),
      is_valid = !is.null(socket),
      can_convert_to_list = is.list(as.list(socket))
    )
  },
  packages = "nanonext"
)
result3 <- wait_for_result(controller, "Create subscriber")

# Test 4: Create socket and call subscribe
log_info("\n=== Test 4: Create socket and subscribe ===")
controller$push(
  command = {
    library(nanonext)
    socket <- nano("sub", dial = "tcp://127.0.0.1:5555")

    # Call subscribe with error handling
    subscribe_result <- tryCatch({
      subscribe(socket, "")
      "SUCCESS"
    }, error = function(e) {
      list(error = e$message, class = class(e))
    })

    list(
      socket_class = class(socket),
      subscribe_result = subscribe_result
    )
  },
  packages = "nanonext"
)
result4 <- wait_for_result(controller, "Socket + subscribe")

# Test 5: Full integration test - create pub socket in main, sub in worker
log_info("\n=== Test 5: Pub/Sub integration ===")

# Create publisher in main process
pub_socket <- nano("pub", listen = "tcp://127.0.0.1:7777")
log_info("Created publisher on port 7777")

controller$push(
  command = {
    library(nanonext)

    # Subscribe to the publisher
    sub_socket <- nano("sub", dial = "tcp://127.0.0.1:7777")
    subscribe(sub_socket, "")

    "Subscriber connected and subscribed"
  },
  packages = "nanonext"
)
result5 <- wait_for_result(controller, "Pub/Sub integration")

# Cleanup publisher
close(pub_socket)
log_info("Closed publisher socket")

# Cleanup controller
controller$terminate()
log_info("\n=== All tests complete ===")
