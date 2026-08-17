author_text <- function(author) {
  if (is.null(author)) {
    return(NULL)
  }

  if (is.character(author)) {
    return(paste(author, collapse = ", "))
  }

  if (is.list(author)) {
    names <- vapply(author, function(entry) {
      if (is.character(entry)) {
        entry[[1]]
      } else if (is.list(entry) && !is.null(entry$name)) {
        as.character(entry$name)
      } else if (is.list(entry) && (!is.null(entry$first_name) || !is.null(entry$last_name))) {
        trimws(paste(
          c(as.character(entry$first_name), as.character(entry$last_name)),
          collapse = " "
        ))
      } else {
        NA_character_
      }
    }, character(1))
    names <- names[!is.na(names) & nzchar(names)]
    if (length(names) > 0) {
      return(paste(names, collapse = ", "))
    }
  }

  NULL
}

article_year <- function(slug, metadata) {
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

  year <- regmatches(slug, regexpr("[0-9]{4}", slug))
  if (length(year) > 0 && nzchar(year)) {
    return(year)
  }

  if (!is.null(metadata$date)) {
    date_text <- as.character(metadata$date)
    year <- regmatches(date_text, regexpr("[0-9]{4}", date_text))
    if (length(year) > 0 && nzchar(year)) {
      return(year)
    }
  }

  NULL
}
