repo <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
script <- file.path(repo, "_scripts", "pre.R")
stopifnot(dir.exists(file.path(repo, "_scripts", "pre")))
stopifnot(dir.exists(file.path(repo, "_scripts", "utils")))
stylesheet <- file.path(repo, "styles.css")

project <- tempfile("pre-render-")
dir.create(project)
oldwd <- setwd(project)
on.exit(setwd(oldwd), add = TRUE)

template_dir <- file.path("assets", "article-template")
dir.create(template_dir, recursive = TRUE)
writeLines(
  c(
    "---",
    'title: "RJOURNAL_TITLE_SENTINEL"',
    "---",
    "",
    "```{=html}",
    "<!-- RJOURNAL_CONTENT_SENTINEL -->",
    "```"
  ),
  file.path(template_dir, "index.qmd")
)
writeLines("project:\n  resources: []", "_article-resources.yml")

dir.create(file.path("_articles", "RJ-2100-001"), recursive = TRUE)
writeLines(
  c(
    "title: Test Article",
    "abstract: This article is used in the generated listing.",
    "author:",
    "- name: Ada Lovelace",
    "- name: Grace Hopper",
    "date: '2100-01-02'",
    "volume: 91",
    "issue: 3",
    "slug: RJ-2100-001"
  ),
  file.path("_articles", "RJ-2100-001", "metadata.yaml")
)
writeLines("%PDF", file.path("_articles", "RJ-2100-001", "RJ-2100-001.pdf"))

dir.create(file.path("_articles", "RJ-2100-999"), recursive = TRUE)
writeLines(
  c(
    "title: Newer Date Older Issue",
    "author: Date Skew Author",
    "date: '2112-01-01'",
    "volume: 91",
    "issue: 3",
    "slug: RJ-2100-999"
  ),
  file.path("_articles", "RJ-2100-999", "metadata.yaml")
)

dir.create(file.path("_issues", "2099-3"), recursive = TRUE)
writeLines("%PDF", file.path("_issues", "2099-3", "2099-3.pdf"))

dir.create(file.path("_articles", "RN-2099-002"), recursive = TRUE)
writeLines(
  c(
    "title: Legacy Article",
    "author: Anonymous",
    "volume: 99",
    "issue: 2",
    "slug: RN-2099-002"
  ),
  file.path("_articles", "RN-2099-002", "metadata.yaml")
)

dir.create(file.path("_articles", "RN-2099-003"), recursive = TRUE)
writeLines(
  c(
    "title: First Last Author Article",
    "author:",
    "- first_name: Peter",
    "  last_name: Watkins",
    "- first_name: Bill",
    "  last_name: Venables",
    "volume: 99",
    "issue: 2",
    "slug: RN-2099-003",
    "journal:",
    "  firstpage: 2"
  ),
  file.path("_articles", "RN-2099-003", "metadata.yaml")
)

for (i in seq_len(11)) {
  slug <- sprintf("RJ-2110-%03d", i)
  dir.create(file.path("_articles", slug), recursive = TRUE)
  writeLines(
    c(
      paste0("title: Latest Article ", i),
      paste0("author: Author ", i),
      if (i == 10) "date: '2111-01-10'" else sprintf("date: '2110-01-%02d'", i),
      "volume: 102",
      "issue: 4",
      paste0("slug: ", slug)
    ),
    file.path("_articles", slug, "metadata.yaml")
  )
}

dir.create(file.path("issues", "old-issue"), recursive = TRUE)
writeLines("stale", file.path("issues", "old-issue", "index.qmd"))

dir.create(file.path("_news", "RJ-2100-1-news"), recursive = TRUE)
writeLines(
  c(
    "title: Test News",
    "author: News Author",
    "date: '2100-02-03'",
    "volume: 92",
    "issue: 1",
    "slug: RJ-2100-1-news"
  ),
  file.path("_news", "RJ-2100-1-news", "metadata.yaml")
)
writeLines("%PDF", file.path("_news", "RJ-2100-1-news", "RJ-2100-1-news.pdf"))

