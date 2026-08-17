has_package <- function(package) {
  requireNamespace(package, quietly = TRUE)
}

require_package <- function(package) {
  if (!has_package(package)) {
    stop("Required R package is not installed: ", package, call. = FALSE)
  }
}

metadata_author_names <- function(author) {
  if (is.null(author)) {
    return(character())
  }

  if (is.character(author)) {
    return(author[nzchar(author)])
  }

  if (!is.list(author)) {
    return(character())
  }

  names <- vapply(author, function(entry) {
    if (is.character(entry)) {
      entry[[1]]
    } else if (is.list(entry) && !is.null(entry$name)) {
      as.character(entry$name)
    } else if (is.list(entry) && (!is.null(entry$first_name) || !is.null(entry$last_name))) {
      trimws(paste(c(entry$first_name, entry$last_name), collapse = " "))
    } else {
      NA_character_
    }
  }, character(1))

  names[!is.na(names) & nzchar(names)]
}

metadata_year <- function(slug, metadata) {
  if (!is.null(metadata$volume)) {
    volume <- suppressWarnings(as.integer(metadata$volume))
    if (!is.na(volume)) {
      if (startsWith(slug, "RJ-")) {
        return(as.character(volume + 2008L))
      }
      if (startsWith(slug, "RN-")) {
        return(as.character(volume + 2000L))
      }
    }
  }

  if (!is.null(metadata$date)) {
    date_text <- as.character(metadata$date)
    year <- regmatches(date_text, regexpr("[0-9]{4}", date_text))
    if (length(year) > 0 && nzchar(year)) {
      return(year)
    }
  }

  year <- regmatches(slug, regexpr("[0-9]{4}", slug))
  if (length(year) > 0 && nzchar(year)) {
    return(year)
  }

  NA_character_
}

metadata_pages <- function(metadata) {
  first <- metadata$journal$firstpage
  last <- metadata$journal$lastpage
  pages <- c(first, last)
  pages <- as.character(pages[!vapply(pages, is.null, logical(1))])
  pages <- pages[nzchar(pages)]
  if (length(pages) == 0) {
    return(NA_character_)
  }
  paste(pages, collapse = "-")
}

metadata_scalar <- function(value) {
  if (is.null(value)) {
    return(NA_character_)
  }
  value <- as.character(value[[1]])
  if (nzchar(value)) value else NA_character_
}

article_bib_row <- function(slug, metadata) {
  title <- metadata_scalar(metadata$title)
  if (is.na(title)) {
    title <- slug
  }

  authors <- metadata_author_names(metadata$author)
  author <- if (length(authors) > 0) {
    paste(authors, collapse = " and ")
  } else {
    NA_character_
  }

  row <- data.frame(
    bibtexkey = slug,
    title = paste0("{", title, "}"),
    AUTHOR = author,
    journal = "{The R Journal}",
    year = metadata_year(slug, metadata),
    volume = metadata_scalar(metadata$volume),
    number = metadata_scalar(metadata$issue),
    pages = metadata_pages(metadata),
    doi = metadata_scalar(metadata$doi),
    url = paste0("https://journal.r-project.org/articles/", slug, "/"),
    category = "article",
    stringsAsFactors = FALSE
  )

  row[, !vapply(row, function(column) is.na(column[[1]]) || !nzchar(column[[1]]), logical(1)), drop = FALSE]
}

write_article_bib <- function(article_dir, slug) {
  require_package("yaml")
  require_package("bib2df")

  metadata_path <- file.path(article_dir, "metadata.yaml")
  if (!file.exists(metadata_path)) {
    return(FALSE)
  }

  metadata <- yaml::read_yaml(metadata_path)
  if (!is.list(metadata)) {
    return(FALSE)
  }

  bib_path <- file.path(article_dir, paste0(slug, ".bib"))
  bib2df::df2bib(article_bib_row(slug, metadata), bib_path)
  TRUE
}

generate_article_bibtex <- function(root = ".", articles_dir = "_articles") {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  articles_path <- file.path(root, articles_dir)
  slugs <- if (dir.exists(articles_path)) {
    list.dirs(articles_path, recursive = FALSE, full.names = FALSE)
  } else {
    character()
  }

  generated <- 0L
  skipped_existing <- 0L
  skipped_missing_metadata <- 0L

  for (slug in sort(slugs)) {
    article_dir <- file.path(articles_path, slug)
    existing_bib <- list.files(article_dir, pattern = "[.]bib$", recursive = FALSE, ignore.case = TRUE)
    if (length(existing_bib) > 0) {
      skipped_existing <- skipped_existing + 1L
      next
    }

    if (!file.exists(file.path(article_dir, "metadata.yaml"))) {
      skipped_missing_metadata <- skipped_missing_metadata + 1L
      next
    }

    if (isTRUE(write_article_bib(article_dir, slug))) {
      generated <- generated + 1L
    }
  }

  list(
    generated = generated,
    skipped_existing = skipped_existing,
    skipped_missing_metadata = skipped_missing_metadata
  )
}

if (identical(environment(), globalenv()) && !interactive()) {
  result <- generate_article_bibtex(".")
  message(
    "Generated ", result$generated,
    " article BibTeX file(s); skipped ", result$skipped_existing,
    " with existing BibTeX file(s); skipped ", result$skipped_missing_metadata,
    " without metadata.yaml."
  )
}
