require("ragg")

strip_yaml_front_matter <- function(lines) {
  if (length(lines) < 2 || !identical(trimws(lines[[1]]), "---")) {
    return(lines)
  }

  end <- which(trimws(lines[-1]) %in% c("---", "..."))
  if (length(end) == 0) {
    return(lines)
  }

  lines[-seq_len(end[[1]] + 1L)]
}

rmd_has_content <- function(lines) {
  body <- strip_yaml_front_matter(lines)
  any(nzchar(trimws(body)))
}

rmd_body_character_count <- function(lines) {
  nchar(trimws(paste(strip_yaml_front_matter(lines), collapse = "\n")))
}

extract_yaml_front_matter <- function(lines) {
  if (length(lines) < 2 || !identical(trimws(lines[[1]]), "---")) {
    return(character())
  }

  end <- which(trimws(lines[-1]) %in% c("---", "..."))
  if (length(end) == 0) {
    return(character())
  }

  lines[seq.int(2L, end[[1]])]
}

extract_render_metadata <- function(lines) {
  yaml_lines <- extract_yaml_front_matter(lines)
  if (length(yaml_lines) == 0) {
    return(list())
  }
  if (!requireNamespace("yaml12", quietly = TRUE)) {
    stop("The yaml12 package is required to preserve metadata.", call. = FALSE)
  }

  yaml_lines <- gsub(
    "rjtools::rjournal_web_article",
    "html_document",
    yaml_lines,
    fixed = TRUE
  )
  metadata <- yaml12::parse_yaml(yaml_lines, simplify = FALSE)
  if (is.null(metadata) || !is.list(metadata)) {
    return(list())
  }

  fields <- c("title", "abstract", "bibliography", "output")
  metadata[fields[fields %in% names(metadata)]]
}

default_output_metadata <- function() {
  list(
    html_document = list(
      self_contained = TRUE,
      theme = NA,
      toc = FALSE
    )
  )
}

render_metadata_yaml <- function(metadata) {
  if (!requireNamespace("yaml12", quietly = TRUE)) {
    stop("The yaml12 package is required to write metadata.", call. = FALSE)
  }
  if (is.null(metadata[["output"]])) {
    metadata[["output"]] <- default_output_metadata()
  }

  lines <- strsplit(yaml12::format_yaml(metadata), "\n", fixed = TRUE)[[1]]
  lines[nzchar(lines)]
}

embed_resources_yaml <- function(cache = use_cache, metadata = list()) {
  cache_lines <- if (isTRUE(cache)) {
    c(
      "```{r render-cache-setup, include=FALSE}",
      "knitr::opts_chunk$set(cache = TRUE)",
      "```",
      ""
    )
  } else {
    character()
  }

  c(
    "---",
    render_metadata_yaml(metadata),
    "---",
    "",
    cache_lines
  )
}

write_embed_resources_rmd <- function(source_rmd, cache = use_cache) {
  lines <- readLines(source_rmd, warn = FALSE)
  metadata <- extract_render_metadata(lines)
  body <- strip_yaml_front_matter(lines)
  output <- file.path(dirname(source_rmd), "embed_resources.Rmd")
  writeLines(c(embed_resources_yaml(cache = cache, metadata = metadata), body), output, useBytes = TRUE)
  output
}

use_system_package_library <- function() {
  tolower(Sys.getenv("RJOURNAL_RENDER_USE_SYSTEM_LIBRARY", "")) %in% c("1", "true", "yes")
}

install_missing_dependencies <- function() {
  tolower(Sys.getenv("RJOURNAL_RENDER_INSTALL_MISSING", "1")) %in% c("1", "true", "yes")
}

package_library <- function(root = project_root()) {
  path <- Sys.getenv("RJOURNAL_RENDER_PACKAGE_LIBRARY", "")
  if (!nzchar(path)) {
    path <- tempfile(pattern = paste0("lib-", Sys.getpid(), "-"), tmpdir = tmp_root(root))
    Sys.setenv(RJOURNAL_RENDER_PACKAGE_LIBRARY = path)
  }
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  normalizePath(path, mustWork = TRUE)
}

configure_package_library <- function(root = project_root()) {
  if (use_system_package_library()) {
    return(invisible(NULL))
  }

  lib <- package_library(root)
  .libPaths(unique(c(lib, .libPaths())))
  Sys.setenv(R_LIBS = paste(.libPaths(), collapse = .Platform$path.sep), R_LIBS_USER = lib)
  invisible(lib)
}

render_package_repositories <- function() {
  c(CRAN = Sys.getenv("RJOURNAL_CRAN_REPOSITORY", "https://cloud.r-project.org"))
}

enable_bspm <- function() {
  bspm::enable()
}

