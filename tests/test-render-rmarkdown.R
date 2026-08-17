repo <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
script <- file.path(repo, "_scripts", "render.R")
rmarkdown_module <- file.path(repo, "_scripts", "render", "rmarkdown.R")
archive_module <- file.path(repo, "_scripts", "render", "archive.R")
utils_dir <- file.path(repo, "_scripts", "utils")
legacy_script <- file.path(repo, "_scripts", "render_rmarkdown.R")

stopifnot(file.exists(script))
stopifnot(file.exists(rmarkdown_module))
stopifnot(file.exists(archive_module))
stopifnot(dir.exists(utils_dir))
stopifnot(!file.exists(legacy_script))

project <- tempfile("render-rmarkdown-")
dir.create(project)
oldwd <- setwd(project)
on.exit(setwd(oldwd), add = TRUE)

env <- new.env(parent = baseenv())
source(script, local = env)

stopifnot(exists("configure_render_options", envir = env, inherits = FALSE))
stopifnot(exists("discover_pending_items", envir = env, inherits = FALSE))
stopifnot(exists("render_one_item", envir = env, inherits = FALSE))
stopifnot(exists("classify_render_error", envir = env, inherits = FALSE))
stopifnot(!exists("render_cli_doc", envir = env, inherits = FALSE))
stopifnot(!exists("parse_render_args", envir = env, inherits = FALSE))
stopifnot(!exists("run_render_cli", envir = env, inherits = FALSE))
stopifnot(!exists("run_item_jobs", envir = env, inherits = FALSE))
stopifnot(!exists("render_all", envir = env, inherits = FALSE))
stopifnot(!exists("start_progress", envir = env, inherits = FALSE))
stopifnot(!exists("merge_render_logs", envir = env, inherits = FALSE))

env$configure_render_options(
  collection_names = "_articles",
  timeout = 2L,
  log_path = file.path(project, "tmp", "render-test.log"),
  cache = FALSE
)
stopifnot(identical(env$collections, "_articles"))
stopifnot(identical(env$render_timeout, 2L))
stopifnot(identical(env$render_log_path, file.path(project, "tmp", "render-test.log")))
stopifnot(identical(env$use_cache, FALSE))
env$setup_render_logger(project)

stopifnot(exists("render_package_repositories", envir = env, inherits = FALSE))
stopifnot(exists("install_render_packages", envir = env, inherits = FALSE))
stopifnot(exists("use_system_package_library", envir = env, inherits = FALSE))
stopifnot(exists("install_missing_dependencies", envir = env, inherits = FALSE))
stopifnot(exists("configure_system_package_install", envir = env, inherits = FALSE))
stopifnot(exists("with_render_install_lock", envir = env, inherits = FALSE))
render_repos <- env$render_package_repositories()
stopifnot(identical(unname(render_repos[["CRAN"]]), "https://cloud.r-project.org"))
if (requireNamespace("rmarkdown", quietly = TRUE)) {
  html_format <- env$rmarkdown_output_format("html")
  expected_html_device <- if (requireNamespace("ragg", quietly = TRUE)) "ragg_png" else "png"
  stopifnot(identical(html_format$knitr$opts_chunk$dev, expected_html_device))
}

install_calls <- list()
installed_by_test <- character()
original_require_namespace <- env$requireNamespace
env$requireNamespace <- function(package, quietly = FALSE) {
  if (identical(package, "alreadyInstalled")) {
    return(TRUE)
  }
  if (identical(package, "needsInstall")) {
    return(package %in% installed_by_test)
  }
  if (identical(package, "bspm")) {
    return(TRUE)
  }
  base::requireNamespace(package, quietly = quietly)
}
env$install_render_packages <- function(packages, lib, repos) {
  install_calls[[length(install_calls) + 1L]] <<- list(packages = packages, lib = lib, repos = repos)
  installed_by_test <<- unique(c(installed_by_test, packages))
  invisible(packages)
}
invisible(env$install_dependencies(c("alreadyInstalled", "needsInstall"), root = project))
stopifnot(length(install_calls) == 1L)
stopifnot(identical(install_calls[[1L]]$packages, "needsInstall"))
stopifnot(identical(install_calls[[1L]]$lib, env$package_library(project)))
stopifnot(identical(install_calls[[1L]]$repos, render_repos))

