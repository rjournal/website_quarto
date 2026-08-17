collections <- c("_articles", "_news")
render_formats <- "html"
use_cache <- TRUE
minimum_render_body_chars <- 500L
render_timeout <- 300
render_log_path <- NULL

script_files <- vapply(sys.frames(), function(frame) if (is.null(frame$ofile)) NA_character_ else frame$ofile, character(1))
script_files <- script_files[!is.na(script_files)]
script_file <- if (length(script_files)) script_files[[length(script_files)]] else sub("^--file=", "", grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)[[1]])
source(file.path(dirname(normalizePath(script_file, mustWork = TRUE)), "utils", "script.R"), local = TRUE)

render_script_dir <- function() {
  script_dir()
}

configure_render_options <- function(
  collection_names = collections,
  timeout = render_timeout,
  log_path = render_log_path,
  cache = use_cache
) {
  collections <<- collection_names
  render_timeout <<- timeout
  render_log_path <<- log_path
  use_cache <<- cache
  invisible(list(
    collections = collections,
    render_timeout = render_timeout,
    render_log_path = render_log_path,
    use_cache = use_cache
  ))
}

project_root <- function() normalizePath(getwd(), mustWork = TRUE)

tmp_root <- function(root = project_root()) {
  path <- file.path(root, "tmp")
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  normalizePath(path, mustWork = TRUE)
}

configure_render_env <- function(root = project_root()) {
  tmp <- tmp_root(root)
  Sys.setenv(TMPDIR = tmp, TMP = tmp, TEMP = tmp, KMP_TMPDIR = tmp)
  invisible(tmp)
}

default_render_log_path <- function(root = project_root()) {
  file.path(tmp_root(root), "render.log")
}

normalize_render_log_path <- function(path, root = project_root()) {
  if (is.null(path) || !nzchar(path)) {
    return(default_render_log_path(root))
  }
  if (grepl("^(/|[A-Za-z]:[/\\\\])", path)) {
    return(path)
  }
  file.path(root, path)
}

setup_render_logger <- function(root = project_root()) {
  render_log_path <<- normalize_render_log_path(render_log_path, root = root)
  dir.create(dirname(render_log_path), recursive = TRUE, showWarnings = FALSE)
  if (requireNamespace("logger", quietly = TRUE)) {
    logger::log_appender(logger::appender_file(render_log_path), namespace = "rjournal.render")
    logger::log_threshold(logger::TRACE, namespace = "rjournal.render")
  }
  invisible(render_log_path)
}

render_log <- function(level, message) {
  if (requireNamespace("logger", quietly = TRUE)) {
    logger_level <- switch(
      as.character(level),
      TRACE = logger::TRACE,
      INFO = logger::INFO,
      WARN = logger::WARN,
      ERROR = logger::ERROR,
      level
    )
    logger::log_level(logger_level, message, namespace = "rjournal.render")
  } else if (!is.null(render_log_path) && nzchar(render_log_path)) {
    cat(
      sprintf("%s %s %s\n", format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"), as.character(level), message),
      file = render_log_path,
      append = TRUE
    )
  }
  invisible(TRUE)
}

render_trace <- function(message) render_log("TRACE", message)
render_info <- function(message) render_log("INFO", message)
render_warn <- function(message) render_log("WARN", message)
render_error <- function(message) render_log("ERROR", message)

condition_message_text <- function(condition) {
  if (inherits(condition, "condition")) {
    conditionMessage(condition)
  } else {
    as.character(condition)
  }
}

classify_render_error <- function(condition) {
  message <- condition_message_text(condition)
  if (inherits(condition, "TimeoutException") || grepl("timeout|timed out|elapsed time limit", message, ignore.case = TRUE)) {
    return("timeout")
  }
  if (grepl("Missing archive", message, fixed = TRUE)) {
    return("missing_archive")
  }
  "error"
}

format_output_file <- function(item_dir, slug, format) {
  file.path(item_dir, paste0(slug, ".", if (identical(format, "html")) "html" else format))
}

missing_render_formats <- function(item_dir, slug) {
  render_formats[!vapply(render_formats, function(format) file.exists(format_output_file(item_dir, slug, format)), logical(1))]
}

skip_row <- function(item_dir, slug, status) {
  render_item_row(item_dir, slug, status)
}

render_item_row <- function(item_dir, slug, status) {
  data.frame(
    collection = basename(dirname(item_dir)),
    slug = slug,
    status = status,
    html = file.exists(file.path(item_dir, paste0(slug, ".html"))),
    pdf = file.exists(file.path(item_dir, paste0(slug, ".pdf"))),
    stringsAsFactors = FALSE
  )
}

discover_items <- function(root = project_root(), collection_names = collections, sample_n = NULL, seed = 1L) {
  rows <- lapply(collection_names, function(collection) {
    dirs <- sort(list.dirs(file.path(root, collection), recursive = FALSE, full.names = TRUE))
    data.frame(collection = collection, item_dir = dirs, slug = basename(dirs), stringsAsFactors = FALSE)
  })
  items <- do.call(rbind, rows)
  if (!is.null(sample_n) && nrow(items) > 0) {
    set.seed(seed)
    items <- items[sort(sample(seq_len(nrow(items)), min(sample_n, nrow(items)))), , drop = FALSE]
  }
  rownames(items) <- NULL
  items
}

discover_pending_items <- function(root = project_root(), collection_names = collections, sample_n = NULL, seed = 1L) {
  items <- discover_items(
    root = root,
    collection_names = collection_names,
    sample_n = sample_n,
    seed = seed
  )
  if (nrow(items) == 0) {
    return(items)
  }
  pending <- vapply(
    seq_len(nrow(items)),
    function(index) length(missing_render_formats(items$item_dir[[index]], items$slug[[index]])) > 0,
    logical(1)
  )
  items[pending, , drop = FALSE]
}

source(file.path(render_script_dir(), "render", "rmarkdown.R"), local = TRUE)
source(file.path(render_script_dir(), "render", "archive.R"), local = TRUE)

render_item_safely <- function(item_dir, root = project_root()) {
  slug <- basename(item_dir)
  render_info(paste0(
    "event=render_item_started collection=", basename(dirname(item_dir)),
    " slug=", slug
  ))
  result <- tryCatch(
    render_item(item_dir, root = root),
    error = function(error) {
      reason <- classify_render_error(error)
      render_error(paste0(
        "event=render_item_failed collection=", basename(dirname(item_dir)),
        " slug=", slug,
        " reason=", reason,
        " message=", condition_message_text(error)
      ))
      skip_row(item_dir, slug, if (identical(reason, "timeout")) "timeout" else "item_error")
    }
  )
  result
}

render_failure_statuses <- c("item_error", "timeout")

render_result_has_failures <- function(result) {
  is.data.frame(result) &&
    "status" %in% names(result) &&
    any(result$status %in% render_failure_statuses)
}

render_result_exit_status <- function(result) {
  if (render_result_has_failures(result)) 1L else 0L
}

render_one_item <- function(
  item_dir,
  root = project_root(),
  timeout = render_timeout,
  log_path = render_log_path,
  cache = use_cache
) {
  configure_render_options(timeout = timeout, log_path = log_path, cache = cache)
  configure_render_env(root)
  setup_render_logger(root)
  render_item_safely(item_dir, root = root)
}
