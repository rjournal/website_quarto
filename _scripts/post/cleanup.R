write_template_redirect <- function(template_html) {
  writeLines(
    c(
      "<!DOCTYPE html>",
      '<html lang="en">',
      "<head>",
      '<meta charset="utf-8">',
      '<meta name="robots" content="noindex">',
      '<meta http-equiv="refresh" content="0; url=../../">',
      "<title>The R Journal</title>",
      "</head>",
      "<body>",
      '<p><a href="../../">The R Journal</a></p>',
      "</body>",
      "</html>"
    ),
    template_html
  )
}

cleanup_generated_sources <- function(site_dir) {
  unlink(
    c(
      "generated",
      "issues",
      "issues.qmd",
      "news.qmd",
      file.path("pages", "issues.qmd"),
      file.path("pages", "news.qmd")
    ),
    recursive = TRUE
  )
  unlink(file.path(site_dir, "articles.html"))
}
