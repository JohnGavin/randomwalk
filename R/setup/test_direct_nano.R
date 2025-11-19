# Test calling nano directly vs in a function
# Date: 2025-11-19

library(crew)
library(logger)
library(nanonext)

log_threshold(INFO)

# Create publisher first
pub_socket <- nano("pub", listen = "tcp://127.0.0.1:5555")
log_info("Publisher created")

# Create controller
controller <- crew_controller_local(name = "test", workers = 1, seconds_idle = 10)
controller$start()

# Test 1: Call nano directly in command (THIS WORKS)
log_info("\n--- Test 1: Direct nano call ---")
controller$push(
  command = {
    library(nanonext)
    socket <- nano("sub", dial = "tcp://127.0.0.1:5555")
    subscribe(socket, "")
    list(success = TRUE, class = class(socket))
  }
)

# Poll for result
max_wait <- 10
start <- Sys.time()
result1 <- NULL
while (is.null(result1) && difftime(Sys.time(), start, units = "secs") < max_wait) {
  result1 <- controller$pop()
  if (is.null(result1)) Sys.sleep(0.5)
}

if (!is.null(result1) && nrow(result1) > 0) {
  log_info("Test 1 - Status: {result1$status}")
  if (result1$status == "success") {
    log_info("Test 1 - Success! Socket class: {result1$result[[1]]$class}")
  } else {
    log_error("Test 1 - Error: {result1$error}")
  }
} else {
  log_error("Test 1 - No result after {max_wait} seconds")
}

# Test 2: Call through a parameter (to simulate our use case)
log_info("\n--- Test 2: Nano call with parameter ---")
pub_addr <- "tcp://127.0.0.1:5555"
controller$push(
  command = {
    library(nanonext)
    socket <- nano("sub", dial = addr)
    subscribe(socket, "")
    list(success = TRUE, class = class(socket), addr_used = addr)
  },
  data = list(addr = pub_addr)
)

# Poll for result
start <- Sys.time()
result2 <- NULL
while (is.null(result2) && difftime(Sys.time(), start, units = "secs") < max_wait) {
  result2 <- controller$pop()
  if (is.null(result2)) Sys.sleep(0.5)
}

if (!is.null(result2) && nrow(result2) > 0) {
  log_info("Test 2 - Status: {result2$status}")
  if (result2$status == "success") {
    log_info("Test 2 - Success! Socket class: {result2$result[[1]]$class}")
    log_info("Test 2 - Address used: {result2$result[[1]]$addr_used}")
  } else {
    log_error("Test 2 - Error: {result2$error}")
  }
} else {
  log_error("Test 2 - No result after {max_wait} seconds")
}

# Cleanup
controller$terminate()
nanonext::close(pub_socket)
log_info("\nTests complete")
