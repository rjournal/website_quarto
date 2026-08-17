pdf_embed <- function(root, slug) {
  pdf <- file.path(root, slug, paste0(slug, ".pdf"))
  if (!file.exists(pdf)) {
    return(NULL)
  }

  pdf_href <- paste0("../../", pdf)
  list(
    content = paste0(
      '<iframe class="article-reader-object" src="',
      pdf_href,
      '" title="PDF article"></iframe>'
    ),
    inline = FALSE,
    toc = NULL
  )
}

build_embed <- function(root, slug, include_toc = FALSE) {
  src_dir <- file.path(root, slug)
  html <- file.path(src_dir, paste0(slug, ".html"))
  pdf <- file.path(src_dir, paste0(slug, ".pdf"))

  if (file.exists(html)) {
    fragment <- clean_html_fragment(read_text(html))
    if (!html_fragment_has_content(fragment)) {
      return(pdf_embed(root, slug))
    }

    article <- paste0(
      '<article class="article-reader article-reader-inline">',
      "\n",
      fragment,
      "\n",
      "</article>"
    )
    toc <- if (include_toc) build_article_toc(fragment) else NULL
    list(content = article, inline = TRUE, toc = toc)
  } else if (file.exists(pdf)) {
    pdf_embed(root, slug)
  } else {
    NULL
  }
}
