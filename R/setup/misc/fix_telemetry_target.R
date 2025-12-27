#!/usr/bin/env Rscript
# Fix telemetry_summary target issue
# Date: 2025-11-16
# Purpose: Add telemetry_summary target to _targets.R

library(logger)

# Setup logging
log_file <- "R/setup/fix_telemetry_target.log"
log_appender(appender_tee(log_file))
log_info("Starting telemetry target fix")

# Read current _targets.R
targets_file <- "_targets.R"
targets_content <- readLines(targets_file, warn = FALSE)

log_info("Read {length(targets_content)} lines from {targets_file}")

# Find the insertion point (before the closing parenthesis of list())
# We want to add the target before the last closing parenthesis
insert_at <- length(targets_content) - 1  # Before final ")"

# Create the telemetry_summary target
new_target <- c(
  "",
  "  # 10. Telemetry summary for vignette",
  "  # Collects metadata from targets pipeline for reporting",
  "  tar_target(",
  "    name = telemetry_summary,",
  "    command = {",
  "      # Get targets meta information",
  "      meta <- targets::tar_meta()",
  "      ",
  "      # Format time and size",
  "      meta %>%",
  "        dplyr::mutate(",
  "          time_formatted = sprintf(\"%.2f\", seconds),",
  "          memory_mb = round(bytes / 1024^2, 2),",
  "          status = ifelse(is.na(error), \"success\", \"error\")",
  "        ) %>%",
  "        dplyr::select(name, time_formatted, memory_mb, status)",
  "    }",
  "  ),"
)

# Insert the new target
new_content <- c(
  targets_content[1:insert_at],
  new_target,
  targets_content[(insert_at + 1):length(targets_content)]
)

# Write back to file
writeLines(new_content, targets_file)
log_info("Added telemetry_summary target to {targets_file}")

# Display the changes
cat("\n", strrep("=", 70), "\n", sep = "")
cat("✅ Fixed telemetry_summary target\n")
cat(strrep("=", 70), "\n\n", sep = "")
cat("Added target:\n")
cat("  - telemetry_summary: Collects pipeline metadata for vignette\n\n")
cat("Changes written to:", targets_file, "\n")
cat(strrep("=", 70), "\n", sep = "")

log_info("Telemetry target fix completed successfully")
