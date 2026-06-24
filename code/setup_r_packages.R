args <- commandArgs(trailingOnly = TRUE)
check_only <- "--check-only" %in% args

.locked_package_helper <- c(
  "code/dependencies/locked_packages.R",
  "dependencies/locked_packages.R",
  "../dependencies/locked_packages.R",
  "../../dependencies/locked_packages.R"
)
.locked_package_helper <- .locked_package_helper[file.exists(.locked_package_helper)][1]
if (is.na(.locked_package_helper)) {
  stop("Could not find code/dependencies/locked_packages.R.")
}

source(.locked_package_helper)
enforce_locked_packages(install = !check_only, load = FALSE)

message("R package setup complete.")
