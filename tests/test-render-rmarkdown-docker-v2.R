repo <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
script <- file.path(repo, "_scripts", "render.R")
docker_script <- file.path(repo, "_scripts", "render_rmarkdown_to_html_v2.sh")
dockerfile <- file.path(repo, "_scripts", "render", "docker", "Dockerfile")
entrypoint <- file.path(repo, "_scripts", "render", "docker", "entrypoint.sh")

stopifnot(file.exists(script))
stopifnot(file.exists(docker_script))
stopifnot(file.access(docker_script, mode = 1) == 0)
stopifnot(file.exists(dockerfile))
stopifnot(file.exists(entrypoint))
stopifnot(file.access(entrypoint, mode = 1) == 0)

docker_script_lines <- readLines(docker_script, warn = FALSE)
dockerfile_lines <- readLines(dockerfile, warn = FALSE)
entrypoint_lines <- readLines(entrypoint, warn = FALSE)

stopifnot(any(grepl('docker --config "$DOCKER_CONFIG_DIR" build', docker_script_lines, fixed = TRUE)))
stopifnot(any(grepl("dockerfile_hash", docker_script_lines, fixed = TRUE)))
stopifnot(any(grepl("org.rjournal.render.dockerfile-sha", docker_script_lines, fixed = TRUE)))
stopifnot(any(grepl("Docker image %s is stale", docker_script_lines, fixed = TRUE)))
stopifnot(any(grepl("DOCKER_CONFIG_DIR=", docker_script_lines, fixed = TRUE)))
stopifnot(any(grepl("RJOURNAL_RENDER_DOCKER_CONFIG", docker_script_lines, fixed = TRUE)))
stopifnot(any(grepl("RJOURNAL_RENDER_DOCKER_BUILDKIT", docker_script_lines, fixed = TRUE)))
stopifnot(any(grepl('export DOCKER_CONFIG="$DOCKER_CONFIG_DIR"', docker_script_lines, fixed = TRUE)))
stopifnot(any(grepl("docker_cli()", docker_script_lines, fixed = TRUE)))
stopifnot(any(grepl("docker_cli create", docker_script_lines, fixed = TRUE)))
stopifnot(any(grepl("docker_cli inspect", docker_script_lines, fixed = TRUE)))
stopifnot(any(grepl('docker --config "$DOCKER_CONFIG_DIR" build', docker_script_lines, fixed = TRUE)))
stopifnot(any(grepl("--memory", docker_script_lines, fixed = TRUE)))
stopifnot(any(grepl("--memory-swap", docker_script_lines, fixed = TRUE)))
stopifnot(any(grepl("RJOURNAL_RENDER_DOCKER_MEMORY", docker_script_lines, fixed = TRUE)))
stopifnot(any(grepl("RJOURNAL_RENDER_DOCKER_WORKERS", docker_script_lines, fixed = TRUE)))
stopifnot(any(grepl("RJOURNAL_RENDER_DOCKER_ITEM_TIMEOUT", docker_script_lines, fixed = TRUE)))
stopifnot(any(grepl('MEMORY="${RJOURNAL_RENDER_DOCKER_MEMORY:-8g}"', docker_script_lines, fixed = TRUE)))
stopifnot(any(grepl('docker_item_timeout="${RJOURNAL_RENDER_DOCKER_ITEM_TIMEOUT:-300}"', docker_script_lines, fixed = TRUE)))
stopifnot(any(grepl("render_timeout=300", docker_script_lines, fixed = TRUE)))
stopifnot(any(grepl("docker_workers=", docker_script_lines, fixed = TRUE)))
stopifnot(any(grepl("docker_item_timeout=", docker_script_lines, fixed = TRUE)))
stopifnot(any(grepl("set_docker_workers", docker_script_lines, fixed = TRUE)))
stopifnot(any(grepl("set_docker_item_timeout", docker_script_lines, fixed = TRUE)))
stopifnot(any(grepl("--container-timeout", docker_script_lines, fixed = TRUE)))
stopifnot(any(grepl('timeout --kill-after=10s "${docker_item_timeout}s"', docker_script_lines, fixed = TRUE)))
stopifnot(any(grepl("render_container_timed_out", docker_script_lines, fixed = TRUE)))
stopifnot(any(grepl("render-package-install.lock", readLines(file.path(repo, "_scripts", "render", "rmarkdown.R"), warn = FALSE), fixed = TRUE)))
stopifnot(any(grepl("wait -n", docker_script_lines, fixed = TRUE)))
stopifnot(any(grepl("render-container-logs", docker_script_lines, fixed = TRUE)))
stopifnot(any(grepl("Container log:", docker_script_lines, fixed = TRUE)))
stopifnot(any(grepl("render_container_create_started", docker_script_lines, fixed = TRUE)))
stopifnot(any(grepl("render_container_starting", docker_script_lines, fixed = TRUE)))
stopifnot(any(grepl("render_container_finished", docker_script_lines, fixed = TRUE)))
stopifnot(any(grepl("render_item_completed", docker_script_lines, fixed = TRUE)))
stopifnot(!any(grepl("render_item_skipped_before_container", docker_script_lines, fixed = TRUE)))
stopifnot(!any(grepl("collect_missing_html_item", docker_script_lines, fixed = TRUE)))
stopifnot(any(grepl("discover_pending_items", docker_script_lines, fixed = TRUE)))
stopifnot(any(grepl("R_LIST_ITEMS", docker_script_lines, fixed = TRUE)))
stopifnot(any(grepl("R_RENDER_ITEM", docker_script_lines, fixed = TRUE)))
stopifnot(any(grepl("item_host_html_file", docker_script_lines, fixed = TRUE)))
stopifnot(any(grepl("No new render items found", docker_script_lines, fixed = TRUE)))
stopifnot(any(grepl("pending_items", docker_script_lines, fixed = TRUE)))
stopifnot(!any(grepl("^items=\\(\\)", docker_script_lines)))
stopifnot(any(grepl("last_item_outcome", docker_script_lines, fixed = TRUE)))
stopifnot(any(grepl("Skipped existing", docker_script_lines, fixed = TRUE)))
stopifnot(any(grepl("Created %s.html", docker_script_lines, fixed = TRUE)))
stopifnot(any(grepl("Discovering pending render items", docker_script_lines, fixed = TRUE)))
stopifnot(any(grepl("Failed to discover pending render items", docker_script_lines, fixed = TRUE)))
stopifnot(any(grepl("rjournal-render-entrypoint", docker_script_lines, fixed = TRUE)))
stopifnot(any(grepl(".xvfb.log", docker_script_lines, fixed = TRUE)))
stopifnot(any(grepl("Xvfb :99", entrypoint_lines, fixed = TRUE)))
stopifnot(any(grepl("xdpyinfo -display :99", entrypoint_lines, fixed = TRUE)))
stopifnot(any(grepl("--security-opt seccomp=unconfined", docker_script_lines, fixed = TRUE)))
stopifnot(any(grepl("bspm_enabled", readLines(file.path(repo, "_scripts", "render", "rmarkdown.R"), warn = FALSE), fixed = TRUE)))
stopifnot(any(grepl('install.packages.compile.from.source = "never"', readLines(file.path(repo, "_scripts", "render", "rmarkdown.R"), warn = FALSE), fixed = TRUE)))
stopifnot(any(grepl("RJOURNAL_RENDER_USE_SYSTEM_LIBRARY=1", docker_script_lines, fixed = TRUE)))
stopifnot(any(grepl("render_result_exit_status", docker_script_lines, fixed = TRUE)))
stopifnot(any(grepl("require_docker_access", docker_script_lines, fixed = TRUE)))
stopifnot(any(grepl("requested_item=", docker_script_lines, fixed = TRUE)))
stopifnot(any(grepl("list_only=", docker_script_lines, fixed = TRUE)))
stopifnot(any(grepl("--item=*", docker_script_lines, fixed = TRUE)))
stopifnot(any(grepl("--list-items", docker_script_lines, fixed = TRUE)))
stopifnot(any(grepl('run_item_with_progress "$requested_item"', docker_script_lines, fixed = TRUE)))
stopifnot(any(grepl("cleanup_containers", docker_script_lines, fixed = TRUE)))
stopifnot(any(grepl("Docker render --log paths must be under tmp/", docker_script_lines, fixed = TRUE)))
stopifnot(any(grepl("Docker is not reachable by this user.", docker_script_lines, fixed = TRUE)))
stopifnot(!any(grepl("--env R_PROFILE=/dev/null", docker_script_lines, fixed = TRUE)))
stopifnot(!any(grepl("bspm::disable", docker_script_lines, fixed = TRUE)))
stopifnot(!any(grepl("RJOURNAL_RENDER_PACKAGE_LIBRARY", docker_script_lines, fixed = TRUE)))
stopifnot(!any(grepl("--args", docker_script_lines, fixed = TRUE)))
stopifnot(!any(grepl("run_render_cli", docker_script_lines, fixed = TRUE)))
stopifnot(!any(grepl("R_RUNNER", docker_script_lines, fixed = TRUE)))
stopifnot(!any(grepl("bulle", docker_script_lines, fixed = TRUE)))

