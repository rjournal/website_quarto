latest_article_href <- function(item) {
  paste0("articles/", item$slug, "/")
}

latest_issue_articles <- function(items) {
  issue_articles <- items[vapply(items, complete_issue_item, logical(1))]
  if (length(issue_articles) == 0) {
    return(list())
  }

  issue_articles <- issue_articles[order(
    vapply(issue_articles, function(item) as.integer(item$year), integer(1)),
    vapply(issue_articles, function(item) as.integer(item$volume), integer(1)),
    vapply(issue_articles, function(item) as.integer(item$issue), integer(1))
  )]
  latest_issue_key <- article_issue_key(issue_articles[[length(issue_articles)]])

  issue_articles <- issue_articles[vapply(issue_articles, function(item) {
    identical(article_issue_key(item), latest_issue_key)
  }, logical(1))]
  issue_articles[order(vapply(issue_articles, issue_sort_key, character(1)))]
}

latest_article_markup <- function(item) {
  meta <- character()
  if (!is.null(item$year)) {
    meta <- c(meta, item$year)
  } else if (!is.null(item$date)) {
    date <- suppressWarnings(as.Date(item$date))
    if (!is.na(date)) {
      meta <- c(meta, format(date, "%Y"))
    }
  }
  if (!is.null(item$volume) && !is.null(item$issue)) {
    meta <- c(meta, paste0("Vol. ", item$volume, ", No. ", item$issue))
  }

  lines <- c(
    '<li class="journal-article-row">',
    '<div class="journal-article-kicker">',
    paste0("<span>", html_escape(meta), "</span>"),
    "</div>",
    '<div class="journal-article-summary">',
    paste0('<h3><a href="', latest_article_href(item), '">', html_escape(item$title), "</a></h3>")
  )
  if (!is.null(item$author) && nzchar(item$author)) {
    lines <- c(lines, paste0('<p class="journal-article-authors">', html_escape(item$author), "</p>"))
  }

  c(lines, "</div>", "</li>")
}

write_latest_articles <- function(items, path) {
  latest <- latest_issue_articles(items)
  lines <- c(
    '<ul class="journal-article-list">',
    unlist(lapply(latest, latest_article_markup), use.names = FALSE),
    "</ul>"
  )
  writeLines(lines, path)
}