dir.create(file.path("_news", "RJ-2099-3-editorial"), recursive = TRUE)
writeLines(
  c(
    "title: Editorial",
    "author: Issue Editor",
    "date: '2099-09-01'",
    "volume: 91",
    "issue: 3",
    "slug: RJ-2099-3-editorial",
    "journal:",
    "  firstpage: 1"
  ),
  file.path("_news", "RJ-2099-3-editorial", "metadata.yaml")
)

dir.create(file.path("_news", "RJ-2099-3-cran"), recursive = TRUE)
writeLines(
  c(
    "title: Changes on CRAN",
    "author: News Writer",
    "date: '2099-09-01'",
    "volume: 91",
    "issue: 3",
    "slug: RJ-2099-3-cran",
    "journal:",
    "  firstpage: 42"
  ),
  file.path("_news", "RJ-2099-3-cran", "metadata.yaml")
)

source(script, local = new.env(parent = baseenv()))

template <- readLines(file.path(template_dir, "index.qmd"), warn = FALSE)
listing <- yaml::read_yaml(file.path("generated", "articles.yml"))
issues <- yaml::read_yaml(file.path("generated", "issues.yml"))
issues_index <- readLines(file.path("pages", "issues.qmd"), warn = FALSE)
news_index <- readLines(file.path("pages", "news.qmd"), warn = FALSE)
issue_page <- readLines(file.path("issues", "2099-v91-i3", "index.qmd"), warn = FALSE)
legacy_issue_page <- readLines(file.path("issues", "2099-v99-i2", "index.qmd"), warn = FALSE)
stopifnot(file.exists(file.path("generated", "latest-articles.html")))
latest_articles <- readLines(file.path("generated", "latest-articles.html"), warn = FALSE)
home_page <- readLines(file.path(repo, "index.qmd"), warn = FALSE)
style_text <- paste(readLines(stylesheet, warn = FALSE), collapse = "\n")
style_blocks <- regmatches(
  style_text,
  gregexpr("[^{}]+\\{[^{}]*\\}", style_text)
)[[1]]
style_selectors <- sub("\\{.*$", "", style_blocks)
sans_selectors <- style_selectors[grepl("Source Sans 3", style_blocks, fixed = TRUE)]
issue_article_title_style_blocks <- style_blocks[grepl(
  "(^|,|\\n)\\s*\\.issue-article-title([\\s,{:#.]|$)",
  style_blocks
)]
issue_article_style_blocks <- style_blocks[grepl(
  "^\\s*\\.issue-article\\s*\\{",
  style_blocks
)]
issue_article_first_child_style_blocks <- style_blocks[grepl(
  "^\\s*\\.issue-article:first-child\\s*\\{",
  style_blocks
)]
archive_item_style_blocks <- style_blocks[grepl(
  "^\\s*\\.archive-item\\s*\\{",
  style_blocks
)]
archive_item_first_child_style_blocks <- style_blocks[grepl(
  "^\\s*\\.archive-item:first-child\\s*\\{",
  style_blocks
)]
issue_section_heading_style_blocks <- style_blocks[grepl(
  "^\\s*\\.issue-section h3\\s*\\{",
  style_blocks
)]
journal_section_header_style_blocks <- style_blocks[grepl(
  "^\\s*\\.journal-section-header\\s*\\{",
  style_blocks
)]
journal_tagline_style_blocks <- style_blocks[grepl(
  "^\\n*\\.journal-hero-copy p\\.journal-hero-tagline\\s*\\{",
  style_blocks
)]
journal_hero_style_blocks <- style_blocks[grepl(
  "^\\s*\\.journal-hero\\s*\\{",
  style_blocks
)]
inline_code_style_blocks <- style_blocks[grepl(
  "^\\s*p code,",
  style_blocks
)]
pre_style_blocks <- style_blocks[grepl(
  "^\\s*pre\\s*\\{",
  style_blocks
)]
pre_code_style_blocks <- style_blocks[grepl(
  "^\\s*pre code\\s*\\{",
  style_blocks
)]
legacy_r_code_style_blocks <- style_blocks[grepl(
  "pre.r",
  style_blocks,
  fixed = TRUE
)]
source_code_style_blocks <- style_blocks[grepl(
  "pre.sourceCode",
  style_blocks,
  fixed = TRUE
)]
cell_output_code_style_blocks <- style_blocks[grepl(
  "cell-output pre",
  style_blocks,
  fixed = TRUE
)]
code_copy_button_style_blocks <- style_blocks[grepl(
  "code-copy-button",
  style_blocks,
  fixed = TRUE
)]
rj_item <- listing[[which(vapply(
  listing,
  function(item) identical(item$path, "/articles/RJ-2100-001/"),
  logical(1)
))]]
rn_item <- listing[[which(vapply(
  listing,
  function(item) identical(item$path, "/articles/RN-2099-002/"),
  logical(1)
))]]
first_last_item <- listing[[which(vapply(
  listing,
  function(item) identical(item$path, "/articles/RN-2099-003/"),
  logical(1)
))]]
issue_by_path <- function(path) {
  issues[[which(vapply(
    issues,
    function(item) identical(item$path, path),
    logical(1)
  ))]]
}
rj_issue <- issue_by_path("/issues/2099-v91-i3/")
rn_issue <- issue_by_path("/issues/2099-v99-i2/")

