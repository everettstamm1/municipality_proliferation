.locked_package_source_file <- tryCatch({
  ofile <- sys.frame(1)$ofile
  if (is.null(ofile)) NA_character_ else normalizePath(ofile, winslash = "/", mustWork = FALSE)
}, error = function(e) NA_character_)

locked_package_truthy <- function(x) {
  tolower(x) %in% c("1", "true", "t", "yes", "y")
}

locked_package_parent_dirs <- function(path) {
  path <- normalizePath(path, winslash = "/", mustWork = FALSE)
  out <- character()
  repeat {
    out <- c(out, path)
    parent <- dirname(path)
    if (identical(parent, path)) break
    path <- parent
  }
  unique(out)
}

locked_package_find_repo_root <- function(start = getwd()) {
  starts <- c(
    Sys.getenv("MUNI_REPO", unset = NA_character_),
    Sys.getenv("REPO", unset = NA_character_),
    getOption("muni.repo_root", NA_character_),
    start,
    if (!is.na(.locked_package_source_file)) dirname(.locked_package_source_file) else NA_character_
  )
  starts <- starts[!is.na(starts) & nzchar(starts)]

  for (root in unique(unlist(lapply(starts, locked_package_parent_dirs)))) {
    if (file.exists(file.path(root, "code", "dependencies", "r_packages.csv"))) {
      return(root)
    }
  }

  paths_file <- file.path(getwd(), "paths.csv")
  if (file.exists(paths_file)) {
    paths <- tryCatch(utils::read.csv(paths_file, stringsAsFactors = FALSE), error = function(e) NULL)
    if (!is.null(paths) && all(c("global", "path") %in% names(paths))) {
      repo <- paths$path[paths$global == "REPO"][1]
      if (!is.na(repo) && file.exists(file.path(repo, "code", "dependencies", "r_packages.csv"))) {
        return(normalizePath(repo, winslash = "/", mustWork = FALSE))
      }
    }
  }

  stop("Could not find code/dependencies/r_packages.csv. Run from the repository, set MUNI_REPO, or create paths.csv.")
}

locked_package_read_lock <- function(lock_file = NULL) {
  if (is.null(lock_file)) {
    lock_file <- file.path(locked_package_find_repo_root(), "code", "dependencies", "r_packages.csv")
  }
  deps <- utils::read.csv(lock_file, stringsAsFactors = FALSE, na.strings = c("", "NA"), strip.white = TRUE)
  required <- c("package", "version", "source")
  missing <- setdiff(required, names(deps))
  if (length(missing) > 0) stop("R dependency lock is missing columns: ", paste(missing, collapse = ", "))

  deps$package <- trimws(deps$package)
  deps$version <- trimws(deps$version)
  deps$source <- tolower(trimws(deps$source))
  deps[nzchar(deps$package), , drop = FALSE]
}

locked_package_repos <- function() {
  repos <- getOption("repos")
  if (is.null(repos) || is.na(repos["CRAN"]) || identical(unname(repos["CRAN"]), "@CRAN@")) {
    repos <- c(CRAN = "https://cloud.r-project.org")
  }
  repos
}

locked_package_installed_version <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) return(NA_character_)
  as.character(utils::packageVersion(pkg))
}

locked_package_check <- function(deps, strict = FALSE) {
  installed <- vapply(deps$package, locked_package_installed_version, character(1))
  exact <- installed == deps$version | is.na(deps$version) | !nzchar(deps$version)
  data.frame(
    package = deps$package,
    required_version = deps$version,
    installed_version = installed,
    source = deps$source,
    installed = !is.na(installed),
    ok = !is.na(installed) & (!strict | exact),
    stringsAsFactors = FALSE
  )
}

locked_package_install <- function(pkg, version, source, strict = FALSE, repos = locked_package_repos()) {
  if (identical(source, "base")) return(invisible(FALSE))

  if (strict && !is.na(version) && nzchar(version)) {
    if (!requireNamespace("remotes", quietly = TRUE)) {
      utils::install.packages("remotes", repos = repos)
    }
    remotes::install_version(pkg, version = version, repos = repos, upgrade = "never")
  } else {
    utils::install.packages(pkg, repos = repos)
  }
  invisible(TRUE)
}

enforce_locked_packages <- function(packages = NULL, install = FALSE, load = FALSE, strict = FALSE, warn = FALSE) {
  strict <- isTRUE(strict) || locked_package_truthy(Sys.getenv("R_PACKAGE_STRICT"))
  deps <- locked_package_read_lock()

  if (!is.null(packages)) {
    missing_from_lock <- setdiff(packages, deps$package)
    if (length(missing_from_lock) > 0) {
      stop("Packages missing from R dependency lock: ", paste(missing_from_lock, collapse = ", "))
    }
    deps <- deps[deps$package %in% packages, , drop = FALSE]
  }

  status <- locked_package_check(deps, strict = strict)
  needs_work <- status[!status$ok, , drop = FALSE]

  if (install && nrow(needs_work) > 0) {
    for (pkg in needs_work$package) {
      row <- deps[deps$package == pkg, ][1, ]
      message("Installing R package ", pkg, if (strict) paste0(" ", row$version) else "", "...")
      tryCatch(
        locked_package_install(pkg, row$version, row$source, strict = strict),
        error = function(e) message("Failed to install ", pkg, ": ", conditionMessage(e))
      )
    }
    status <- locked_package_check(deps, strict = strict)
  }

  failures <- status[!status$ok, , drop = FALSE]
  if (nrow(failures) > 0) {
    detail <- paste(
      failures$package,
      "(required: ", failures$required_version, ", installed: ", ifelse(is.na(failures$installed_version), "missing", failures$installed_version), ")",
      sep = "",
      collapse = ", "
    )
    stop(
      "R package requirements are not satisfied: ", detail,
      ". Run Rscript code/setup_r_packages.R",
      if (strict) " --strict" else "",
      " from the repository root."
    )
  }

  version_mismatch <- status$installed & !is.na(status$required_version) &
    nzchar(status$required_version) & status$installed_version != status$required_version
  if (isTRUE(warn) && !strict && any(version_mismatch)) {
    warning(
      "Using installed R package versions that differ from code/dependencies/r_packages.csv: ",
      paste(status$package[version_mismatch], collapse = ", "),
      ". Use R_PACKAGE_STRICT=TRUE or --strict in setup_r_packages.R to require exact versions.",
      call. = FALSE
    )
  }

  if (isTRUE(load)) {
    for (pkg in deps$package) {
      if (!identical(deps$source[deps$package == pkg][1], "base")) {
        suppressPackageStartupMessages(library(pkg, character.only = TRUE))
      }
    }
  }

  invisible(status)
}

check_locked_packages <- function(packages = NULL, strict = FALSE) {
  enforce_locked_packages(packages = packages, install = FALSE, load = FALSE, strict = strict, warn = TRUE)
}