docker_help <- system2(docker_script, "--help", stdout = TRUE, stderr = TRUE)
stopifnot(is.null(attr(docker_help, "status")))
stopifnot(any(grepl("Render archived R Markdown articles in Docker.", docker_help, fixed = TRUE)))

bad_log <- suppressWarnings(system2(
  docker_script,
  c("--log=logs/render.log", "--list-items"),
  stdout = TRUE,
  stderr = TRUE
))
stopifnot(identical(attr(bad_log, "status"), 2L))
stopifnot(any(grepl("Docker render --log paths must be under tmp/", bad_log, fixed = TRUE)))

bad_workers <- suppressWarnings(system2(
  docker_script,
  c("--workers=0", "--list-items"),
  stdout = TRUE,
  stderr = TRUE
))
stopifnot(identical(attr(bad_workers, "status"), 2L))
stopifnot(any(grepl("--workers must be a positive integer", bad_workers, fixed = TRUE)))

bad_timeout <- suppressWarnings(system2(
  docker_script,
  c("--container-timeout=abc", "--list-items"),
  stdout = TRUE,
  stderr = TRUE
))
stopifnot(identical(attr(bad_timeout, "status"), 2L))
stopifnot(any(grepl("--container-timeout must be a non-negative integer", bad_timeout, fixed = TRUE)))

