extract_body <- function(html) {
  body <- regmatches(
    html,
    regexpr("(?is)<body\\b[^>]*>(.*)</body>", html, perl = TRUE)
  )
  if (length(body) == 0 || !nzchar(body)) {
    return(html)
  }

  sub("(?is)^<body\\b[^>]*>(.*)</body>$", "\\1", body, perl = TRUE)
}

fragment_top_level_heading <- function(fragment) {
  heading <- regmatches(fragment, regexpr("(?is)<h([1-6])\\b", fragment, perl = TRUE))
  if (length(heading) == 0 || !nzchar(heading)) {
    return("h2")
  }

  sub("(?is)^<h([1-6])\\b.*$", "h\\1", heading, perl = TRUE)
}

add_missing_references_heading <- function(fragment) {
  if (!grepl("(?is)<div\\b[^>]*\\bid\\s*=\\s*(['\"])refs\\1[^>]*>", fragment, perl = TRUE)) {
    return(fragment)
  }
  if (grepl("(?is)\\bid\\s*=\\s*(['\"])references\\1", fragment, perl = TRUE)) {
    return(fragment)
  }
  if (grepl("(?is)<h[1-6]\\b[^>]*>\\s*(References|Bibliography)\\s*</h[1-6]>", fragment, perl = TRUE)) {
    return(fragment)
  }

  tag <- fragment_top_level_heading(fragment)
  refs <- regexpr("(?is)<div\\b[^>]*\\bid\\s*=\\s*(['\"])refs\\1[^>]*>", fragment, perl = TRUE)
  heading <- paste0("<", tag, ' id="references" class="unnumbered">References</', tag, ">\n")

  paste0(
    substr(fragment, 1L, refs[[1]] - 1L),
    heading,
    substr(fragment, refs[[1]], nchar(fragment))
  )
}

clean_html_fragment <- function(html) {
  fragment <- extract_body(html)
  fragment <- gsub("(?is)<!--.*?-->", "", fragment, perl = TRUE)
  fragment <- trimws(fragment)
  add_missing_references_heading(fragment)
}

html_fragment_has_content <- function(fragment) {
  candidate <- gsub("(?is)<(script|style|noscript)\\b[^>]*>.*?</\\1>", "", fragment, perl = TRUE)
  text <- gsub("(?is)<[^>]+>", "", candidate, perl = TRUE)
  text <- html_unescape(text)
  text <- trimws(gsub("\\s+", " ", text, perl = TRUE))
  if (nzchar(text)) {
    return(TRUE)
  }

  grepl("(?is)<(img|svg|math|iframe|object|embed|video|audio|canvas)\\b", candidate, perl = TRUE)
}

attr_value <- function(attrs, name) {
  pattern <- paste0("\\b", name, "\\s*=\\s*(['\"])(.*?)\\1")
  match <- regexpr(pattern, attrs, perl = TRUE)
  if (match[[1]] == -1) {
    return(NULL)
  }

  starts <- attr(match, "capture.start")
  lengths <- attr(match, "capture.length")
  value <- substring(attrs, starts[2], starts[2] + lengths[2] - 1)
  html_unescape(value)
}

heading_text <- function(html) {
  text <- gsub("(?is)<[^>]+>", "", html, perl = TRUE)
  text <- html_unescape(text)
  trimws(gsub("\\s+", " ", text, perl = TRUE))
}

indent_html <- function(html, spaces) {
  indent <- paste(rep(" ", spaces), collapse = "")
  paste0(indent, gsub("\n", paste0("\n", indent), html, fixed = TRUE))
}
