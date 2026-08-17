repo <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
script <- file.path(repo, "_scripts", "post.R")
stopifnot(dir.exists(file.path(repo, "_scripts", "post")))
stopifnot(dir.exists(file.path(repo, "_scripts", "utils")))
output_dir <- "docs"

project <- tempfile("post-render-")
dir.create(project)
oldwd <- setwd(project)
on.exit(setwd(oldwd), add = TRUE)

writeLines(
  c(
    "project:",
    "  type: website",
    paste0("  output-dir: ", output_dir)
  ),
  "_quarto.yml"
)

dir.create(file.path("_articles", "RJ-2099-001"), recursive = TRUE)
writeLines(
  c(
    "<html>",
    "<head><title>source title</title><script>headScript()</script></head>",
    "<body>",
    "<!-- source comment -->",
    "<script>bodyScript()</script>",
    '<div class="article">',
    '<section class="article-page-abstract">',
    '<h2 class="article-page-abstract-title">Abstract</h2>',
    '<p>This <strong>rendered</strong> abstract came from article HTML.</p>',
    "</section>",
    '<div id="introduction" class="section level2">',
    "<h2>Introduction</h2>",
    "<p>intro</p>",
    "</div>",
    '<div id="details" class="section level3">',
    "<h3>Details</h3>",
    "<p>details</p>",
    "</div>",
    "<p>article</p>",
    "</div>",
    "</body>",
    "</html>"
  ),
  file.path("_articles", "RJ-2099-001", "RJ-2099-001.html")
)
writeLines("%PDF", file.path("_articles", "RJ-2099-001", "RJ-2099-001.pdf"))
writeLines(
  c(
    "@article{RJ-2099-001,",
    "  title = {Article Metadata Title},",
    "  author = {Ada Lovelace and Grace Hopper},",
    "  year = {2099}",
    "}"
  ),
  file.path("_articles", "RJ-2099-001", "RJ-2099-001.bib")
)
writeLines(
  c(
    "title: Article Metadata Title",
    "author:",
    "- name: Ada Lovelace",
    "  affiliation: Analytical Engine Lab",
    "- first_name: Grace",
    "  last_name: Hopper",
    "  affiliation:",
    "  - Compiler Bureau",
    "  - Naval Computing Unit",
    "abstract: This **metadata** abstract must not be inserted separately.",
    "date: '2099-09-01'",
    "journal:",
    "  firstpage: 10",
    "  lastpage: 18",
    "volume: 91",
    "issue: 3",
    "slug: RJ-2099-001",
    "doi: 10.32614/RJ-2099-001"
  ),
  file.path("_articles", "RJ-2099-001", "metadata.yaml")
)
archive_source <- file.path(tempdir(), "post-render-archive-source")
unlink(archive_source, recursive = TRUE, force = TRUE)
dir.create(file.path(archive_source, "RJ-2099-001"), recursive = TRUE)
writeLines(
  "supplement payload",
  file.path(archive_source, "RJ-2099-001", "RJ-2099-001.zip")
)
old_archive_wd <- setwd(archive_source)
utils::zip(
  zipfile = file.path(project, "_articles", "RJ-2099-001", "archive.zip"),
  files = file.path("RJ-2099-001", "RJ-2099-001.zip"),
  flags = "-q"
)
setwd(old_archive_wd)

dir.create(file.path("_articles", "RN-2099-002"), recursive = TRUE)
writeLines("%PDF", file.path("_articles", "RN-2099-002", "RN-2099-002.pdf"))
writeLines(
  c(
    "title: PDF Metadata Title",
    "author: Anonymous",
    "volume: 99",
    "issue: 2",
    "slug: RN-2099-002",
    "doi: 10.32614/RN-2099-002"
  ),
  file.path("_articles", "RN-2099-002", "metadata.yaml")
)

