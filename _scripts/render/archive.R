find_source_dir <- function(extract_dir, slug) {
  exact <- file.path(extract_dir, slug)
  if (dir.exists(exact)) {
    return(exact)
  }

  dirs <- list.dirs(extract_dir, recursive = FALSE, full.names = TRUE)
  if (length(dirs) == 1) {
    return(dirs[[1]])
  }

  stop("Could not identify source directory for ", slug, call. = FALSE)
}

find_source_rmd <- function(source_dir, slug) {
  exact <- file.path(source_dir, paste0(slug, ".Rmd"))
  if (file.exists(exact)) {
    return(exact)
  }

  rmds <- list.files(
    source_dir,
    pattern = "[.]Rmd$",
    ignore.case = TRUE,
    full.names = TRUE,
    recursive = FALSE
  )

  if (length(rmds) == 1) {
    return(rmds[[1]])
  }

  stop(
    "Could not identify a unique top-level Rmd in ",
    source_dir,
    call. = FALSE
  )
}

top_level_rmds <- function(source_dir) {
  list.files(
    source_dir,
    pattern = "[.]Rmd$",
    ignore.case = TRUE,
    full.names = TRUE,
    recursive = FALSE
  )
}

render_item <- function(item_dir, root = project_root()) {
  item_dir <- normalizePath(item_dir, mustWork = TRUE)
  configure_render_env(root)
  slug <- basename(item_dir)
  archive <- file.path(item_dir, "archive.zip")
  formats_to_render <- missing_render_formats(item_dir, slug)

  if (length(formats_to_render) == 0) {
    render_trace(paste0(
      "event=render_item_skipped collection=", basename(dirname(item_dir)),
      " slug=", slug,
      " reason=existing_output"
    ))
    return(skip_row(item_dir, slug, "skipped_existing_output"))
  }

  if (!file.exists(archive)) {
    stop("Missing archive: ", archive, call. = FALSE)
  }

  render_trace(paste0(
    "event=render_item_extract_started collection=", basename(dirname(item_dir)),
    " slug=", slug
  ))
  extract_dir <- tempfile(pattern = paste0(slug, "-"), tmpdir = tmp_root(root))
  dir.create(extract_dir)
  on.exit(unlink(extract_dir, recursive = TRUE, force = TRUE), add = TRUE)

  utils::unzip(archive, exdir = extract_dir)
  source_dir <- find_source_dir(extract_dir, slug)
  render_trace(paste0(
    "event=render_item_extract_finished collection=", basename(dirname(item_dir)),
    " slug=", slug,
    " source_dir=", source_dir
  ))
  rmds <- top_level_rmds(source_dir)
  exact_rmd <- file.path(source_dir, paste0(slug, ".Rmd"))
  if (length(rmds) == 0) {
    render_warn(paste0(
      "event=render_item_skipped collection=", basename(dirname(item_dir)),
      " slug=", slug,
      " reason=no_rmd",
      " source_dir=", source_dir
    ))
    return(skip_row(item_dir, slug, "skipped_no_top_level_rmd"))
  }
  if (length(rmds) > 1 && !file.exists(exact_rmd)) {
    render_warn(paste0(
      "event=render_item_skipped collection=", basename(dirname(item_dir)),
      " slug=", slug,
      " reason=multiple_top_level_rmd",
      " source_dir=", source_dir
    ))
    return(skip_row(item_dir, slug, "skipped_multiple_top_level_rmd"))
  }

  source_rmd <- find_source_rmd(source_dir, slug)
  skip_status <- render_rmarkdown_file(
    source_rmd = source_rmd,
    output_dir = item_dir,
    slug = slug,
    formats = formats_to_render,
    source_dir = source_dir,
    root = root
  )
  if (!is.null(skip_status)) {
    render_warn(paste0(
      "event=render_item_skipped collection=", basename(dirname(item_dir)),
      " slug=", slug,
      " reason=", sub("^skipped_", "", skip_status)
    ))
    return(skip_row(item_dir, slug, skip_status))
  }

  status <- if (length(formats_to_render) == length(render_formats)) {
    "rendered"
  } else {
    paste0("rendered_", paste(formats_to_render, collapse = "_"))
  }

  render_info(paste0(
    "event=render_item_succeeded collection=", basename(dirname(item_dir)),
    " slug=", slug,
    " status=", status
  ))
  render_item_row(item_dir, slug, status)
}