dockerfile_text <- paste(dockerfile_lines, collapse = "\n")
stopifnot(grepl("FROM rocker/r2u:24.04", dockerfile_text, fixed = TRUE))
stopifnot(grepl("pandoc", dockerfile_text, fixed = TRUE))
stopifnot(!grepl("r-cran-docopt", dockerfile_text, fixed = TRUE))
stopifnot(grepl("r-cran-coda", dockerfile_text, fixed = TRUE))
stopifnot(grepl("r-cran-data.table", dockerfile_text, fixed = TRUE))
stopifnot(grepl("r-cran-marginaleffects", dockerfile_text, fixed = TRUE))
stopifnot(grepl("r-cran-modelsummary", dockerfile_text, fixed = TRUE))
stopifnot(grepl("r-cran-emd", dockerfile_text, fixed = TRUE))
stopifnot(grepl("r-cran-mvtnorm", dockerfile_text, fixed = TRUE))
stopifnot(grepl("r-cran-remotes", dockerfile_text, fixed = TRUE))
stopifnot(grepl("r-cran-renv", dockerfile_text, fixed = TRUE))
stopifnot(grepl("r-cran-rmarkdown", dockerfile_text, fixed = TRUE))
stopifnot(grepl("r-cran-sf", dockerfile_text, fixed = TRUE))
stopifnot(grepl("r-cran-snow", dockerfile_text, fixed = TRUE))
stopifnot(grepl("r-cran-gwidgets2tcltk", dockerfile_text, fixed = TRUE))
stopifnot(grepl("r-cran-tcltk2", dockerfile_text, fixed = TRUE))
stopifnot(grepl("r-cran-tidyverse", dockerfile_text, fixed = TRUE))
stopifnot(grepl("r-cran-tkrplot", dockerfile_text, fixed = TRUE))
stopifnot(grepl("r-cran-yaml12", dockerfile_text, fixed = TRUE))
stopifnot(grepl("tk-table", dockerfile_text, fixed = TRUE))
stopifnot(grepl("tklib", dockerfile_text, fixed = TRUE))
stopifnot(grepl("x11-utils", dockerfile_text, fixed = TRUE))
stopifnot(grepl("xvfb", dockerfile_text, fixed = TRUE))
stopifnot(grepl("COPY entrypoint.sh /usr/local/bin/rjournal-render-entrypoint", dockerfile_text, fixed = TRUE))
stopifnot(!grepl("install.packages", dockerfile_text, fixed = TRUE))
stopifnot(!grepl("bspm::disable", dockerfile_text, fixed = TRUE))
stopifnot(!grepl('type = "source"', dockerfile_text, fixed = TRUE))
stopifnot(!grepl("MARGINALEFFECTS_REF", dockerfile_text, fixed = TRUE))
stopifnot(grepl('remotes::install_github("rjournal/rjtools")', dockerfile_text, fixed = TRUE))
stopifnot(!grepl("vincentarelbundock/marginaleffects", dockerfile_text, fixed = TRUE))

