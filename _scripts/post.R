script_files <- vapply(sys.frames(), function(frame) if (is.null(frame$ofile)) NA_character_ else frame$ofile, character(1))
script_files <- script_files[!is.na(script_files)]
script_file <- if (length(script_files)) script_files[[length(script_files)]] else sub("^--file=", "", grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)[[1]])
source(file.path(dirname(normalizePath(script_file, mustWork = TRUE)), "utils", "script.R"), local = TRUE)

source_script_files(file.path("utils", c("io.R", "html.R", "metadata.R", "icons.R")))
source_script_files(file.path("post", c(
  "config.R",
  "io.R",
  "metadata.R",
  "html.R",
  "toc.R",
  "embeds.R",
  "supplements.R",
  "pages.R",
  "assets.R",
  "cleanup.R"
)))

site_dir <- project_output_dir()
template_html <- file.path(site_dir, "assets", "article-template", "index.html")
template_cache <- file.path(site_dir, "assets", "article-template", "template.html")

template_source <- find_template_source(template_html, template_cache)

if (!is.null(template_source)) {
  template <- read_text(template_source)
  validate_template(template)

  if (!file.exists(template_cache)) {
    writeLines(template, template_cache)
  }

  for (slug in sort(item_dirs("_articles"))) {
    extract_article_supplement("_articles", slug)
    if (write_item_page(template, "articles", "_articles", slug)) {
      copy_item_assets("_articles", slug)
    }
  }

  for (slug in sort(item_dirs("_news"))) {
    if (write_item_page(template, "news", "_news", slug)) {
      copy_item_assets("_news", slug)
    }
  }

  copy_issue_pdfs()
  write_template_redirect(template_html)
}

cleanup_generated_sources(site_dir)

fn <- file.path(site_dir, ".nojekyll")
try(file.create(fn), silent = TRUE)