configure_system_package_install <- function() {
  if (!use_system_package_library()) {
    return(invisible(FALSE))
  }
  if (isTRUE(getOption("rjournal.render.bspm.enabled", FALSE))) {
    return(invisible(TRUE))
  }
  if (!requireNamespace("bspm", quietly = TRUE)) {
    stop("The bspm package is required for r2u-backed Docker package installation.", call. = FALSE)
  }

  options(install.packages.compile.from.source = "never")
  suppressMessages(enable_bspm())
  options(rjournal.render.bspm.enabled = TRUE)
  if (exists("render_info", mode = "function")) {
    render_info("event=bspm_enabled method=r2u")
  }
  invisible(TRUE)
}

install_render_packages <- function(packages, lib = NULL, repos = render_package_repositories()) {
  configure_system_package_install()
  args <- list(pkgs = packages, repos = repos, dependencies = NA)
  if (!is.null(lib)) {
    args$lib <- lib
  }
  do.call(utils::install.packages, args)
}

install_lock_path <- function(root = project_root()) {
  Sys.getenv("RJOURNAL_RENDER_INSTALL_LOCK", file.path(tmp_root(root), "render-package-install.lock"))
}

install_lock_timeout <- function() {
  value <- Sys.getenv("RJOURNAL_RENDER_INSTALL_LOCK_TIMEOUT", "1800")
  parsed <- suppressWarnings(as.numeric(value))
  if (!is.finite(parsed) || parsed < 1) {
    stop("RJOURNAL_RENDER_INSTALL_LOCK_TIMEOUT must be a positive number of seconds.", call. = FALSE)
  }
  parsed
}