dir.create(file.path("_articles", "RJ-2099-003"), recursive = TRUE)
writeLines(
  c(
    "<html>",
    "<body>",
    "<!-- code folding -->",
    "<script>supportScript()</script>",
    "</body>",
    "</html>"
  ),
  file.path("_articles", "RJ-2099-003", "RJ-2099-003.html")
)
writeLines("%PDF", file.path("_articles", "RJ-2099-003", "RJ-2099-003.pdf"))
writeLines(
  c(
    "title: Empty HTML Article",
    "author:",
    "- name: Fallback Author",
    "  affiliation: Fallback Institute",
    "volume: 91",
    "issue: 3",
    "slug: RJ-2099-003",
    "doi: 10.32614/RJ-2099-003"
  ),
  file.path("_articles", "RJ-2099-003", "metadata.yaml")
)

dir.create(file.path("_articles", "RJ-2099-004"), recursive = TRUE)
writeLines(
  c(
    "<html>",
    "<body>",
    '<div class="article">',
    '<div id="legacy-introduction" class="section level1">',
    "<h1>Legacy Introduction</h1>",
    "<p>legacy intro</p>",
    "</div>",
    '<div id="legacy-details" class="section level2">',
    "<h2>Legacy Details</h2>",
    "<p>legacy details</p>",
    "</div>",
    '<div id="conclusion" class="section level1">',
    "<h1>Conclusion</h1>",
    "<p>legacy conclusion</p>",
    "</div>",
    '<div id="acknowledgements" class="section level1 unnumbered">',
    '<h1 class="unnumbered">Acknowledgements</h1>',
    "<p>legacy acknowledgements</p>",
    "</div>",
    '<div id="refs" class="references csl-bib-body hanging-indent">',
    '<div id="ref-example" class="csl-entry">Reference entry.</div>',
    "</div>",
    "</div>",
    "</body>",
    "</html>"
  ),
  file.path("_articles", "RJ-2099-004", "RJ-2099-004.html")
)
writeLines("%PDF", file.path("_articles", "RJ-2099-004", "RJ-2099-004.pdf"))
writeLines(
  c(
    "title: Legacy Heading Article",
    "author: Section Author",
    "volume: 91",
    "issue: 3",
    "slug: RJ-2099-004",
    "doi: 10.32614/RJ-2099-004"
  ),
  file.path("_articles", "RJ-2099-004", "metadata.yaml")
)

dir.create(file.path("_news", "RJ-2099-1-news"), recursive = TRUE)
writeLines("<html><body><p>news</p></body></html>", file.path("_news", "RJ-2099-1-news", "RJ-2099-1-news.html"))
writeLines("%PDF", file.path("_news", "RJ-2099-1-news", "RJ-2099-1-news.pdf"))
writeLines(
  c(
    "title: News Metadata Title",
    "author:",
    "- name: News Reporter",
    "- name: Beat Writer",
    "doi: 10.32614/RJ-2099-1-news"
  ),
  file.path("_news", "RJ-2099-1-news", "metadata.yaml")
)

dir.create(file.path("_issues", "2099-1"), recursive = TRUE)
writeLines("%PDF", file.path("_issues", "2099-1", "2099-1.pdf"))
writeLines("<html><body>old issue page</body></html>", file.path("_issues", "2099-1", "2099-1.html"))

template_dir <- file.path(output_dir, "assets", "article-template")
dir.create(template_dir, recursive = TRUE)
writeLines(
  c(
    "<html>",
    "<head>",
    "<title>RJOURNAL_TITLE_SENTINEL - The R Journal</title>",
    '<script src="../../site_libs/quarto-html/quarto.js"></script>',
    "</head>",
    "<body>",
    '<div id="quarto-content" class="quarto-container page-columns page-rows-contents page-layout-full page-navbar">',
    "<!-- sidebar -->",
    "<!-- margin-sidebar -->",
    "    ",
    "<!-- main -->",
    '<main class="content column-page" id="quarto-document-content">',
    '<header id="title-block-header" class="quarto-title-block default">',
    '<div class="quarto-title">',
    "<h1>RJOURNAL_TITLE_SENTINEL</h1>",
    "</div>",
    '<div class="quarto-title-meta column-page">',
    "</div>",
    "</header>",
    "<!-- RJOURNAL_CONTENT_SENTINEL -->",
    "</main>",
    "</div>",
    "</body>",
    "</html>"
  ),
  file.path(template_dir, "index.html")
)

