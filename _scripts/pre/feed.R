rjournal_site_url <- "https://journal.r-project.org"
rjournal_feed_limit <- 50L

canonical_feed_path <- function(path) {
  path <- sub("^\\.\\./", "/", path)
  if (!startsWith(path, "/")) {
    path <- paste0("/", path)
  }
  path
}

canonical_feed_url <- function(path, site_url = rjournal_site_url) {
  paste0(sub("/+$", "", site_url), canonical_feed_path(path))
}

feed_item_date <- function(item) {
  if (!is.null(item$date)) {
    date <- suppressWarnings(as.Date(item$date))
    if (!is.na(date)) {
      return(date)
    }
  }

  if (!is.null(item$year) && !is.null(item$issue)) {
    issue_months <- c("1" = "03", "2" = "06", "3" = "09", "4" = "12")
    issue <- as.character(item$issue)
    month <- if (issue %in% names(issue_months)) issue_months[[issue]] else "01"
    date <- suppressWarnings(as.Date(sprintf("%s-%s-01", item$year, month)))
    if (!is.na(date)) {
      return(date)
    }
  }

  if (!is.null(item$year)) {
    date <- suppressWarnings(as.Date(sprintf("%s-01-01", item$year)))
    if (!is.na(date)) {
      return(date)
    }
  }

  as.Date(NA)
}

rss_date <- function(date) {
  weekdays <- c("Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat")
  months <- c("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")
  parts <- as.POSIXlt(as.POSIXct(date, tz = "GMT"), tz = "GMT")
  paste0(
    weekdays[[parts$wday + 1L]],
    ", ",
    sprintf("%02d", parts$mday),
    " ",
    months[[parts$mon + 1L]],
    " ",
    parts$year + 1900L,
    " 00:00:00 GMT"
  )
}

rss_description <- function(item) {
  if (!is.null(item$description) && nzchar(item$description)) {
    return(item$description)
  }
  if (!is.null(item$author) && nzchar(item$author)) {
    return(item$author)
  }
  item$title
}

rss_item_markup <- function(item, site_url = rjournal_site_url) {
  link <- canonical_feed_url(item$path, site_url = site_url)
  c(
    "    <item>",
    paste0("      <title>", html_escape(item$title), "</title>"),
    paste0("      <link>", html_escape(link), "</link>"),
    paste0("      <guid isPermaLink=\"true\">", html_escape(link), "</guid>"),
    paste0("      <pubDate>", rss_date(item$rss_date), "</pubDate>"),
    paste0("      <description>", html_escape(rss_description(item)), "</description>"),
    "    </item>"
  )
}

write_rss_feed <- function(items, path, site_url = rjournal_site_url, limit = rjournal_feed_limit) {
  dated_items <- lapply(items, function(item) {
    item$rss_date <- feed_item_date(item)
    item
  })
  dated_items <- dated_items[!is.na(vapply(dated_items, function(item) item$rss_date, as.Date(NA)))]
  dated_items <- dated_items[order(
    -as.numeric(vapply(dated_items, function(item) item$rss_date, as.Date(NA))),
    vapply(dated_items, function(item) tolower(item$title), character(1))
  )]
  if (length(dated_items) > limit) {
    dated_items <- dated_items[seq_len(limit)]
  }

  build_date <- if (length(dated_items) > 0) {
    max(vapply(dated_items, function(item) item$rss_date, as.Date(NA)))
  } else {
    Sys.Date()
  }

  feed_url <- paste0(sub("/+$", "", site_url), "/rss.xml")
  lines <- c(
    '<?xml version="1.0" encoding="UTF-8"?>',
    '<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">',
    "  <channel>",
    "    <title>The R Journal</title>",
    paste0("    <link>", html_escape(sub("/+$", "", site_url)), "</link>"),
    "    <description>Recent articles, editorials, and news from The R Journal.</description>",
    "    <language>en-us</language>",
    paste0("    <lastBuildDate>", rss_date(build_date), "</lastBuildDate>"),
    paste0('    <atom:link href="', html_escape(feed_url), '" rel="self" type="application/rss+xml" />'),
    unlist(lapply(dated_items, rss_item_markup, site_url = site_url), use.names = FALSE),
    "  </channel>",
    "</rss>"
  )

  writeLines(lines, path, useBytes = TRUE)
}
