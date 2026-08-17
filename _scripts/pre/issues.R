issue_slug <- function(item) {
  paste0(item$year, "-v", item$volume, "-i", item$issue)
}

issue_title <- function(item) {
  paste0("Volume ", item$volume, ", Issue ", item$issue, " (", item$year, ")")
}

issue_description <- function(item) {
  issue_months <- c("1" = "March", "2" = "June", "3" = "September", "4" = "December")
  issue <- as.character(item$issue)
  if (!is.na(issue) && issue %in% names(issue_months)) {
    return(paste0("Articles published in the ", issue_months[[issue]], " ", item$year, " issue"))
  }

  paste0("Articles published in the ", item$year, " issue")
}

issue_listing_item <- function(item) {
  list(
    title = issue_title(item),
    path = paste0("/issues/", issue_slug(item), "/"),
    year = item$year,
    volume = item$volume,
    issue = item$issue
  )
}

issue_link_title <- function(item) {
  paste0("Volume ", item$volume, ", Issue ", item$issue)
}

write_issues_index <- function(items) {
  dir.create(dirname(issues_index_qmd), showWarnings = FALSE, recursive = TRUE)

  lines <- c(
    "---",
    'title: "Issues"',
    "---",
    ""
  )

  years <- unique(vapply(items, function(item) item$year, character(1)))
  for (year in years) {
    year_items <- items[vapply(items, function(item) identical(item$year, year), logical(1))]
    lines <- c(lines, paste0("## ", year), "")
    for (item in year_items) {
      lines <- c(
        lines,
        paste0("- [", issue_link_title(item), "](", file.path("..", "issues", issue_slug(item), fsep = "/"), "/)")
      )
    }
    lines <- c(lines, "")
  }

  writeLines(lines, issues_index_qmd)
}

article_issue_key <- function(item) {
  paste(item$year, item$volume, item$issue, sep = "-")
}

article_sort_key <- function(item) {
  title <- if (!is.null(item$title)) item$title else ""
  tolower(title)
}

issue_sort_key <- function(item) {
  if (!is.null(item$firstpage)) {
    firstpage <- suppressWarnings(as.integer(item$firstpage))
    if (!is.na(firstpage)) {
      return(sprintf("%08d", firstpage))
    }
  }

  paste0("99999999-", article_sort_key(item))
}

issue_entry_href <- function(item, section) {
  paste0("../../", section, "/", item$slug, "/")
}

issue_entry_markup <- function(item, section) {
  title <- html_escape(item$title)
  lines <- c(
    '<article class="issue-article issue-entry">',
    paste0(
      '<h4 class="issue-article-title"><a href="',
      issue_entry_href(item, section),
      '">',
      title,
      "</a></h4>"
    )
  )

  details <- character()
  if (!is.null(item$author) && nzchar(item$author)) {
    details <- c(details, html_escape(item$author))
  }
  if (length(details) > 0) {
    lines <- c(lines, paste0('<p class="issue-article-authors">', paste(details, collapse = " "), "</p>"))
  }

  c(lines, "</article>")
}

issue_pdf_candidates <- function(item) {
  issue_dir <- paste0(item$year, "-", item$issue)
  file.path(
    "_issues",
    issue_dir,
    c(
      paste0(issue_dir, ".pdf"),
      paste0("RJ-", issue_dir, ".pdf")
    )
  )
}

issue_pdf_href <- function(item) {
  candidates <- issue_pdf_candidates(item)
  candidates <- candidates[file.exists(candidates)]
  if (length(candidates) == 0) {
    return(NULL)
  }

  paste0("../../", candidates[[1]])
}

issue_pdf_markup <- function(item) {
  href <- issue_pdf_href(item)
  if (is.null(href)) {
    return(character())
  }

  paste0(
    '<p class="issue-complete"><a class="issue-complete-pdf" href="',
    html_escape(href),
    '">Complete issue ',
    rjournal_pdf_icon,
    "</a></p>"
  )
}

issue_section_markup <- function(title, class_name, items, section) {
  if (length(items) == 0) {
    return(character())
  }

  c(
    paste0('<section class="issue-section ', class_name, '">'),
    if (!is.null(title)) paste0("### ", title) else character(),
    unlist(lapply(items, issue_entry_markup, section = section), use.names = FALSE),
    "</section>"
  )
}

is_editorial_news <- function(item) {
  grepl("-editorial$", item$slug)
}

write_issue_page <- function(item, articles, news) {
  page_dir <- file.path(issues_dir, issue_slug(item))
  dir.create(page_dir, showWarnings = FALSE, recursive = TRUE)

  key <- article_issue_key(item)
  issue_articles <- articles[vapply(articles, function(article) {
    complete_issue_item(article) && identical(article_issue_key(article), key)
  }, logical(1))]
  issue_articles <- issue_articles[order(vapply(issue_articles, issue_sort_key, character(1)))]

  issue_news <- news[vapply(news, function(news_item) {
    complete_issue_item(news_item) && identical(article_issue_key(news_item), key)
  }, logical(1))]
  editorials <- issue_news[vapply(issue_news, is_editorial_news, logical(1))]
  news_notes <- issue_news[!vapply(issue_news, is_editorial_news, logical(1))]
  editorials <- editorials[order(vapply(editorials, issue_sort_key, character(1)))]
  news_notes <- news_notes[order(vapply(news_notes, issue_sort_key, character(1)))]

  body <- c(
    issue_section_markup("Editorial", "issue-editorial", editorials, "news"),
    issue_section_markup("Research Articles", "issue-contributed-articles", issue_articles, "articles"),
    issue_section_markup("News and Notes", "issue-news-notes", news_notes, "news")
  )
  if (length(body) == 0) {
    body <- "_No articles found for this issue._"
  }

  description <- issue_description(item)
  page <- c(
    "---",
    paste0('title: "', issue_title(item), '"'),
    paste0('description: "', description, '"'),
    "---",
    "",
    issue_pdf_markup(item),
    "",
    '<section class="issue-articles">',
    body,
    "</section>"
  )

  writeLines(page, file.path(page_dir, "index.qmd"))
}

complete_issue_item <- function(item) {
  !is.null(item$year) && !is.null(item$volume) && !is.null(item$issue)
}

issue_items_from <- function(article_items, news_items) {
  issue_items <- c(article_items, news_items)
  issue_items <- issue_items[vapply(issue_items, complete_issue_item, logical(1))]
  issue_keys <- vapply(issue_items, function(item) {
    article_issue_key(item)
  }, character(1))
  issue_items <- issue_items[!duplicated(issue_keys)]
  issue_items[order(
    vapply(issue_items, function(item) as.integer(item$year), integer(1)),
    vapply(issue_items, function(item) as.integer(item$volume), integer(1)),
    vapply(issue_items, function(item) as.integer(item$issue), integer(1)),
    decreasing = TRUE
  )]
}

write_issue_pages <- function(issue_items, article_items, news_items) {
  for (item in issue_items) {
    write_issue_page(item, article_items, news_items)
  }
}
