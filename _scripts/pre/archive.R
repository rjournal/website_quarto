archive_year <- function(item) {
  if (!is.null(item$year)) {
    return(item$year)
  }

  year <- regmatches(item$slug, regexpr("[0-9]{4}", item$slug))
  if (length(year) > 0 && nzchar(year)) {
    return(year)
  }

  "Undated"
}

archive_sort_year <- function(item) {
  year <- suppressWarnings(as.integer(archive_year(item)))
  if (is.na(year)) {
    return(-Inf)
  }
  year
}

archive_item_markup <- function(item, show_pdf = TRUE) {
  title <- html_escape(item$title)
  lines <- c(
    '<article class="archive-item">',
    paste0('<h2 class="archive-item-title"><a href="', item$path, '">', title, "</a></h2>")
  )

  details <- character()
  if (!is.null(item$author) && nzchar(item$author)) {
    details <- c(details, html_escape(item$author))
  }
  if (!is.null(item$volume) && !is.null(item$issue)) {
    details <- c(details, paste0("Volume ", item$volume, ", Issue ", item$issue))
  }
  if (length(details) > 0) {
    lines <- c(lines, paste0('<p class="archive-item-details">', paste(details, collapse = " · "), "</p>"))
  }

  if (show_pdf && !is.null(item$pdf)) {
    lines <- c(
      lines,
      paste0('<p class="archive-item-links"><a class="archive-item-pdf" href="', item$pdf, '">PDF</a></p>')
    )
  }

  c(lines, "</article>")
}

write_archive_index <- function(
  items,
  path,
  title,
  description,
  empty_text,
  show_pdf = TRUE,
  toc = NULL,
  year_heading_class = NULL
) {
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)

  lines <- c(
    "---",
    paste0('title: "', title, '"'),
    "description: |",
    paste0("  ", description)
  )
  if (!is.null(toc)) {
    lines <- c(lines, paste0("toc: ", tolower(as.character(toc))))
  }
  lines <- c(lines, "---", "")

  if (length(items) == 0) {
    lines <- c(lines, empty_text)
    writeLines(lines, path)
    return(invisible(NULL))
  }

  items <- items[order(
    -vapply(items, archive_sort_year, numeric(1)),
    vapply(items, function(item) tolower(item$title), character(1))
  )]

  years <- unique(vapply(items, archive_year, character(1)))
  for (year in years) {
    year_items <- items[vapply(items, function(item) identical(archive_year(item), year), logical(1))]
    year_heading <- if (is.null(year_heading_class)) {
      paste0("## ", year)
    } else {
      paste0("## ", year, " {.", year_heading_class, "}")
    }
    lines <- c(lines, year_heading, "", '<section class="archive-list">')
    lines <- c(lines, unlist(lapply(year_items, archive_item_markup, show_pdf = show_pdf), use.names = FALSE))
    lines <- c(lines, "</section>", "")
  }

  writeLines(lines, path)
}