project <- tempfile("render-rmarkdown-docker-v2-")
dir.create(project)
oldwd <- setwd(project)
on.exit(setwd(oldwd), add = TRUE)

env <- new.env(parent = baseenv())
source(script, local = env)

stopifnot(identical(
  env$render_result_exit_status(data.frame(status = "rendered", stringsAsFactors = FALSE)),
  0L
))
stopifnot(identical(
  env$render_result_exit_status(data.frame(status = "item_error", stringsAsFactors = FALSE)),
  1L
))
stopifnot(identical(
  env$render_result_exit_status(data.frame(status = "timeout", stringsAsFactors = FALSE)),
  1L
))
stopifnot(!exists("render_cli_doc", envir = env, inherits = FALSE))
stopifnot(!exists("parse_render_args", envir = env, inherits = FALSE))
stopifnot(!exists("run_render_cli", envir = env, inherits = FALSE))

dir.create(file.path(project, "_articles", "RJ-2099-001"), recursive = TRUE)
dir.create(file.path(project, "_articles", "RJ-2099-002"), recursive = TRUE)
dir.create(file.path(project, "_news"), recursive = TRUE)
file.create(file.path(project, "_articles", "RJ-2099-002", "RJ-2099-002.html"))

env$configure_render_options(
  collection_names = "_articles",
  timeout = 7L,
  log_path = "tmp/custom-render.log",
  cache = FALSE
)
stopifnot(identical(env$collections, "_articles"))
stopifnot(identical(env$render_timeout, 7L))
stopifnot(identical(env$render_log_path, "tmp/custom-render.log"))
stopifnot(identical(env$use_cache, FALSE))

listed <- env$discover_items(root = project, collection_names = "_articles")
stopifnot(identical(listed$item_dir, file.path(project, "_articles", c("RJ-2099-001", "RJ-2099-002"))))
pending <- env$discover_pending_items(root = project, collection_names = "_articles")
stopifnot(identical(pending$item_dir, file.path(project, "_articles", "RJ-2099-001")))

called_item <- NULL
env$render_item_safely <- function(item_dir, root = env$project_root()) {
  called_item <<- item_dir
  data.frame(collection = "_articles", slug = basename(item_dir), status = "rendered")
}
env$setup_render_logger <- function(root = env$project_root()) {
  invisible(file.path(root, "tmp", "render.log"))
}
item_result <- env$render_one_item(
  "_articles/RJ-2099-001",
  root = project,
  timeout = 9L,
  log_path = "tmp/item-render.log",
  cache = TRUE
)
stopifnot(identical(called_item, "_articles/RJ-2099-001"))
stopifnot(identical(item_result$status, "rendered"))
stopifnot(identical(env$render_timeout, 9L))
stopifnot(identical(env$render_log_path, "tmp/item-render.log"))
stopifnot(identical(env$use_cache, TRUE))