dir.create(file.path("generated"), recursive = TRUE)
writeLines("- title: disposable", file.path("generated", "articles.yml"))
dir.create(file.path("issues", "2099-v91-i3"), recursive = TRUE)
writeLines("disposable", file.path("issues", "2099-v91-i3", "index.qmd"))
dir.create("pages", recursive = TRUE)
writeLines("disposable issue index", file.path("pages", "issues.qmd"))
writeLines("disposable news index", file.path("pages", "news.qmd"))
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
writeLines("stale articles page", file.path(output_dir, "articles.html"))

source(script, local = new.env(parent = baseenv()))
source(script, local = new.env(parent = baseenv()))

article_html <- readLines(file.path(output_dir, "articles", "RJ-2099-001", "index.html"), warn = FALSE)
article_pdf <- readLines(file.path(output_dir, "articles", "RN-2099-002", "index.html"), warn = FALSE)
article_empty_html <- readLines(file.path(output_dir, "articles", "RJ-2099-003", "index.html"), warn = FALSE)
article_legacy_headings <- readLines(file.path(output_dir, "articles", "RJ-2099-004", "index.html"), warn = FALSE)
news_html <- readLines(file.path(output_dir, "news", "RJ-2099-1-news", "index.html"), warn = FALSE)

stopifnot(any(grepl("<title>Article Metadata Title - The R Journal</title>", article_html, fixed = TRUE)))
stopifnot(any(grepl("<h1>Article Metadata Title</h1>", article_html, fixed = TRUE)))
stopifnot(!any(grepl("<h1>RJ-2099-001</h1>", article_html, fixed = TRUE)))
stopifnot(any(grepl('<p class="article-page-authors">Ada Lovelace<sup>1</sup>, Grace Hopper<sup>2,3</sup></p>', article_html, fixed = TRUE)))
stopifnot(any(grepl('<ol class="article-page-affiliations" aria-label="Author affiliations">', article_html, fixed = TRUE)))
stopifnot(any(grepl("<li>Analytical Engine Lab</li>", article_html, fixed = TRUE)))
stopifnot(any(grepl("<li>Compiler Bureau</li>", article_html, fixed = TRUE)))
stopifnot(any(grepl("<li>Naval Computing Unit</li>", article_html, fixed = TRUE)))
stopifnot(any(grepl('<p class="article-page-meta">', article_html, fixed = TRUE)))
stopifnot(any(grepl('<a class="article-page-issue" href="../../issues/2099-v91-i3/">Volume 91, Issue 3</a>', article_html, fixed = TRUE)))
stopifnot(any(grepl('<a class="article-page-doi" href="https://doi.org/10.32614/RJ-2099-001">https://doi.org/10.32614/RJ-2099-001</a>', article_html, fixed = TRUE)))
stopifnot(!any(grepl("DOI: ", article_html, fixed = TRUE)))
stopifnot(any(grepl('<a class="article-page-action article-page-pdf" href="../../_articles/RJ-2099-001/RJ-2099-001.pdf"><svg class="issue-pdf-icon"', article_html, fixed = TRUE)))
stopifnot(any(grepl('<span class="article-page-action-label">PDF</span></a>', article_html, fixed = TRUE)))
stopifnot(file.exists(file.path("_articles", "RJ-2099-001", "supplement.zip")))
stopifnot(any(grepl('<a class="article-page-action article-page-supplement" href="../../_articles/RJ-2099-001/supplement.zip" download="RJ-2099-001-supplement.zip"><svg class="article-page-supplement-icon"', article_html, fixed = TRUE)))
stopifnot(any(grepl('<span class="article-page-action-label">Supplement</span></a>', article_html, fixed = TRUE)))
stopifnot(any(grepl('<a class="article-page-action article-page-cite" href="#citation"><svg class="article-page-cite-icon"', article_html, fixed = TRUE)))
stopifnot(any(grepl('<span class="article-page-action-label">Cite</span></a>', article_html, fixed = TRUE)))
stopifnot(!any(grepl("Download PDF", article_html, fixed = TRUE)))
article_html_text <- paste(article_html, collapse = "\n")
article_actions <- regmatches(article_html_text, regexpr('<p class="article-page-actions">[\\s\\S]*?</p>', article_html_text, perl = TRUE))
stopifnot(length(article_actions) == 1L)
stopifnot(!grepl("BibTeX", article_actions, fixed = TRUE))
stopifnot(any(grepl('<section id="citation" class="article-page-citation">', article_html, fixed = TRUE)))
stopifnot(any(grepl('<h2>Citation</h2>', article_html, fixed = TRUE)))
stopifnot(any(grepl('<h3>Formatted citation</h3>', article_html, fixed = TRUE)))
stopifnot(any(grepl('<code id="citation-formatted-RJ-2099-001">Ada Lovelace, Grace Hopper (2099). Article Metadata Title. The R Journal, 91(3), 10-18. https://doi.org/10.32614/RJ-2099-001</code>', article_html, fixed = TRUE)))
stopifnot(any(grepl('<button type="button" class="article-copy-button" data-copy-target="citation-formatted-RJ-2099-001" aria-label="Copy formatted citation">', article_html, fixed = TRUE)))
stopifnot(any(grepl('<h3>BibTeX</h3>', article_html, fixed = TRUE)))
stopifnot(any(grepl('<code id="citation-bibtex-RJ-2099-001">@article{RJ-2099-001,', article_html, fixed = TRUE)))
stopifnot(any(grepl('  title = {Article Metadata Title},', article_html, fixed = TRUE)))
stopifnot(any(grepl('<button type="button" class="article-copy-button" data-copy-target="citation-bibtex-RJ-2099-001" aria-label="Copy BibTeX citation">', article_html, fixed = TRUE)))
stopifnot(any(grepl('<a class="article-page-bibtex-download" href="../../_articles/RJ-2099-001/RJ-2099-001.bib">Download BibTeX</a>', article_html, fixed = TRUE)))
stopifnot(any(grepl("navigator.clipboard.writeText", article_html, fixed = TRUE)))
stopifnot(sum(grepl('<section class="article-page-abstract">', article_html, fixed = TRUE)) == 1L)
stopifnot(any(grepl('<h2 class="article-page-abstract-title">Abstract</h2>', article_html, fixed = TRUE)))
stopifnot(any(grepl('<p>This <strong>rendered</strong> abstract came from article HTML.</p>', article_html, fixed = TRUE)))
stopifnot(!any(grepl("metadata", article_html, fixed = TRUE)))
abstract_position <- regexpr('<section class="article-page-abstract">', article_html_text, fixed = TRUE)[[1]]
introduction_position <- regexpr('<div id="introduction" class="section level2">', article_html_text, fixed = TRUE)[[1]]
stopifnot(abstract_position > 0L, introduction_position > 0L, abstract_position < introduction_position)
stopifnot(any(grepl('<svg class="issue-pdf-icon"', article_html, fixed = TRUE)))
stopifnot(any(grepl('<div id="quarto-content" class="quarto-container page-columns page-rows-contents page-layout-article page-navbar">', article_html, fixed = TRUE)))
stopifnot(any(grepl('<div id="quarto-margin-sidebar" class="sidebar margin-sidebar">', article_html, fixed = TRUE)))
stopifnot(any(grepl('<main class="content" id="quarto-document-content">', article_html, fixed = TRUE)))
stopifnot(any(grepl('<div class="quarto-title-meta">', article_html, fixed = TRUE)))
stopifnot(any(grepl('<nav id="TOC" role="doc-toc" class="toc-active">', article_html, fixed = TRUE)))
stopifnot(any(grepl('<h2 id="toc-title">On this page</h2>', article_html, fixed = TRUE)))
stopifnot(any(grepl('<a href="#introduction" id="toc-introduction" class="nav-link active" data-scroll-target="#introduction">Introduction</a>', article_html, fixed = TRUE)))
stopifnot(any(grepl('<ul class="collapse">', article_html, fixed = TRUE)))
stopifnot(any(grepl('<a href="#details" id="toc-details" class="nav-link" data-scroll-target="#details">Details</a>', article_html, fixed = TRUE)))
stopifnot(!any(grepl('<div class="article-page-with-toc">', article_html, fixed = TRUE)))
stopifnot(!any(grepl('<aside class="article-toc">', article_html, fixed = TRUE)))
stopifnot(!any(grepl('page-layout-full', article_html, fixed = TRUE)))
stopifnot(!any(grepl('class="content column-page"', article_html, fixed = TRUE)))
stopifnot(!any(grepl('class="quarto-title-meta column-page"', article_html, fixed = TRUE)))
stopifnot(any(grepl('<article class="article-reader article-reader-inline">', article_html, fixed = TRUE)))
stopifnot(any(grepl('<div class="article">', article_html, fixed = TRUE)))
stopifnot(any(grepl("<p>article</p>", article_html, fixed = TRUE)))
stopifnot(!any(grepl("<iframe", article_html, fixed = TRUE)))
stopifnot(!any(grepl("headScript", article_html, fixed = TRUE)))
stopifnot(any(grepl("bodyScript", article_html, fixed = TRUE)))
stopifnot(!any(grepl("source comment", article_html, fixed = TRUE)))
stopifnot(any(grepl('<script src="../../site_libs/quarto-html/quarto.js"></script>', article_html, fixed = TRUE)))
article_position <- regexpr("<p>article</p>", article_html_text, fixed = TRUE)[[1]]
citation_position <- regexpr('<section id="citation" class="article-page-citation">', article_html_text, fixed = TRUE)[[1]]
stopifnot(article_position > 0L, citation_position > article_position)

