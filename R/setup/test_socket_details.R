# Test: Inspect what nano() returns in crew worker
# Date: 2025-11-19
# Goal: Understand socket object structure to debug subscribe() error

library(crew)
library(logger)

log_threshold(INFO)

controller <- crew_controller_local(name = "test", workers = 1, seconds_idle = 10)
controller$start()

log_info("=== Test 1: What does nano() return? ===")
controller$push(
  command = {
    library(nanonext)

    # Create socket
    socket <- nano("sub", dial = "tcp://127.0.0.1:5555")

    # Inspect socket BEFORE calling subscribe
    list(
      class = class(socket),
      typeof = typeof(socket),
      length = length(socket),
      names = names(socket),
      is_null = is.null(socket),
      str_output = paste(capture.output(str(socket)), collapse = "\n"),
      socket_raw = socket  # Try to return socket itself
    )
  },
  packages = "nanonext"
)

# Wait for result
Sys.sleep(2)
result <- controller$pop()

if (!is.null(result) && nrow(result) > 0) {
  log_info("Status: {result$status}")
  if (result$status == "success") {
    r <- result$result[[1]]
    log_info("Socket class: {r$class}")
    log_info("Socket typeof: {r$typeof}")
    log_info("Socket is_null: {r$is_null}")
    log_info("Socket structure:\n{r$str_output}")
  } else {
    log_error("Error: {result$error}")
  }
}

log_info("\n=== Test 2: Call subscribe() separately ===")
controller$push(
  command = {
    library(nanonext)

    socket <- nano("sub", dial = "tcp://127.0.0.1:5555")

    # Try subscribe with error handling
    subscribe_result <- tryCatch({
      subscribe(socket, "")
      "SUCCESS"
    }, error = function(e) {
      list(
        error_msg = e$message,
        error_class = class(e),
        socket_class = class(socket),
        socket_valid = !is.null(socket)
      )
    })

    list(
      subscribe_result = subscribe_result,
      socket_class = class(socket)
    )
  },
  packages = "nanonext"
)

Sys.sleep(2)
result2 <- controller$pop()

if (!is.null(result2) && nrow(result2) > 0) {
  log_info("Status: {result2$status}")
  if (result2$status == "success") {
    r <- result2$result[[1]]
    log_info("Subscribe result: {paste(capture.output(str(r$subscribe_result)), collapse = ', ')}")
  } else {
    log_error("Error: {result2$error}")
  }
}

log_info("\n=== Test 3: Check if socket needs initialization ===")
controller$push(
  command = {
    library(nanonext)

    # Try with autostart parameter
    socket1 <- nano("sub", dial = "tcp://127.0.0.1:5555", autostart = TRUE)
    socket2 <- nano("sub", dial = "tcp://127.0.0.1:5556", autostart = FALSE)

    list(
      socket1_class = class(socket1),
      socket2_class = class(socket2),
      both_nanoObject = class(socket1) == "nanoObject" && class(socket2) == "nanoObject"
    )
  },
  packages = "nanonext"
)

Sys.sleep(2)
result3 <- controller$pop()

if (!is.null(result3) && nrow(result3) > 0) {
  log_info("Status: {result3$status}")
  if (result3$status == "success") {
    r <- result3$result[[1]]
    log_info("Socket1 class: {r$socket1_class}")
    log_info("Socket2 class: {r$socket2_class}")
  } else {
    log_error("Error: {result3$error}")
  }
}

controller$terminate()
log_info("\nTests complete")
