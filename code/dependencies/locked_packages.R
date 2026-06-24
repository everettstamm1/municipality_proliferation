locked_package_find_repo_root <- function() {
  candidates <- unique(normalizePath(c(
    getwd(),
    file.path(getwd(), ".."),
    file.path(getwd(), "..", ".."),
    file.path(getwd(), "..", "..", "..")
  ), winslash = "/", mustWork = FALSE))

  for (candidate in candidates) {
    lock_file <- file.path(candidate, "code", "dependencies", "r_packages.csv")
    if (file.exists(lock_file)) return(candidate)
  }

  for (candidate in candidates) {
    paths_file <- file.path(candidate, "paths.csv")
    if (!file.exists(paths_file)) next
    paths <- tryCatch(read.csv(paths_file, stringsAsFactors = FALSE), error = function(e) NULL)
    if (is.null(paths) || !all(c("global", "path") %in% names(paths))) next
    repo <- paths$path[paths$global == "REPO"][1]
    if (!is.na(repo) && file.exists(file.path(repo, "code", "dependencies", "r_packages.csv"))) {
      return(normalizePath(repo, winslash = "/", mustWork = TRUE))
    }
  }

  stop("Could not find code/dependencies/r_packages.csv. Run from the repository root or after paths.csv has been created.")
}

locked_package_read_lock <- function() {
  lock_file <- file.path(locked_package_find_repo_root(), "code", "dependencies", "r_packages.csv")
  deps <- read.csv(
    lock_file,
    stringsAsFactors = FALSE,
    na.strings = c("", "NA"),
    strip.white = TRUE
  )

  required_cols <- c("package", "version", "source")
  missing_cols <- setdiff(required_cols, names(deps))
  if (length(missing_cols) > 0) {
    stop("R dependency lock is missing columns: ", paste(missing_cols, collapse = ", "))
  }

  deps$package <- trimws(deps$package)
  deps$version <- trimws(deps$version)
  deps$source <- tolower(trimws(deps$source))
  deps[nzchar(deps$package), ]
}

locked_package_repos <- function() {
  repos <- getOption("repos")
  if (is.null(repos) || is.na(repos["CRAN"]) || repos["CRAN"] == "@CRAN@") {
    repos <- c(CRAN = "https://cloud.r-project.org")
  }
  repos
}

locked_package_version_ok <- function(pkg, required_version) {
  if (!requireNamespace(pkg, quietly = TRUE)) return(FALSE)
  if (is.na(required_version) || !nzchar(required_version)) return(TRUE)
  utils::packageVersion(pkg) == package_version(required_version)
}

locked_package_install_remotes <- function(repos) {
  if (requireNamespace("remotes", quietly = TRUE)) return(invisible(TRUE))
  message("Installing remotes from CRAN to restore locked package versions...")
  utils::install.packages("remotes", repos = repos)
  requireNamespace("remotes", quietly = TRUE)
}

enforce_locked_packages <- function(packages = NULL, install = TRUE, load = FALSE) {
  deps <- locked_package_read_lock()
  if (!is.null(packages)) {
    missing_lock <- setdiff(packages, deps$package)
    if (length(missing_lock) > 0) {
      stop("Packages missing from R dependency lock: ", paste(missing_lock, collapse = ", "))
    }
    deps <- deps[deps$package %in% packages, ]
  }

  repos <- locked_package_repos()
  failures <- character()

  for (i in seq_len(nrow(deps))) {
    pkg <- deps$package[i]
    required_version <- deps$version[i]
    source <- deps$source[i]

    if (!locked_package_version_ok(pkg, required_version)) {
      if (!install || source == "base" || source != "cran") {
        failures <- c(failures, pkg)
        next
      }

      installed_version <- if (requireNamespace(pkg, quietly = TRUE)) {
        as.character(utils::packageVersion(pkg))
      } else {
        "not installed"
      }
      message("Installing ", pkg, " version ", required_version, " from CRAN; current version is ", installed_version, ".")

      tryCatch({
        if (!locked_package_install_remotes(repos)) stop("could not install or load remotes")
        remotes::install_version(pkg, version = required_version, repos = repos, upgrade = "never")
      }, error = function(e) {
        message("Failed to install ", pkg, ": ", conditionMessage(e))
      })
    }

    if (!locked_package_version_ok(pkg, required_version)) {
      failures <- c(failures, pkg)
      next
    }

    if (isTRUE(load)) {
      suppressPackageStartupMessages(library(pkg, character.only = TRUE))
    }
  }

  if (length(failures) > 0) {
    action <- if (install) "installed at" else "available at"
    stop(
      "The following R packages are not ",
      action,
      " the locked version: ",
      paste(unique(failures), collapse = ", ")
    )
  }

  invisible(deps)
}