stopifnot(any(grepl("<title>PDF Metadata Title - The R Journal</title>", article_pdf, fixed = TRUE)))
stopifnot(any(grepl("<h1>PDF Metadata Title</h1>", article_pdf, fixed = TRUE)))
stopifnot(!any(grepl("<h1>RN-2099-002</h1>", article_pdf, fixed = TRUE)))
stopifnot(any(grepl('<p class="article-page-authors">Anonymous</p>', article_pdf, fixed = TRUE)))
stopifnot(!any(grepl("article-page-affiliations", article_pdf, fixed = TRUE)))
stopifnot(any(grepl('<a class="article-page-issue" href="../../issues/2099-v99-i2/">Volume 99, Issue 2</a>', article_pdf, fixed = TRUE)))
stopifnot(any(grepl('<a class="article-page-doi" href="https://doi.org/10.32614/RN-2099-002">https://doi.org/10.32614/RN-2099-002</a>', article_pdf, fixed = TRUE)))
stopifnot(!any(grepl("DOI: ", article_pdf, fixed = TRUE)))
stopifnot(any(grepl('<a class="article-page-action article-page-pdf" href="../../_articles/RN-2099-002/RN-2099-002.pdf"><svg class="issue-pdf-icon"', article_pdf, fixed = TRUE)))
stopifnot(!any(grepl("article-page-supplement", article_pdf, fixed = TRUE)))
stopifnot(any(grepl('<a class="article-page-action article-page-cite" href="#citation"><svg class="article-page-cite-icon"', article_pdf, fixed = TRUE)))
stopifnot(any(grepl('<section id="citation" class="article-page-citation">', article_pdf, fixed = TRUE)))
stopifnot(any(grepl('<code id="citation-formatted-RN-2099-002">Anonymous (2099). PDF Metadata Title. The R Journal, 99(2). https://doi.org/10.32614/RN-2099-002</code>', article_pdf, fixed = TRUE)))
stopifnot(any(grepl('<code id="citation-bibtex-RN-2099-002">@article{RN-2099-002,', article_pdf, fixed = TRUE)))
stopifnot(!any(grepl("Download BibTeX", article_pdf, fixed = TRUE)))
stopifnot(!any(grepl('<nav id="TOC" role="doc-toc"', article_pdf, fixed = TRUE)))
stopifnot(any(grepl('page-layout-full', article_pdf, fixed = TRUE)))
stopifnot(any(grepl('<iframe class="article-reader-object" src="../../_articles/RN-2099-002/RN-2099-002.pdf" title="PDF article"></iframe>', article_pdf, fixed = TRUE)))
stopifnot(!any(grepl('<object class="article-reader-object"', article_pdf, fixed = TRUE)))
stopifnot(!any(grepl(">Open PDF</a>", article_pdf, fixed = TRUE)))

