as_bytes <- function(x) {
  Encoding(x) <- "bytes"
  x
}

as_utf8 <- function(x) {
  Encoding(x) <- "UTF-8"
  x
}

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
    # Article HTML can be many MB (inlined base64 images) and contain
    # multibyte UTF-8. R's substr()/regex position handling is O(n) per call
    # on such strings, so process the fragment as raw bytes and mark the
    # results as UTF-8 again afterwards. All offsets stay within the same
    # byte string, so the output is identical.
    fragment <- clean_html_fragment(as_bytes(read_text(html)))
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
    list(content = as_utf8(article), inline = TRUE, toc = if (is.null(toc)) NULL else as_utf8(toc))
  } else if (file.exists(pdf)) {
    pdf_embed(root, slug)
  } else {
    NULL
  }
}
