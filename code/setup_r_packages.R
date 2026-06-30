args <- commandArgs(trailingOnly = TRUE)

has_arg <- function(flag) flag %in% args
arg_value <- function(prefix) {
  hit <- grep(paste0("^", prefix), args, value = TRUE)
  if (length(hit) == 0) return(NULL)
  sub(paste0("^", prefix), "", hit[[1]])
}

truthy <- function(x) tolower(x) %in% c("1", "true", "t", "yes", "y")

check_only <- has_arg("--check-only")
strict <- has_arg("--strict") || truthy(Sys.getenv("R_PACKAGE_STRICT"))
install_missing <- !check_only && !has_arg("--no-install")

lib <- arg_value("--lib=")
if (!is.null(lib)) {
  dir.create(lib, recursive = TRUE, showWarnings = FALSE)
  .libPaths(c(normalizePath(lib, winslash = "/", mustWork = FALSE), .libPaths()))
}

source_file <- tryCatch({
  ofile <- sys.frame(1)$ofile
  if (is.null(ofile)) NA_character_ else ofile
}, error = function(e) NA_character_)

script_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
script_file <- if (!is.na(source_file) && nzchar(source_file)) {
  source_file
} else if (length(script_arg) > 0) {
  sub("^--file=", "", script_arg[[1]])
} else {
  NA_character_
}

script_dir <- if (!is.na(script_file) && nzchar(script_file)) {
  dirname(normalizePath(script_file, winslash = "/", mustWork = FALSE))
} else {
  getwd()
}

candidate_helpers <- c(
  file.path(script_dir, "dependencies", "locked_packages.R"),
  file.path(getwd(), "code", "dependencies", "locked_packages.R"),
  file.path(getwd(), "dependencies", "locked_packages.R"),
  file.path(getwd(), "..", "dependencies", "locked_packages.R"),
  file.path(getwd(), "..", "code", "dependencies", "locked_packages.R")
)
helper <- candidate_helpers[file.exists(candidate_helpers)][1]
if (is.na(helper)) {
  stop("Could not find code/dependencies/locked_packages.R. Run this script from the repository root or code directory.")
}

source(helper)

enforce_locked_packages(
  install = install_missing,
  strict = strict,
  load = FALSE,
  warn = TRUE
)

mode <- if (check_only) "check" else if (strict) "strict install/check" else "install/check"
message("R package ", mode, " complete.")