stopifnot(any(grepl("<title>Empty HTML Article - The R Journal</title>", article_empty_html, fixed = TRUE)))
stopifnot(any(grepl('<p class="article-page-authors">Fallback Author</p>', article_empty_html, fixed = TRUE)))
stopifnot(any(grepl('<p class="article-page-affiliations">Fallback Institute</p>', article_empty_html, fixed = TRUE)))
stopifnot(any(grepl('<a class="article-page-action article-page-pdf" href="../../_articles/RJ-2099-003/RJ-2099-003.pdf"><svg class="issue-pdf-icon"', article_empty_html, fixed = TRUE)))
stopifnot(any(grepl('<a class="article-page-action article-page-cite" href="#citation"><svg class="article-page-cite-icon"', article_empty_html, fixed = TRUE)))
stopifnot(any(grepl('<section id="citation" class="article-page-citation">', article_empty_html, fixed = TRUE)))
stopifnot(any(grepl('<iframe class="article-reader-object" src="../../_articles/RJ-2099-003/RJ-2099-003.pdf" title="PDF article"></iframe>', article_empty_html, fixed = TRUE)))
stopifnot(!any(grepl("supportScript", article_empty_html, fixed = TRUE)))

stopifnot(any(grepl('<a href="#legacy-introduction" id="toc-legacy-introduction" class="nav-link active" data-scroll-target="#legacy-introduction">Legacy Introduction</a>', article_legacy_headings, fixed = TRUE)))
stopifnot(any(grepl('<a href="#legacy-details" id="toc-legacy-details" class="nav-link" data-scroll-target="#legacy-details">Legacy Details</a>', article_legacy_headings, fixed = TRUE)))
stopifnot(any(grepl('<a href="#conclusion" id="toc-conclusion" class="nav-link" data-scroll-target="#conclusion">Conclusion</a>', article_legacy_headings, fixed = TRUE)))
stopifnot(any(grepl('<a href="#acknowledgements" id="toc-acknowledgements" class="nav-link" data-scroll-target="#acknowledgements">Acknowledgements</a>', article_legacy_headings, fixed = TRUE)))
stopifnot(any(grepl('<h1 id="references" class="unnumbered">References</h1>', article_legacy_headings, fixed = TRUE)))
stopifnot(any(grepl('<a href="#references" id="toc-references" class="nav-link" data-scroll-target="#references">References</a>', article_legacy_headings, fixed = TRUE)))
stopifnot(any(grepl('<div id="refs" class="references csl-bib-body hanging-indent">', article_legacy_headings, fixed = TRUE)))