old_use_system_library <- Sys.getenv("RJOURNAL_RENDER_USE_SYSTEM_LIBRARY", unset = NA)
old_install_missing <- Sys.getenv("RJOURNAL_RENDER_INSTALL_MISSING", unset = NA)
old_bspm_option <- getOption("rjournal.render.bspm.enabled")
on.exit({
  if (is.na(old_use_system_library)) {
    Sys.unsetenv("RJOURNAL_RENDER_USE_SYSTEM_LIBRARY")
  } else {
    Sys.setenv(RJOURNAL_RENDER_USE_SYSTEM_LIBRARY = old_use_system_library)
  }
  if (is.na(old_install_missing)) {
    Sys.unsetenv("RJOURNAL_RENDER_INSTALL_MISSING")
  } else {
    Sys.setenv(RJOURNAL_RENDER_INSTALL_MISSING = old_install_missing)
  }
  options(rjournal.render.bspm.enabled = old_bspm_option)
}, add = TRUE)

Sys.setenv(RJOURNAL_RENDER_USE_SYSTEM_LIBRARY = "1")
Sys.setenv(RJOURNAL_RENDER_INSTALL_MISSING = "1")
options(rjournal.render.bspm.enabled = FALSE)
stopifnot(isTRUE(env$use_system_package_library()))
stopifnot(isTRUE(env$install_missing_dependencies()))
lock_calls <- 0L
bspm_calls <- 0L
env$enable_bspm <- function() {
  bspm_calls <<- bspm_calls + 1L
  invisible(TRUE)
}
env$with_render_install_lock <- function(root = env$project_root(), code) {
  lock_calls <<- lock_calls + 1L
  eval(substitute(code), parent.frame())
}
install_calls <- list()
installed_by_test <- character()
invisible(env$install_dependencies("needsInstall", root = project))
stopifnot(length(install_calls) == 1L)
stopifnot(identical(lock_calls, 1L))
stopifnot(identical(bspm_calls, 1L))
stopifnot(identical(install_calls[[1L]]$packages, "needsInstall"))
stopifnot(is.null(install_calls[[1L]]$lib))
stopifnot(identical(install_calls[[1L]]$repos, render_repos))
Sys.setenv(RJOURNAL_RENDER_INSTALL_MISSING = "0")
install_calls <- list()
installed_by_test <- character()
missing_result <- try(env$install_dependencies("needsInstall", root = project), silent = TRUE)
stopifnot(inherits(missing_result, "try-error"))
stopifnot(length(install_calls) == 0L)
stopifnot(grepl("Missing package(s) in render image: needsInstall", conditionMessage(attr(missing_result, "condition")), fixed = TRUE))
Sys.unsetenv("RJOURNAL_RENDER_USE_SYSTEM_LIBRARY")
Sys.unsetenv("RJOURNAL_RENDER_INSTALL_MISSING")
env$requireNamespace <- original_require_namespace

if (!requireNamespace("rmarkdown", quietly = TRUE)) {
  message("Skipping R Markdown render smoke tests because rmarkdown is not installed.")
  quit(status = 0)
}

dir.create(file.path(project, "_articles"), recursive = TRUE)
dir.create(file.path(project, "_news"), recursive = TRUE)
dir.create(file.path(project, "_scripts"), recursive = TRUE)
dir.create(file.path(project, "_scripts", "render"), recursive = TRUE)
dir.create(file.path(project, "_scripts", "utils"), recursive = TRUE)
invisible(file.copy(script, file.path(project, "_scripts", "render.R"), overwrite = TRUE))
invisible(file.copy(rmarkdown_module, file.path(project, "_scripts", "render", "rmarkdown.R"), overwrite = TRUE))
invisible(file.copy(archive_module, file.path(project, "_scripts", "render", "archive.R"), overwrite = TRUE))
invisible(file.copy(list.files(utils_dir, full.names = TRUE), file.path(project, "_scripts", "utils"), overwrite = TRUE))

make_item <- function(slug) {
  item_dir <- file.path(project, "_articles", slug)
  dir.create(item_dir, recursive = TRUE)

  source_root <- tempfile(paste0(slug, "-source-"))
  source_dir <- file.path(source_root, slug)
  dir.create(source_dir, recursive = TRUE)
  writeLines(
    c(
      "---",
      'title: "Renderer smoke test"',
      "---",
      "",
      paste(rep(
        "Rendered by the test suite with enough body content to pass the rough renderer cutoff.",
        8
      ), collapse = " ")
    ),
    file.path(source_dir, paste0(slug, ".Rmd"))
  )

  zip::zipr(
    zipfile = file.path(item_dir, "archive.zip"),
    files = slug,
    root = source_root,
    include_directories = TRUE
  )
  unlink(source_root, recursive = TRUE)

  item_dir
}

