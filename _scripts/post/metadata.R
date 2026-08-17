issue_slug <- function(metadata, slug) {
  year <- article_year(slug, metadata)
  if (is.null(year) || is.null(metadata$volume) || is.null(metadata$issue)) {
    return(NULL)
  }

  paste0(year, "-v", metadata$volume, "-i", metadata$issue)
}

issue_title <- function(metadata) {
  if (is.null(metadata$volume) || is.null(metadata$issue)) {
    return(NULL)
  }

  paste0("Volume ", metadata$volume, ", Issue ", metadata$issue)
}

doi_url <- function(doi) {
  if (is.null(doi) || !nzchar(as.character(doi))) {
    return(NULL)
  }

  doi <- sub("^https?://doi[.]org/", "", as.character(doi), ignore.case = TRUE)
  paste0("https://doi.org/", doi)
}