stopifnot(any(grepl("<title>News Metadata Title - The R Journal</title>", news_html, fixed = TRUE)))
stopifnot(any(grepl("<h1>News Metadata Title</h1>", news_html, fixed = TRUE)))
stopifnot(!any(grepl("<h1>RJ-2099-1-news</h1>", news_html, fixed = TRUE)))
stopifnot(any(grepl('<p class="article-page-authors">News Reporter, Beat Writer</p>', news_html, fixed = TRUE)))
stopifnot(any(grepl('<p class="article-page-meta"><a class="article-page-doi" href="https://doi.org/10.32614/RJ-2099-1-news">https://doi.org/10.32614/RJ-2099-1-news</a></p>', news_html, fixed = TRUE)))
stopifnot(any(grepl('<a class="issue-complete-pdf" href="../../_news/RJ-2099-1-news/RJ-2099-1-news.pdf">Download PDF', news_html, fixed = TRUE)))
stopifnot(!any(grepl('<div class="article-page-with-toc">', news_html, fixed = TRUE)))
stopifnot(!any(grepl('<nav id="TOC" role="doc-toc"', news_html, fixed = TRUE)))
stopifnot(any(grepl('<article class="article-reader article-reader-inline">', news_html, fixed = TRUE)))
stopifnot(any(grepl("<p>news</p>", news_html, fixed = TRUE)))
stopifnot(!any(grepl("<iframe", news_html, fixed = TRUE)))