stopifnot(any(grepl("RJOURNAL_TITLE_SENTINEL", template, fixed = TRUE)))
stopifnot(any(grepl("RJOURNAL_CONTENT_SENTINEL", template, fixed = TRUE)))
stopifnot(!file.exists("_article-resources.yml"))
stopifnot(length(listing) == 15)
stopifnot(identical(rn_item$title, "Legacy Article"))
stopifnot(identical(rn_item$author, "Anonymous"))
stopifnot(identical(rn_item$year, "2099"))
stopifnot(identical(rn_item$volume, 99L))
stopifnot(identical(rn_item$issue, 2L))
stopifnot(identical(first_last_item$author, "Peter Watkins, Bill Venables"))
stopifnot(identical(rj_item$title, "Test Article"))
stopifnot(identical(rj_item$author, "Ada Lovelace, Grace Hopper"))
stopifnot(identical(rj_item$year, "2099"))
stopifnot(identical(rj_item$volume, 91L))
stopifnot(identical(rj_item$issue, 3L))
stopifnot(any(grepl('title: "Volume 91, Issue 3 (2099)"', issue_page, fixed = TRUE)))
stopifnot(any(grepl('description: "Articles published in the September 2099 issue"', issue_page, fixed = TRUE)))
stopifnot(!any(grepl("issue-description", issue_page, fixed = TRUE)))
stopifnot(!any(grepl("listing:", issue_page, fixed = TRUE)))
stopifnot(any(grepl('<a class="issue-complete-pdf" href="../../_issues/2099-3/2099-3.pdf">', issue_page, fixed = TRUE)))
stopifnot(any(grepl("Complete issue", issue_page, fixed = TRUE)))
stopifnot(!any(grepl("Table of contents", issue_page, fixed = TRUE)))
stopifnot(any(grepl('<section class="issue-section issue-editorial">', issue_page, fixed = TRUE)))
stopifnot(any(grepl('<section class="issue-section issue-contributed-articles">', issue_page, fixed = TRUE)))
stopifnot(any(grepl('<section class="issue-section issue-news-notes">', issue_page, fixed = TRUE)))
stopifnot(any(grepl("### Editorial", issue_page, fixed = TRUE)))
stopifnot(any(grepl("### Research Articles", issue_page, fixed = TRUE)))
stopifnot(!any(grepl("Contributed Research Articles", issue_page, fixed = TRUE)))
stopifnot(any(grepl("### News and Notes", issue_page, fixed = TRUE)))
stopifnot(any(grepl('<article class="issue-article issue-entry">', issue_page, fixed = TRUE)))
stopifnot(any(grepl('<h4 class="issue-article-title"><a href="../../news/RJ-2099-3-editorial/">Editorial</a></h4>', issue_page, fixed = TRUE)))
stopifnot(any(grepl('<p class="issue-article-authors">Issue Editor</p>', issue_page, fixed = TRUE)))
stopifnot(!any(grepl('<p class="issue-article-authors">Issue Editor 1</p>', issue_page, fixed = TRUE)))
stopifnot(any(grepl('<h4 class="issue-article-title"><a href="../../articles/RJ-2100-001/">Test Article</a></h4>', issue_page, fixed = TRUE)))
stopifnot(any(grepl('<p class="issue-article-authors">Ada Lovelace, Grace Hopper</p>', issue_page, fixed = TRUE)))
stopifnot(any(grepl('<h4 class="issue-article-title"><a href="../../news/RJ-2099-3-cran/">Changes on CRAN</a></h4>', issue_page, fixed = TRUE)))
stopifnot(any(grepl('<p class="issue-article-authors">News Writer</p>', issue_page, fixed = TRUE)))
stopifnot(!any(grepl('<p class="issue-article-authors">News Writer 42</p>', issue_page, fixed = TRUE)))
stopifnot(!any(grepl("issue-article-pdf", issue_page, fixed = TRUE)))
stopifnot(!any(grepl("../../_articles/RJ-2100-001/RJ-2100-001.pdf", issue_page, fixed = TRUE)))
stopifnot(sum(grepl('<li class="journal-article-row">', latest_articles, fixed = TRUE)) == 11)
stopifnot(any(grepl('<a href="articles/RJ-2110-010/">Latest Article 10</a>', latest_articles, fixed = TRUE)))
stopifnot(any(grepl('<a href="articles/RJ-2110-011/">Latest Article 11</a>', latest_articles, fixed = TRUE)))
stopifnot(any(grepl('<p class="journal-article-authors">Author 10</p>', latest_articles, fixed = TRUE)))
stopifnot(any(grepl("<span>2110</span>", latest_articles, fixed = TRUE)))
stopifnot(!any(grepl("<span>2111</span>", latest_articles, fixed = TRUE)))
stopifnot(any(grepl("<span>Vol. 102, No. 4</span>", latest_articles, fixed = TRUE)))
stopifnot(!any(grepl("RJ-2100-001", latest_articles, fixed = TRUE)))
stopifnot(!any(grepl("RJ-2100-999", latest_articles, fixed = TRUE)))
stopifnot(any(grepl('<section class="journal-hero"', home_page, fixed = TRUE)))
stopifnot(any(home_page == '<main class="journal-home-main">'))
stopifnot(!any(grepl("^\\s+<main class=\"journal-home-main\">", home_page)))
stopifnot(!any(grepl("<aside", home_page, fixed = TRUE)))
stopifnot(!any(grepl("journal-home-rail", home_page, fixed = TRUE)))
stopifnot(!any(grepl("Aims &amp; Scope", home_page, fixed = TRUE)))
stopifnot(any(grepl('src="assets/R_logo.svg"', home_page, fixed = TRUE)))
stopifnot(any(grepl('<h2 id="latest-articles-heading">Latest Issue Research Articles</h2>', home_page, fixed = TRUE)))
stopifnot(!any(grepl('<h2 id="latest-articles-heading">Latest Articles</h2>', home_page, fixed = TRUE)))
stopifnot(any(grepl('readLines("generated/latest-articles.html"', home_page, fixed = TRUE)))
stopifnot(!any(grepl("R Journal article summaries, for the last four years", home_page, fixed = TRUE)))
stopifnot(any(grepl("(^|,|\\n)\\s*h1\\s*($|,|\\n)", sans_selectors)))
stopifnot(any(grepl("(^|,|\\n)\\s*h2\\s*($|,|\\n)", sans_selectors)))
stopifnot(any(grepl("(^|,|\\n)\\s*\\.navbar([\\s,{:#.]|$)", sans_selectors)))
stopifnot(!any(grepl("(^|,|\\n)\\s*h[3-6]\\s*($|,|\\n)", sans_selectors)))
stopifnot(!any(grepl("\\.(quarto-title-banner|sidebar-title|toc-title)\\b", sans_selectors)))
stopifnot(any(grepl("border-bottom\\s*:\\s*(0|none)", issue_article_title_style_blocks)))
stopifnot(any(grepl("padding-bottom\\s*:\\s*0", issue_article_title_style_blocks)))
stopifnot(length(issue_article_style_blocks) == 1)
stopifnot(!any(grepl("border-(top|bottom)", issue_article_style_blocks)))
stopifnot(length(issue_article_first_child_style_blocks) == 0)
stopifnot(length(issue_section_heading_style_blocks) == 1)
stopifnot(any(grepl("border-bottom\\s*:\\s*(0|none)", issue_section_heading_style_blocks)))
stopifnot(any(grepl("padding-bottom\\s*:\\s*0", issue_section_heading_style_blocks)))
stopifnot(any(grepl("\\.journal-hero-copy h1\\s*\\{[^}]*white-space\\s*:\\s*nowrap", style_text)))
stopifnot(length(journal_tagline_style_blocks) == 1)
stopifnot(any(grepl("white-space\\s*:\\s*nowrap", journal_tagline_style_blocks)))
stopifnot(any(grepl("max-width\\s*:\\s*none", journal_tagline_style_blocks)))
stopifnot(length(journal_hero_style_blocks) == 1)
stopifnot(!any(grepl("overflow\\s*:\\s*hidden", journal_hero_style_blocks)))
stopifnot(any(grepl(
  "@media \\(max-width: 900px\\)[\\s\\S]*\\.journal-hero-logo\\s*\\{[\\s\\S]*max-height\\s*:\\s*150px",
  style_text,
  perl = TRUE
)))
stopifnot(any(grepl("\\.navbar\\s*\\{[^}]*background\\s*:\\s*var\\(--rj-paper\\)", style_text)))
stopifnot(any(grepl("\\.navbar\\s*\\{[^}]*border-bottom\\s*:\\s*1px solid var\\(--rj-rule\\)", style_text)))
stopifnot(any(grepl("\\.navbar \\.nav-link\\s*\\{[^}]*color\\s*:\\s*var\\(--rj-muted\\)", style_text)))
stopifnot(any(grepl("\\.navbar \\.navbar-brand\\s*\\{[^}]*color\\s*:\\s*var\\(--rj-ink\\)", style_text)))
stopifnot(!any(grepl("#dee2e6|#5c6670", style_text)))
stopifnot(any(grepl("--rj-code-bg", style_text, fixed = TRUE)))
stopifnot(length(inline_code_style_blocks) == 1)
stopifnot(any(grepl("background\\s*:\\s*var\\(--rj-code-bg\\)", inline_code_style_blocks)))
stopifnot(any(grepl("border\\s*:\\s*1px solid var\\(--rj-code-border\\)", inline_code_style_blocks)))
stopifnot(length(pre_style_blocks) == 1)
stopifnot(any(grepl("overflow-x\\s*:\\s*auto", pre_style_blocks)))
stopifnot(any(grepl("background\\s*:\\s*var\\(--rj-code-bg\\)", pre_style_blocks)))
stopifnot(any(grepl("border\\s*:\\s*1px solid var\\(--rj-code-border\\)", pre_style_blocks)))
stopifnot(length(pre_code_style_blocks) == 1)
stopifnot(any(grepl("background\\s*:\\s*transparent", pre_code_style_blocks)))
stopifnot(any(grepl("white-space\\s*:\\s*pre", pre_code_style_blocks)))
stopifnot(length(legacy_r_code_style_blocks) >= 1)
stopifnot(length(source_code_style_blocks) >= 1)
stopifnot(length(cell_output_code_style_blocks) >= 1)
stopifnot(length(code_copy_button_style_blocks) >= 1)
stopifnot(length(journal_section_header_style_blocks) == 1)
stopifnot(!any(grepl("border-bottom", journal_section_header_style_blocks, fixed = TRUE)))
stopifnot(any(grepl("\\.journal-home\\s*\\{", style_text)))
stopifnot(any(grepl("\\.journal-hero\\s*\\{", style_text)))
stopifnot(any(grepl("\\.journal-home-layout\\s*\\{", style_text)))
stopifnot(any(grepl("\\.journal-article-row\\s*\\{", style_text)))
stopifnot(!any(grepl("\\.journal-home-rail\\s*\\{", style_text)))
stopifnot(!any(grepl("journal-rail-section", style_text, fixed = TRUE)))
stopifnot(any(grepl("@media (max-width: 900px)", style_text, fixed = TRUE)))
stopifnot(any(grepl("\\.journal-hero-visual\\s*\\{[^}]*justify-content\\s*:\\s*flex-start", style_text)))
stopifnot(any(grepl('title: "Volume 99, Issue 2 (2099)"', legacy_issue_page, fixed = TRUE)))
stopifnot(any(grepl('<h4 class="issue-article-title"><a href="../../articles/RN-2099-003/">First Last Author Article</a></h4>', legacy_issue_page, fixed = TRUE)))
stopifnot(any(grepl('<p class="issue-article-authors">Peter Watkins, Bill Venables</p>', legacy_issue_page, fixed = TRUE)))
stopifnot(!file.exists(file.path("issues", "old-issue", "index.qmd")))
stopifnot(!file.exists("issues.qmd"))
stopifnot(!file.exists("news.qmd"))
stopifnot(length(issues) == 4)
stopifnot(identical(rj_issue$title, "Volume 91, Issue 3 (2099)"))
stopifnot(identical(rj_issue$path, "/issues/2099-v91-i3/"))
stopifnot(identical(rj_issue$year, "2099"))
stopifnot(identical(rj_issue$volume, 91L))
stopifnot(identical(rj_issue$issue, 3L))
stopifnot(identical(rn_issue$title, "Volume 99, Issue 2 (2099)"))
stopifnot(identical(rn_issue$path, "/issues/2099-v99-i2/"))
stopifnot(any(grepl("## 2099", issues_index, fixed = TRUE)))
stopifnot(any(grepl("- [Volume 91, Issue 3](../issues/2099-v91-i3/)", issues_index, fixed = TRUE)))
stopifnot(any(grepl("- [Volume 99, Issue 2](../issues/2099-v99-i2/)", issues_index, fixed = TRUE)))
stopifnot(!any(grepl("listing:", issues_index, fixed = TRUE)))
stopifnot(!file.exists("articles.qmd"))
stopifnot(any(grepl('title: "All News"', news_index, fixed = TRUE)))
stopifnot(any(grepl("toc: true", news_index, fixed = TRUE)))
stopifnot(!any(grepl("_No news found._", news_index, fixed = TRUE)))
stopifnot(any(grepl("## 2100 {.archive-year-heading}", news_index, fixed = TRUE)))
stopifnot(!any(grepl('<h2 class="archive-year-heading">2100</h2>', news_index, fixed = TRUE)))
stopifnot(any(grepl('<h2 class="archive-item-title"><a href="../news/RJ-2100-1-news/">Test News</a></h2>', news_index, fixed = TRUE)))
stopifnot(!any(grepl("archive-item-pdf", news_index, fixed = TRUE)))
stopifnot(!any(grepl("/_news/RJ-2100-1-news/RJ-2100-1-news.pdf", news_index, fixed = TRUE)))
stopifnot(any(grepl("\\.archive-year-heading\\s*\\{[^}]*border-bottom\\s*:\\s*(0|none)", style_text)))
stopifnot(length(archive_item_style_blocks) == 1)
stopifnot(!any(grepl("border-(top|bottom)", archive_item_style_blocks)))
stopifnot(length(archive_item_first_child_style_blocks) == 0)
