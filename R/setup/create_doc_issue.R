# Create GitHub Issue for Dynamic Broadcasting Documentation
# Issue #89: Document algorithm in wiki and vignette

library(gh)

issue <- gh("POST /repos/JohnGavin/randomwalk/issues",
  title = "Document Dynamic Broadcasting Algorithm in Wiki/Vignette",
  body = "## Summary

Document the dynamic grid broadcasting algorithm implemented in PR #83 (Group E).

## Scope

### Wiki Page (Primary Documentation)

Create comprehensive wiki page: `Dynamic-Grid-Broadcasting-Algorithm.md`

**Content:**
- Problem statement (static snapshots vs dynamic updates)
- Algorithm overview
- Key innovation: Minimal broadcasting (~10-20 messages vs ~10,000)
- Eventual consistency model
- Step-by-step walker logic with broadcasts
- Performance characteristics (~12% overhead)
- Pub/sub architecture diagrams
- nanonext socket implementation details
- Use cases and limitations

### Vignette Appendix (Cross-Reference)

Add appendix to `vignettes/dynamic_broadcasting.qmd`:

**Content:**
- Brief algorithm summary
- Link to detailed wiki page
- Key equations/pseudocode
- Performance comparison table
- When to use dynamic vs static mode

## Implementation Phases

PR #83 completed Phase 1 (infrastructure). Document:
- Phase 1: Broadcasting infrastructure (R/broadcasting.R) - COMPLETE
- Phase 2: Worker integration - FUTURE
- Phase 3: Simulation integration with sync_mode parameter - FUTURE

## Technical Details to Document

1. **Minimal Broadcasting Design**
   - Only broadcast when creating new black pixels
   - Skip broadcasting on max_steps, boundary, or started_on_black
   - Reduces message overhead significantly

2. **Eventual Consistency**
   - Workers pop all pending messages before each move
   - Acceptable lag for simulation purposes
   - Trade-off: simplicity vs perfect consistency

3. **Implementation Functions**
   - init_publisher_socket() - Setup pub socket
   - init_subscriber_socket() - Setup sub socket
   - broadcast_black_pixel() - Send update
   - update_grid_from_broadcasts() - Pop and apply
   - close_sockets() - Cleanup

4. **Performance**
   - Overhead: ~12% vs static mode
   - Message count: ~10-20 per simulation
   - Scales well with workers

## Related Issues

- Closes Group E (#51) Phase 1
- Related: #87 (async dashboard wiki comparison)

## Acceptance Criteria

- [ ] Wiki page created with comprehensive algorithm documentation
- [ ] Vignette appendix added with cross-reference to wiki
- [ ] Performance benchmarks documented
- [ ] Architecture diagrams included
- [ ] Code examples provided
- [ ] Cross-links verified (wiki to vignette and vice versa)

## Priority

Medium - enhances understanding of advanced feature
",
  labels = list("documentation", "wiki", "vignette", "Group E")
)

cat("Created issue:", issue$number, "\n")
cat("URL:", issue$html_url, "\n")