template_html <- readLines(file.path(template_dir, "index.html"), warn = FALSE)
template_cache <- readLines(file.path(template_dir, "template.html"), warn = FALSE)
stopifnot(file.exists(file.path(template_dir, "index.html")))
stopifnot(file.exists(file.path(template_dir, "template.html")))
stopifnot(any(grepl('<meta http-equiv="refresh" content="0; url=../../">', template_html, fixed = TRUE)))
stopifnot(!any(grepl("RJOURNAL_TITLE_SENTINEL", template_html, fixed = TRUE)))
stopifnot(!any(grepl("RJOURNAL_CONTENT_SENTINEL", template_html, fixed = TRUE)))
stopifnot(any(grepl("RJOURNAL_TITLE_SENTINEL", template_cache, fixed = TRUE)))
stopifnot(any(grepl("RJOURNAL_CONTENT_SENTINEL", template_cache, fixed = TRUE)))

stopifnot(file.exists(file.path(output_dir, "_articles", "RJ-2099-001", "RJ-2099-001.pdf")))
stopifnot(file.exists(file.path(output_dir, "_articles", "RJ-2099-001", "RJ-2099-001.bib")))
stopifnot(file.exists(file.path(output_dir, "_articles", "RJ-2099-001", "supplement.zip")))
stopifnot(!file.exists(file.path(output_dir, "_articles", "RJ-2099-001", "RJ-2099-001.html")))
stopifnot(!file.exists(file.path(output_dir, "_articles", "RJ-2099-001", "metadata.yaml")))
stopifnot(!file.exists(file.path(output_dir, "_articles", "RJ-2099-001", "archive.zip")))
stopifnot(file.exists(file.path(output_dir, "_news", "RJ-2099-1-news", "RJ-2099-1-news.pdf")))
stopifnot(!file.exists(file.path(output_dir, "_news", "RJ-2099-1-news", "RJ-2099-1-news.html")))
stopifnot(!file.exists(file.path(output_dir, "_news", "RJ-2099-1-news", "metadata.yaml")))
stopifnot(file.exists(file.path(output_dir, "_issues", "2099-1", "2099-1.pdf")))
stopifnot(!file.exists(file.path(output_dir, "_issues", "2099-1", "2099-1.html")))
stopifnot(!dir.exists("generated"))
stopifnot(!dir.exists("issues"))
stopifnot(!file.exists("issues.qmd"))
stopifnot(!file.exists("news.qmd"))
stopifnot(!file.exists(file.path("pages", "issues.qmd")))
stopifnot(!file.exists(file.path("pages", "news.qmd")))
stopifnot(!file.exists(file.path(output_dir, "articles.html")))
stopifnot(!dir.exists("_site"))