extract_generated_yaml <- function(lines) {
  stopifnot(identical(lines[[1]], "---"))
  end <- which(trimws(lines[-1]) == "---")[[1]] + 1L
  lines[seq.int(2L, end - 1L)]
}

yaml_source <- file.path(project, "yaml-source.Rmd")
writeLines(
  c(
    "---",
    "title: Drop this title",
    "abstract: Preserve **renderable** abstract metadata with @smith.",
    "bibliography:",
    "  - refs.bib",
    "output:",
    "  rjtools::rjournal_web_article:",
    "    toc: true",
    "---",
    "",
    "# Body"
  ),
  yaml_source
)

env$requireNamespace <- function(package, quietly = FALSE) {
  if (identical(package, "yaml")) {
    return(FALSE)
  }
  base::requireNamespace(package, quietly = quietly)
}
embed_path <- env$write_embed_resources_rmd(yaml_source, cache = FALSE)
embed_lines <- readLines(embed_path, warn = FALSE)
embed_metadata <- yaml12::parse_yaml(extract_generated_yaml(embed_lines), simplify = FALSE)

stopifnot(identical(names(embed_metadata), c("title", "abstract", "bibliography", "output")))
stopifnot(identical(embed_metadata$title, "Drop this title"))
stopifnot(identical(embed_metadata$abstract, "Preserve **renderable** abstract metadata with @smith."))
stopifnot(identical(embed_metadata$bibliography[[1]], "refs.bib"))
stopifnot("html_document" %in% names(embed_metadata$output))
stopifnot(!any(grepl("rjtools::rjournal_web_article", embed_lines, fixed = TRUE)))
stopifnot(any(grepl("# Body", embed_lines, fixed = TRUE)))

tex_native_item_dir <- file.path(project, "_articles", "RJ-2099-027")
dir.create(tex_native_item_dir, recursive = TRUE)
tex_native_source_root <- tempfile("tex-native-source-")
tex_native_source_dir <- file.path(tex_native_source_root, "RJ-2099-027")
dir.create(tex_native_source_dir, recursive = TRUE)
writeLines(
  c(
    "---",
    'title: "Native TeX wrapper"',
    "tex_native: yes",
    "---",
    "",
    "```{=latex}",
    "\\input{RJ-2099-027-src.tex}",
    "```"
  ),
  file.path(tex_native_source_dir, "RJ-2099-027.Rmd")
)
writeLines("Native TeX body", file.path(tex_native_source_dir, "RJ-2099-027-src.tex"))
zip::zipr(
  zipfile = file.path(tex_native_item_dir, "archive.zip"),
  files = "RJ-2099-027",
  root = tex_native_source_root,
  include_directories = TRUE
)
unlink(tex_native_source_root, recursive = TRUE)

tex_native_row <- env$render_item(tex_native_item_dir, root = project)
stopifnot(identical(tex_native_row$status, "skipped_short_body"))
stopifnot(!tex_native_row$html)
stopifnot(!file.exists(file.path(tex_native_item_dir, "RJ-2099-027.html")))

no_rmd_item_dir <- file.path(project, "_articles", "RJ-2099-029")
dir.create(no_rmd_item_dir, recursive = TRUE)
no_rmd_source_root <- tempfile("no-rmd-source-")
no_rmd_source_dir <- file.path(no_rmd_source_root, "RJ-2099-029")
dir.create(no_rmd_source_dir, recursive = TRUE)
writeLines("No R Markdown source here.", file.path(no_rmd_source_dir, "README.txt"))
zip::zipr(
  zipfile = file.path(no_rmd_item_dir, "archive.zip"),
  files = "RJ-2099-029",
  root = no_rmd_source_root,
  include_directories = TRUE
)
unlink(no_rmd_source_root, recursive = TRUE)

no_rmd_row <- env$render_item(no_rmd_item_dir, root = project)
stopifnot(identical(no_rmd_row$status, "skipped_no_top_level_rmd"))
render_log <- readLines(env$render_log_path, warn = FALSE)
stopifnot(any(grepl("RJ-2099-029", render_log, fixed = TRUE)))
stopifnot(any(grepl("reason=no_rmd", render_log, fixed = TRUE)))

