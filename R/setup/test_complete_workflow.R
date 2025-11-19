# Test: Complete pub/sub workflow in crew
# Date: 2025-11-19
# Goal: Test if full publisher->subscriber communication works

library(crew)
library(nanonext)
library(logger)

log_threshold(INFO)

# Create publisher first
log_info("Creating publisher on port 5555...")
pub_socket <- nano("pub", listen = "tcp://127.0.0.1:5555")
log_info("Publisher created")

# Give it time to start
Sys.sleep(0.5)

# Create crew controller
controller <- crew_controller_local(name = "test", workers = 1, seconds_idle = 10)
controller$start()

log_info("\n=== Test: Full sub/subscribe/receive workflow ===")
controller$push(
  command = {
    library(nanonext)

    # Create subscriber
    socket <- nano("sub", dial = "tcp://127.0.0.1:5555")

    # Subscribe to all messages
    subscribe(socket, "")

    # Wait briefly for connection
    Sys.sleep(0.2)

    # Try non-blocking receive
    msg <- recv(socket, mode = "raw", block = FALSE)

    list(
      socket_created = TRUE,
      subscribed = TRUE,
      msg_received = !is.null(msg),
      msg_class = if (!is.null(msg)) class(msg) else "NULL"
    )
  },
  packages = "nanonext"
)

# Send a message from publisher
Sys.sleep(0.5)
log_info("Sending test message from publisher...")
test_msg <- serialize(list(type = "test", value = 123), NULL)
nanonext::send(pub_socket, test_msg, mode = "raw", block = FALSE)

# Wait for worker result
Sys.sleep(1)
result <- controller$pop()

if (!is.null(result) && nrow(result) > 0) {
  log_info("\nStatus: {result$status}")
  if (result$status == "success") {
    r <- result$result[[1]]
    log_info("Socket created: {r$socket_created}")
    log_info("Subscribed: {r$subscribed}")
    log_info("Message received: {r$msg_received}")
    log_info("Message class: {r$msg_class}")
  } else {
    log_error("Error: {result$error}")
    if (!is.na(result$trace)) {
      log_info("Trace: {result$trace}")
    }
  }
} else {
  log_error("No result received")
}

# Cleanup
controller$terminate()
nanonext::close(pub_socket)
log_info("\nTest complete")
