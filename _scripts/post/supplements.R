archive_supplement_entry <- function(archive, slug) {
  listing <- tryCatch(
    utils::unzip(archive, list = TRUE),
    error = function(error) {
      stop("Could not inspect archive: ", archive, call. = FALSE)
    }
  )

  target <- paste0(slug, ".zip")
  entries <- listing$Name[basename(listing$Name) == target]
  entries <- entries[!grepl("/$", entries)]
  if (length(entries) == 0) {
    return(NULL)
  }

  entries[[1]]
}

extract_article_supplement <- function(root, slug) {
  item_dir <- file.path(root, slug)
  archive <- file.path(item_dir, "archive.zip")
  if (!file.exists(archive)) {
    return(FALSE)
  }

  entry <- archive_supplement_entry(archive, slug)
  if (is.null(entry)) {
    return(FALSE)
  }

  extract_dir <- tempfile(pattern = paste0(slug, "-supplement-"))
  dir.create(extract_dir)
  on.exit(unlink(extract_dir, recursive = TRUE, force = TRUE), add = TRUE)

  utils::unzip(
    archive,
    files = entry,
    exdir = extract_dir,
    junkpaths = TRUE,
    overwrite = TRUE
  )

  extracted <- file.path(extract_dir, basename(entry))
  if (!file.exists(extracted)) {
    stop("Could not extract supplement from archive: ", archive, call. = FALSE)
  }

  target <- file.path(item_dir, "supplement.zip")
  copied <- file.copy(extracted, target, overwrite = TRUE)
  if (!isTRUE(copied)) {
    stop("Could not write supplement: ", target, call. = FALSE)
  }

  TRUE
}
