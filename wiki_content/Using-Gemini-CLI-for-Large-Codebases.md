# Using Gemini CLI for Large Codebase Analysis

When analyzing large codebases or multiple files that might exceed Claude's context limits, use the Gemini CLI with its massive context window.

## When to Use Gemini CLI

Use `gemini -p` when:

- ✅ Analyzing entire codebases or large directories
- ✅ Comparing multiple large files
- ✅ Understanding project-wide patterns or architecture
- ✅ Current context window is insufficient for the task
- ✅ Working with files totaling more than 100KB
- ✅ Verifying if specific features, patterns, or security measures are implemented
- ✅ Checking for the presence of certain coding patterns across the entire codebase
- ✅ Need comprehensive search across all R package code
- ✅ No need for --yolo flag for read-only analysis

## File and Directory Inclusion Syntax

Use the `@` syntax to include files and directories in your Gemini prompts. **Paths are relative to WHERE you run the gemini command.**

### Basic Examples

**Single file analysis:**
```bash
gemini -p "@src/main.py Explain this file's purpose and structure"
```

**Multiple files:**
```bash
gemini -p "@package.json @src/index.js Analyze the dependencies used in the code"
```

**Entire directory:**
```bash
gemini -p "@src/ Summarize the architecture of this codebase"
```

**Multiple directories:**
```bash
gemini -p "@src/ @tests/ Analyze test coverage for the source code"
```

**Current directory and subdirectories:**
```bash
gemini -p "@./ Give me an overview of this entire project"
```

**Or use --all_files flag:**
```bash
gemini --all_files -p "Analyze the project structure and dependencies"
```

## R Package Analysis Examples

### Codebase Structure
```bash
# From package root
gemini -p "@R/ @inst/ @vignettes/ Summarize the structure and purpose of this R package"
```

### Documentation Review
```bash
gemini -p "@man/ Are all exported functions properly documented with examples?"
```

### Test Coverage Analysis
```bash
gemini -p "@R/ @tests/ Which functions in R/ are missing tests?"
```

### Dependencies Check
```bash
gemini -p "@DESCRIPTION @R/ Are all package dependencies actually used in the code?"
```

### Targets Pipeline Review
```bash
gemini -p "@_targets.R @R/tar_plans/ Explain the targets pipeline structure and dependencies"
```

## Implementation Verification Examples

### Check if a feature is implemented
```bash
gemini -p "@R/ @inst/ Has async simulation been implemented? Show relevant functions"
```

### Verify authentication implementation
```bash
gemini -p "@R/api/ @R/auth/ Is token-based auth implemented? List all auth functions"
```

### Check for specific patterns
```bash
gemini -p "@R/ Are there any functions using parallel processing? List with file paths"
```

### Verify error handling
```bash
gemini -p "@R/ Is proper error handling implemented? Show examples of tryCatch usage"
```

### Check for rate limiting
```bash
gemini -p "@R/api/ Is API rate limiting implemented? Show the implementation"
```

### Verify caching strategy
```bash
gemini -p "@R/ Are results cached? List all caching-related functions"
```

### Check for specific security measures
```bash
gemini -p "@R/ Are user inputs validated? Show input sanitization functions"
```

### Verify test coverage for features
```bash
gemini -p "@R/simulation.R @tests/testthat/ Is the simulation module fully tested?"
```

## R-Specific Use Cases

### Package Standards Compliance
```bash
gemini -p "@. Does this package follow tidyverse style guidelines?"
```

### Documentation Completeness
```bash
gemini -p "@man/ @vignettes/ List all exported functions without vignette examples"
```

### Dependency Analysis
```bash
gemini -p "@DESCRIPTION @NAMESPACE @R/ Are there any unused Imports in DESCRIPTION?"
```

### Code Quality Review
```bash
gemini -p "@R/ Find instances of code duplication that could be refactored"
```

### Shinylive Dashboard Review
```bash
gemini -p "@inst/shiny/ @vignettes/ How is the Shinylive dashboard structured?"
```

## Integration with R Workflows

### Using ellmer R Package

Connect to Gemini via R for reproducible analysis:

```r
library(ellmer)

# Create chat session
chat <- chat_google_gemini(
  system_prompt = "You are an R package code reviewer"
)

# Analyze code
result <- chat$chat("Review this function for best practices:")
```

**Benefits:**
- R commands stored in `R/setup/` for reproducibility
- Results can be saved to markdown files
- Integrate with documentation workflow

### Combining with btw Package

Use btw (by the way) for interactive R package exploration:

```r
library(btw)

# Then use Gemini for deeper analysis of findings
```

## Important Notes

- 📁 **Paths** in `@` syntax are relative to your current working directory when invoking gemini
- 📄 **File contents** included directly in the context
- 🔒 **No --yolo flag** needed for read-only analysis
- 🎯 **Be specific** about what you're looking for to get accurate results
- 💰 **Context window** can handle entire codebases that would overflow Claude's context
- ⚡ **Performance** - Gemini CLI is fast for large codebase analysis

## When to Use Claude vs Gemini

### Use Claude Code when:
- ✅ Making code changes
- ✅ Interactive development
- ✅ Git operations and PR creation
- ✅ Running tests and builds
- ✅ Package development workflow
- ✅ Working with context < 100KB

### Use Gemini CLI when:
- ✅ Read-only analysis of entire codebase
- ✅ Large file comparisons
- ✅ Pattern detection across many files
- ✅ Architecture review
- ✅ Finding specific implementations
- ✅ Documentation completeness checks
- ✅ Working with context > 100KB

### Use Both Together:
1. **Gemini** for comprehensive codebase analysis and discovery
2. **Claude Code** for implementing changes based on findings
3. Document findings in markdown files for future reference

## Example Workflow

```bash
# 1. Use Gemini to analyze codebase
cd /Users/johngavin/docs_gh/claude_rix/random_walk
gemini -p "@R/ @tests/ Which functions need more test coverage?"

# 2. Save findings to file
gemini -p "@R/ @tests/ Create a test coverage report" > test_coverage_report.md

# 3. Use Claude Code to implement tests
# Start Claude and: "Read test_coverage_report.md and help me add missing tests"
```

## Resources

- **Gemini CLI**: https://github.com/jamubc/gemini-mcp-tool
- **ellmer R Package**: https://ellmer.tidyverse.org/reference/chat_google_gemini.html
- **btw R Package**: https://cran.r-project.org/web/packages/btw/index.html
- **Reddit Discussion**: https://www.reddit.com/r/ChatGPTCoding/comments/1lm3fxq/gemini_cli_is_awesome_but_only_when_you_make/

## Related Resources

- See [[Working with Claude Across Sessions]] for context management
- See project's R package development guide for testing standards
