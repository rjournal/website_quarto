read_article_template <- function(template_qmd) {
  if (!file.exists(template_qmd)) {
    stop("Missing article template: ", template_qmd)
  }

  template <- paste(readLines(template_qmd, warn = FALSE), collapse = "\n")
  validate_article_template(template)
}

validate_article_template <- function(template) {
  if (!grepl("RJOURNAL_TITLE_SENTINEL", template, fixed = TRUE)) {
    stop("Article template is missing RJOURNAL_TITLE_SENTINEL")
  }
  if (!grepl("RJOURNAL_CONTENT_SENTINEL", template, fixed = TRUE)) {
    stop("Article template is missing RJOURNAL_CONTENT_SENTINEL")
  }

  invisible(template)
}