with_render_install_lock <- function(root = project_root(), code) {
  code <- substitute(code)
  lock <- install_lock_path(root)
  timeout <- install_lock_timeout()
  started <- Sys.time()
  acquired <- FALSE

  repeat {
    if (dir.create(lock, recursive = FALSE, showWarnings = FALSE)) {
      acquired <- TRUE
      writeLines(
        c(
          paste0("pid=", Sys.getpid()),
          paste0("time=", format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"))
        ),
        file.path(lock, "owner")
      )
      if (exists("render_info", mode = "function")) {
        render_info("event=package_install_lock_acquired")
      }
      break
    }

    elapsed <- as.numeric(difftime(Sys.time(), started, units = "secs"))
    if (elapsed > timeout) {
      stop("Timed out waiting for package install lock: ", lock, call. = FALSE)
    }

    if (exists("render_trace", mode = "function")) {
      render_trace("event=package_install_lock_waiting")
    }
    Sys.sleep(1)
  }

  on.exit({
    if (acquired) {
      unlink(lock, recursive = TRUE, force = TRUE)
      if (exists("render_info", mode = "function")) {
        render_info("event=package_install_lock_released")
      }
    }
  }, add = TRUE)

  eval(code, parent.frame())
}

base_or_recommended_packages <- function() {
  installed <- utils::installed.packages()
  rownames(installed)[installed[, "Priority"] %in% c("base", "recommended")]
}

detect_dependencies <- function(source_dir) {
  if (!requireNamespace("renv", quietly = TRUE)) {
    stop("The renv package is required to detect and install dependencies.", call. = FALSE)
  }

  deps <- renv::dependencies(source_dir, progress = FALSE)
  if (!"Package" %in% names(deps) || nrow(deps) == 0) {
    return(character())
  }

  packages <- unique(stats::na.omit(deps$Package))
  packages <- setdiff(packages, c("R", base_or_recommended_packages()))
  sort(packages)
}

install_dependencies <- function(packages, root = project_root()) {
  if (length(packages) == 0) {
    if (exists("render_trace", mode = "function")) {
      render_trace("event=dependency_install_skipped reason=no_packages")
    }
    return(invisible(character()))
  }

  lib <- configure_package_library(root)
  missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
  if (exists("render_info", mode = "function")) {
    render_info(paste0(
      "event=dependency_check packages=", paste(packages, collapse = ","),
      " missing=", if (length(missing) == 0) "none" else paste(missing, collapse = ",")
    ))
  }
  if (length(missing) > 0) {
    if (!install_missing_dependencies()) {
      if (exists("render_error", mode = "function")) {
        render_error(paste0(
          "event=dependency_install_disabled missing=", paste(missing, collapse = ",")
        ))
      }
      stop(
        "Missing package(s) in render image: ",
        paste(missing, collapse = ", "),
        ". Add them to the Dockerfile as r-cran-* packages when available.",
        call. = FALSE
      )
    }
    if (use_system_package_library()) {
      configure_system_package_install()
      with_render_install_lock(root, {
        missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
        if (length(missing) > 0) {
          if (exists("render_info", mode = "function")) {
            render_info(paste0(
              "event=dependency_install_started packages=", paste(missing, collapse = ",")
            ))
          }
          install_render_packages(missing, lib = lib, repos = render_package_repositories())
        }
      })
    } else {
      if (exists("render_info", mode = "function")) {
        render_info(paste0(
          "event=dependency_install_started packages=", paste(missing, collapse = ",")
        ))
      }
      install_render_packages(missing, lib = lib, repos = render_package_repositories())
    }
    still_missing <- missing[!vapply(missing, requireNamespace, logical(1), quietly = TRUE)]
    if (length(still_missing) > 0) {
      stop(
        "Could not install package(s): ",
        paste(still_missing, collapse = ", "),
        call. = FALSE
      )
    }
    if (exists("render_info", mode = "function")) {
      render_info(paste0(
        "event=dependency_install_finished packages=", paste(missing, collapse = ",")
      ))
    }
  }
  installed <- missing
  invisible(installed)
}

rmarkdown_output_format <- function(format) {
  if (!requireNamespace("rmarkdown", quietly = TRUE)) {
    stop("The rmarkdown package is required to render documents.", call. = FALSE)
  }

  if (identical(format, "html")) {
    dev <- if (requireNamespace("ragg", quietly = TRUE)) "ragg_png" else "png"
    return(rmarkdown::html_document(
      self_contained = TRUE,
      theme = NULL,
      toc = FALSE,
      dev = dev
    ))
  }

  stop("Unsupported render format: ", format, call. = FALSE)
}

strip_rendered_html_title <- function(path) {
  html <- paste(readLines(path, warn = FALSE), collapse = "\n")
  cleaned <- sub(
    "(?is)<h1\\b[^>]*class\\s*=\\s*(['\"])[^'\"]*\\btitle\\b[^'\"]*\\1[^>]*>.*?</h1>\\s*",
    "",
    html,
    perl = TRUE
  )
  if (!identical(cleaned, html)) {
    writeLines(strsplit(cleaned, "\n", fixed = TRUE)[[1]], path, useBytes = TRUE)
  }
  invisible(path)
}

render_with_rmarkdown <- function(input, output_dir, slug, format, root = project_root()) {
  input_dir <- dirname(input)
  before_output <- list.files(output_dir, all.files = TRUE, no.. = TRUE, full.names = TRUE)
  final_file <- format_output_file(output_dir, slug, format)
  rendered_file <- format_output_file(input_dir, slug, format)

  configure_render_env(root)
  configure_package_library(root)
  old_wd <- setwd(input_dir)
  on.exit(setwd(old_wd), add = TRUE)

  render_expr <- quote(rmarkdown::render(
    input = basename(input),
    output_format = rmarkdown_output_format(format),
    output_file = basename(rendered_file),
    output_dir = input_dir,
    clean = TRUE,
    quiet = FALSE,
    envir = new.env(parent = globalenv())
  ))

  utils::capture.output(
    if (is.null(render_timeout)) {
      eval(render_expr)
    } else {
      if (!requireNamespace("R.utils", quietly = TRUE)) {
        stop("The R.utils package is required for render timeouts.", call. = FALSE)
      }
      R.utils::withTimeout(eval(render_expr), timeout = render_timeout, onTimeout = "error")
    },
    type = "output"
  )

  if (!file.exists(rendered_file)) {
    stop("Expected temporary rendered file was not created: ", rendered_file, call. = FALSE)
  }

  if (identical(format, "html")) {
    strip_rendered_html_title(rendered_file)
  }

  if (!file.copy(rendered_file, final_file, overwrite = TRUE)) {
    stop("Could not copy rendered file to: ", final_file, call. = FALSE)
  }

  if (!file.exists(final_file)) {
    stop("Expected rendered file was not created: ", final_file, call. = FALSE)
  }

  if (identical(format, "html")) {
    after_output <- list.files(output_dir, all.files = TRUE, no.. = TRUE, full.names = TRUE)
    sidecar_output <- setdiff(after_output, c(before_output, final_file))
    unlink(sidecar_output, recursive = TRUE, force = TRUE)
  }

  invisible(final_file)
}

render_rmarkdown_file <- function(source_rmd, output_dir, slug, formats, source_dir = dirname(source_rmd), root = project_root()) {
  source_lines <- readLines(source_rmd, warn = FALSE)
  if (!rmd_has_content(source_lines)) {
    return("skipped_empty_body")
  }

  if ("html" %in% formats && rmd_body_character_count(source_lines) < minimum_render_body_chars) {
    return("skipped_short_body")
  }

  source_rmd_stripped <- write_embed_resources_rmd(source_rmd, cache = use_cache)

  if (exists("render_info", mode = "function")) {
    render_info(paste0(
      "event=dependency_detection_started source_dir=", source_dir
    ))
  }
  packages <- detect_dependencies(source_dir)
  if (exists("render_info", mode = "function")) {
    render_info(paste0(
      "event=dependency_detection_finished packages=",
      if (length(packages) == 0) "none" else paste(packages, collapse = ",")
    ))
  }
  install_dependencies(packages, root = root)

  for (format in formats) {
    if (exists("render_info", mode = "function")) {
      render_info(paste0(
        "event=rmarkdown_render_started slug=", slug,
        " format=", format
      ))
    }
    render_with_rmarkdown(source_rmd_stripped, output_dir, slug, format, root = root)
    if (exists("render_info", mode = "function")) {
      render_info(paste0(
        "event=rmarkdown_render_finished slug=", slug,
        " format=", format
      ))
    }
  }

  NULL
}