timeout_condition <- structure(
  list(message = "reached elapsed time limit"),
  class = c("TimeoutException", "error", "condition")
)
stopifnot(identical(env$classify_render_error(timeout_condition), "timeout"))

multi_rmd_item_dir <- file.path(project, "_articles", "RJ-2099-028")
dir.create(multi_rmd_item_dir, recursive = TRUE)
multi_rmd_source_root <- tempfile("multi-rmd-source-")
multi_rmd_source_dir <- file.path(multi_rmd_source_root, "RJ-2099-028")
dir.create(multi_rmd_source_dir, recursive = TRUE)
writeLines(
  c(
    "---",
    'title: "Exact source wins"',
    "---",
    "",
    paste(rep(
      "This exact slug source should render even when another top-level R Markdown file is present.",
      8
    ), collapse = " ")
  ),
  file.path(multi_rmd_source_dir, "RJ-2099-028.Rmd")
)
writeLines(
  c(
    "---",
    'title: "Supplement"',
    "---",
    "",
    "This extra file should be ignored."
  ),
  file.path(multi_rmd_source_dir, "supplement.Rmd")
)
zip::zipr(
  zipfile = file.path(multi_rmd_item_dir, "archive.zip"),
  files = "RJ-2099-028",
  root = multi_rmd_source_root,
  include_directories = TRUE
)
unlink(multi_rmd_source_root, recursive = TRUE)

multi_rmd_row <- env$render_item(multi_rmd_item_dir, root = project)
stopifnot(identical(multi_rmd_row$status, "rendered"))
stopifnot(multi_rmd_row$html)
stopifnot(file.exists(file.path(multi_rmd_item_dir, "RJ-2099-028.html")))

abstract_item_dir <- file.path(project, "_articles", "RJ-2099-030")
dir.create(abstract_item_dir, recursive = TRUE)
abstract_source_root <- tempfile("abstract-source-")
abstract_source_dir <- file.path(abstract_source_root, "RJ-2099-030")
dir.create(abstract_source_dir, recursive = TRUE)
writeLines(
  c(
    "---",
    'title: "Rendered abstract article"',
    "abstract: This **rendered** abstract cites @smith.",
    "bibliography: refs.bib",
    "---",
    "",
    "# Introduction",
    paste(rep(
      "The body content is long enough for the renderer and separate from the abstract.",
      8
    ), collapse = " "),
    "",
    "# References"
  ),
  file.path(abstract_source_dir, "RJ-2099-030.Rmd")
)
writeLines(
  "@article{smith, title={Smith Paper}, author={Smith, Jane}, year={2099}}",
  file.path(abstract_source_dir, "refs.bib")
)
zip::zipr(
  zipfile = file.path(abstract_item_dir, "archive.zip"),
  files = "RJ-2099-030",
  root = abstract_source_root,
  include_directories = TRUE
)
unlink(abstract_source_root, recursive = TRUE)

abstract_row <- env$render_item(abstract_item_dir, root = project)
abstract_html <- paste(readLines(file.path(abstract_item_dir, "RJ-2099-030.html"), warn = FALSE), collapse = "\n")
stopifnot(identical(abstract_row$status, "rendered"))
stopifnot(grepl("<strong>rendered</strong>", abstract_html, fixed = TRUE))
stopifnot(grepl("Smith", abstract_html, fixed = TRUE))
stopifnot(!grepl('<h1 class="title">Rendered abstract article</h1>', abstract_html, fixed = TRUE))

relative_item_dir <- make_item("RJ-2099-003")
relative_item_row <- env$render_item(file.path("_articles", basename(relative_item_dir)), root = project)
stopifnot(identical(relative_item_row$status, "rendered"))
stopifnot(relative_item_row$html)
stopifnot(file.exists(file.path(relative_item_dir, "RJ-2099-003.html")))

item_dirs <- c(
  make_item("RJ-2099-001"),
  make_item("RJ-2099-002")
)

rows <- lapply(item_dirs, env$render_one_item, root = project)
rows <- do.call(rbind, rows)

stopifnot(nrow(rows) == 2L)
stopifnot(all(rows$status == "rendered"))
stopifnot(all(rows$html))
stopifnot(all(file.exists(file.path(item_dirs, paste0(basename(item_dirs), ".html")))))
