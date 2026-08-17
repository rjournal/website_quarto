config <- yaml::read_yaml("_quarto.yml")

navbar_left <- config$website$navbar$left
navbar_right <- config$website$navbar$right
contribute <- navbar_left[[which(vapply(
  navbar_left,
  function(item) identical(item$text, "Contribute"),
  logical(1)
))]]

reader_item <- contribute$menu[[which(vapply(
  contribute$menu,
  function(item) identical(item$text, "Report problems"),
  logical(1)
))]]

stopifnot(identical(reader_item$href, "pages/contribute_readers.qmd"))
stopifnot(file.exists(reader_item$href))

rss_item <- navbar_right[[which(vapply(
  navbar_right,
  function(item) identical(item$icon, "rss"),
  logical(1)
))]]

stopifnot(identical(rss_item$href, "rss.xml"))
stopifnot(identical(rss_item[["aria-label"]], "RSS feed"))
stopifnot(identical(config$website[["site-url"]], "https://journal.r-project.org"))
stopifnot(grepl(
  '<link rel="alternate" type="application/rss+xml" title="The R Journal" href="/rss.xml">',
  config$format$html[["include-in-header"]]$text,
  fixed = TRUE
))

footer <- config$website[["page-footer"]]
stopifnot(is.character(footer$center), length(footer$center) == 1L)
stopifnot(grepl("© The R Foundation", footer$center, fixed = TRUE))
stopifnot(grepl('<a href="mailto:r-journal@r-project.org">Contact us.</a>', footer$center, fixed = TRUE))
