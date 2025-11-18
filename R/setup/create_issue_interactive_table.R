# Create GitHub Issue: Interactive Table for Raw Data Page
# Date: 2025-01-18
# Purpose: Log command to create future enhancement issue

library(gh)

# Issue details
issue_title <- "Add interactive table to raw data page"

issue_body <- "## Description

Replace the static table in the dashboard's raw data page with an interactive table that supports:
- Filtering by columns
- Pagination for large datasets
- Sorting by any column
- Better user experience for exploring simulation data

## Proposed Solution

Use one of these R packages:
- **reactable**: https://glin.github.io/reactable/
  - Modern, performant, feature-rich
  - Good Shiny integration
  - Recommended option

- **DT**: https://rstudio.github.io/DT/
  - Mature, widely used
  - jQuery DataTables wrapper
  - Alternative option

## Implementation Details

- Target file: `R/shiny_modules.R` (raw data module)
- Update dashboard vignette to showcase interactive features
- Add package to DESCRIPTION Suggests
- Test in both native R and Shinylive (verify webR compatibility)

## Milestone

v2.1.0 (post-async implementation)

## Priority

Low - Enhancement for future release after async v2.0.0 is complete
"

# Create the issue
result <- gh(
  "POST /repos/{owner}/{repo}/issues",
  owner = "JohnGavin",
  repo = "randomwalk",
  title = issue_title,
  body = issue_body,
  labels = list("enhancement", "future-work")
)

# Print result
cat("Issue created successfully!\n")
cat("Issue number:", result$number, "\n")
cat("URL:", result$html_url, "\n")

# Return issue number for reference
result$number
