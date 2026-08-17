repo <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)

source(file.path(repo, "_scripts", "utils", "html.R"), local = TRUE)
source(file.path(repo, "_scripts", "pre", "feed.R"), local = TRUE)

project <- tempfile("rss-feed-")
dir.create(project)
oldwd <- setwd(project)
on.exit(setwd(oldwd), add = TRUE)

items <- list(
  list(
    title = "Article & Package",
    path = "/articles/RJ-2100-001/",
    description = "Escapes <xml> correctly.",
    date = "2100-01-02"
  ),
  list(
    title = "News Item",
    path = "../news/RJ-2099-3-cran/",
    author = "News Writer",
    year = "2099",
    issue = 3L
  )
)

write_rss_feed(items, "rss.xml", site_url = "https://journal.r-project.org", limit = 10L)
feed <- readLines("rss.xml", warn = FALSE)

stopifnot(file.exists("rss.xml"))
stopifnot(any(grepl('<?xml version="1.0" encoding="UTF-8"?>', feed, fixed = TRUE)))
stopifnot(any(grepl('<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">', feed, fixed = TRUE)))
stopifnot(any(grepl('<atom:link href="https://journal.r-project.org/rss.xml" rel="self" type="application/rss+xml" />', feed, fixed = TRUE)))
stopifnot(any(grepl("<title>Article &amp; Package</title>", feed, fixed = TRUE)))
stopifnot(any(grepl("<description>Escapes &lt;xml&gt; correctly.</description>", feed, fixed = TRUE)))
stopifnot(any(grepl("<link>https://journal.r-project.org/articles/RJ-2100-001/</link>", feed, fixed = TRUE)))
stopifnot(any(grepl("<link>https://journal.r-project.org/news/RJ-2099-3-cran/</link>", feed, fixed = TRUE)))
stopifnot(any(grepl("<description>News Writer</description>", feed, fixed = TRUE)))
