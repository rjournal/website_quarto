article_headings <- function(fragment) {
  pattern <- "(?is)<h([1-3])\\b([^>]*)>(.*?)</h\\1>"
  matches <- gregexpr(pattern, fragment, perl = TRUE)[[1]]
  if (matches[[1]] == -1) {
    return(list())
  }

  match_starts <- as.integer(matches)
  starts <- attr(matches, "capture.start")
  lengths <- attr(matches, "capture.length")
  headings <- vector("list", nrow(starts))
  for (i in seq_len(nrow(starts))) {
    attrs <- substring(fragment, starts[i, 2], starts[i, 2] + lengths[i, 2] - 1)
    id <- attr_value(attrs, "id")
    if (is.null(id) || !nzchar(id)) {
      prefix <- substr(fragment, 1L, match_starts[[i]] - 1L)
      wrapper <- regmatches(prefix, regexpr("(?is)<(?:section|div)\\b([^>]*)>\\s*$", prefix, perl = TRUE))
      if (length(wrapper) > 0 && nzchar(wrapper)) {
        id <- attr_value(wrapper, "id")
      }
    }
    text <- heading_text(substring(fragment, starts[i, 3], starts[i, 3] + lengths[i, 3] - 1))
    if (is.null(id) || !nzchar(id) || !nzchar(text)) {
      headings[[i]] <- NULL
    } else {
      headings[[i]] <- list(
        level = as.integer(substring(fragment, starts[i, 1], starts[i, 1] + lengths[i, 1] - 1)),
        id = id,
        text = text
      )
    }
  }

  headings[!vapply(headings, is.null, logical(1))]
}

toc_link <- function(heading, active = FALSE) {
  id <- html_escape(heading$id)
  link_class <- if (active) "nav-link active" else "nav-link"
  paste0(
    '<a href="#',
    id,
    '" id="toc-',
    id,
    '" class="',
    link_class,
    '" data-scroll-target="#',
    id,
    '">',
    html_escape(heading$text),
    "</a>"
  )
}

build_article_toc <- function(fragment) {
  headings <- article_headings(fragment)
  if (length(headings) == 0) {
    return(NULL)
  }
  top_level <- min(vapply(headings, function(heading) heading$level, integer(1)))

  lines <- c(
    '<nav id="TOC" role="doc-toc" class="toc-active">',
    '<h2 id="toc-title">On this page</h2>',
    "<ul>"
  )
  in_level2 <- FALSE
  in_sublist <- FALSE
  for (i in seq_along(headings)) {
    heading <- headings[[i]]
    link <- toc_link(heading, active = identical(i, 1L))
    toc_level <- if (heading$level <= top_level) 2L else 3L
    if (toc_level == 2L) {
      if (in_sublist) {
        lines <- c(lines, "</ul>")
        in_sublist <- FALSE
      }
      if (in_level2) {
        lines <- c(lines, "</li>")
      }
      lines <- c(lines, paste0("<li>", link))
      in_level2 <- TRUE
    } else if (toc_level == 3L && in_level2) {
      if (!in_sublist) {
        lines <- c(lines, '<ul class="collapse">')
        in_sublist <- TRUE
      }
      lines <- c(lines, paste0("<li>", link, "</li>"))
    } else {
      lines <- c(lines, paste0("<li>", link, "</li>"))
    }
  }
  if (in_sublist) {
    lines <- c(lines, "</ul>")
  }
  if (in_level2) {
    lines <- c(lines, "</li>")
  }

  paste(c(lines, "</ul>", "</nav>"), collapse = "\n")
}

article_margin_sidebar <- function(toc) {
  paste(
    "<!-- margin-sidebar -->",
    '    <div id="quarto-margin-sidebar" class="sidebar margin-sidebar">',
    indent_html(toc, 8L),
    "    </div>",
    sep = "\n"
  )
}

apply_article_toc_layout <- function(page, toc) {
  sidebar <- article_margin_sidebar(toc)

  page <- gsub("page-layout-full", "page-layout-article", page, fixed = TRUE)
  page <- gsub(
    '<main class="content column-page" id="quarto-document-content">',
    '<main class="content" id="quarto-document-content">',
    page,
    fixed = TRUE
  )
  page <- gsub(
    '<div class="quarto-title-meta column-page">',
    '<div class="quarto-title-meta">',
    page,
    fixed = TRUE
  )

  if (grepl('id="quarto-margin-sidebar"', page, fixed = TRUE)) {
    return(sub(
      '(?is)<!-- margin-sidebar -->\\s*<div id="quarto-margin-sidebar" class="sidebar margin-sidebar">.*?</div>\\s*<!-- main -->',
      paste0(sidebar, "\n<!-- main -->"),
      page,
      perl = TRUE
    ))
  }

  if (grepl("<!-- margin-sidebar -->", page, fixed = TRUE)) {
    return(sub(
      "(?s)<!-- margin-sidebar -->\\s*",
      paste0(sidebar, "\n"),
      page,
      perl = TRUE
    ))
  }

  sub("(?s)<!-- main -->", paste0(sidebar, "\n<!-- main -->"), page, perl = TRUE)
}
