# install_hooks.R
#
# Install git hooks for automatic nix file regeneration
#
# Usage:
#   source("R/setup/nix/install_hooks.R")
#   install_git_hooks()
#
# What it does:
#   Installs the pre-commit hook that automatically regenerates nix files
#   when DESCRIPTION is modified. This ensures nix files stay in sync.

#' Find package root directory
#'
#' Searches upward from current directory to find DESCRIPTION file
#' @return Path to package root
#' @keywords internal
find_package_root <- function() {
  path <- getwd()
  while (path != dirname(path)) {
    if (file.exists(file.path(path, "DESCRIPTION"))) {
      return(path)
    }
    path <- dirname(path)
  }
  stop("Could not find package root (no DESCRIPTION file found)")
}

#' Install git hooks for nix file auto-regeneration
#'
#' Copies the pre-commit hook from inst/hooks to .git/hooks and makes it executable.
#' This hook automatically regenerates nix files when DESCRIPTION changes.
#'
#' @param force Logical. If TRUE, overwrite existing hooks (default FALSE)
#' @return Invisible TRUE on success
#' @export
#'
#' @examples
#' \dontrun{
#' install_git_hooks()
#' }
install_git_hooks <- function(force = FALSE) {
  # Find package root (directory containing DESCRIPTION)
  pkg_root <- find_package_root()

  hook_source <- file.path(pkg_root, "inst", "hooks", "pre-commit")
  hook_dest <- file.path(pkg_root, ".git", "hooks", "pre-commit")

  # Check source exists

if (!file.exists(hook_source)) {
    stop("Hook source not found: ", hook_source, "\n",
         "Please ensure inst/hooks/pre-commit exists")
  }

  # Check .git directory exists
  git_dir <- file.path(pkg_root, ".git")
  if (!dir.exists(git_dir)) {
    stop("Not a git repository: ", pkg_root)
  }

  # Create hooks directory if needed
  hooks_dir <- file.path(git_dir, "hooks")
  if (!dir.exists(hooks_dir)) {
    dir.create(hooks_dir)
  }

  # Check for existing hook
  if (file.exists(hook_dest) && !force) {
    message("Pre-commit hook already exists at: ", hook_dest)
    message("Use install_git_hooks(force = TRUE) to overwrite")
    return(invisible(FALSE))
  }

  # Copy hook
  file.copy(hook_source, hook_dest, overwrite = force)

  # Make executable (Unix only)
  if (.Platform$OS.type == "unix") {
    Sys.chmod(hook_dest, mode = "0755")
  }

  message("Installed pre-commit hook to: ", hook_dest)
  message("")
  message("The hook will automatically regenerate nix files when you commit")
  message("changes to DESCRIPTION. To test it:")
  message("")
  message("  1. Make a small change to DESCRIPTION (e.g., add a space)")
  message("  2. git add DESCRIPTION")
message("  3. git commit -m 'test hook'")
  message("  4. Check that package.nix and default-ci.nix were updated")
  message("")

  invisible(TRUE)
}

#' Uninstall git hooks
#'
#' Removes the pre-commit hook installed by install_git_hooks()
#'
#' @return Invisible TRUE on success
#' @export
uninstall_git_hooks <- function() {
  pkg_root <- find_package_root()
  hook_dest <- file.path(pkg_root, ".git", "hooks", "pre-commit")

  if (!file.exists(hook_dest)) {
    message("No pre-commit hook found")
    return(invisible(FALSE))
  }

  file.remove(hook_dest)
  message("Removed pre-commit hook: ", hook_dest)

  invisible(TRUE)
}

#' Check if git hooks are installed
#'
#' @return Logical. TRUE if pre-commit hook is installed
#' @export
hooks_installed <- function() {
  pkg_root <- find_package_root()
  hook_dest <- file.path(pkg_root, ".git", "hooks", "pre-commit")

  if (file.exists(hook_dest)) {
    message("Pre-commit hook is installed: ", hook_dest)
    TRUE
  } else {
    message("Pre-commit hook is NOT installed")
    message("Run install_git_hooks() to install")
    FALSE
  }
}

# Print usage if sourced interactively
if (interactive()) {
  message("Git hooks installer loaded.")
  message("")
  message("Usage:")
  message("  install_git_hooks()     # Install hooks")
  message("  uninstall_git_hooks()   # Remove hooks")
  message("  hooks_installed()       # Check status")
}
