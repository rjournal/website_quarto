script_files <- vapply(sys.frames(), function(frame) if (is.null(frame$ofile)) NA_character_ else frame$ofile, character(1))
script_files <- script_files[!is.na(script_files)]
script_file <- if (length(script_files)) script_files[[length(script_files)]] else sub("^--file=", "", grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)[[1]])
source(file.path(dirname(normalizePath(script_file, mustWork = TRUE)), "utils", "script.R"), local = TRUE)

source_script_files(file.path("utils", c("io.R", "html.R", "metadata.R", "icons.R")))
source_script_files(file.path("pre", c(
  "config.R",
  "metadata.R",
  "items.R",
  "feed.R",
  "latest.R",
  "archive.R",
  "issues.R",
  "cleanup.R"
)))

template_qmd <- file.path("assets", "article-template", "index.qmd")
articles_listing_yml <- file.path("generated", "articles.yml")
issues_listing_yml <- file.path("generated", "issues.yml")
latest_articles_html <- file.path("generated", "latest-articles.html")
rss_feed_xml <- "rss.xml"
issues_index_qmd <- file.path("pages", "issues.qmd")
news_index_qmd <- file.path("pages", "news.qmd")
issues_dir <- "issues"

read_article_template(template_qmd)
remove_article_resources()

article_slugs <- sort(item_dirs("_articles"))
article_items <- lapply(article_slugs, article_listing_item)
write_article_listing(article_items, articles_listing_yml)
write_latest_articles(article_items, latest_articles_html)

news_slugs <- sort(item_dirs("_news"))
news_items <- lapply(news_slugs, news_listing_item)
write_rss_feed(c(article_items, news_items), rss_feed_xml)
write_archive_index(
  news_items,
  news_index_qmd,
  "All News",
  "All news items published by the R Journal.",
  "_No news found._",
  show_pdf = FALSE,
  toc = TRUE,
  year_heading_class = "archive-year-heading"
)

reset_issues_dir(issues_dir)
issue_items <- issue_items_from(article_items, news_items)
yaml::write_yaml(lapply(issue_items, issue_listing_item), issues_listing_yml)
write_issues_index(issue_items)
write_issue_pages(issue_items, article_items, news_items)
