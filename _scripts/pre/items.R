content_listing_item <- function(root, slug, path) {
  metadata_path <- file.path(root, slug, "metadata.yaml")
  metadata <- if (file.exists(metadata_path)) {
    yaml::read_yaml(metadata_path)
  } else {
    list()
  }

  item <- list(
    slug = slug,
    title = if (!is.null(metadata$title)) as.character(metadata$title) else slug,
    path = path
  )

  if (!is.null(metadata$date)) {
    item$date <- as.character(metadata$date)
  }

  year <- article_year(slug, metadata)
  if (!is.null(year)) {
    item$year <- year
  }

  if (!is.null(metadata$volume)) {
    item$volume <- metadata$volume
  }

  if (!is.null(metadata$issue)) {
    item$issue <- metadata$issue
  }

  firstpage <- metadata_firstpage(metadata)
  if (!is.null(firstpage)) {
    item$firstpage <- firstpage
  }

  author <- author_text(metadata$author)
  if (!is.null(author)) {
    item$author <- author
  }

  if (!is.null(metadata$abstract)) {
    item$description <- as.character(metadata$abstract)
  }

  pdf_path <- file.path(root, slug, paste0(slug, ".pdf"))
  if (file.exists(pdf_path)) {
    item$pdf <- paste0("/", root, "/", slug, "/", slug, ".pdf")
  }

  item
}

article_listing_item <- function(slug) {
  content_listing_item("_articles", slug, paste0("/articles/", slug, "/"))
}

write_article_listing <- function(article_items, articles_listing_yml) {
  dir.create(dirname(articles_listing_yml), showWarnings = FALSE, recursive = TRUE)
  yaml::write_yaml(article_items, articles_listing_yml)
}

news_listing_item <- function(slug) {
  content_listing_item("_news", slug, paste0("../news/", slug, "/"))
}
