repo <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
script <- file.path(repo, "_scripts", "generate_article_bib.R")

project <- tempfile("generate-article-bib-")
dir.create(project)

article_dir <- file.path(project, "_articles", "RJ-2099-004")
dir.create(article_dir, recursive = TRUE)
writeLines(
  c(
    "title: Generated Citation Title",
    "author:",
    "- name: Ada Lovelace",
    "- first_name: Grace",
    "  last_name: Hopper",
    "date: '2099-09-01'",
    "volume: 91",
    "issue: 3",
    "journal:",
    "  firstpage: 10",
    "  lastpage: 18",
    "slug: RJ-2099-004",
    "doi: 10.32614/RJ-2099-004"
  ),
  file.path(article_dir, "metadata.yaml")
)

existing_dir <- file.path(project, "_articles", "RJ-2099-005")
dir.create(existing_dir, recursive = TRUE)
writeLines("@article{existing}", file.path(existing_dir, "custom.bib"))
writeLines(
  c(
    "title: Existing Citation",
    "author: Existing Author",
    "volume: 91",
    "issue: 3",
    "slug: RJ-2099-005"
  ),
  file.path(existing_dir, "metadata.yaml")
)

env <- new.env(parent = baseenv())
source(script, local = env)

result <- env$generate_article_bibtex(project)
generated_path <- file.path(article_dir, "RJ-2099-004.bib")

stopifnot(file.exists(generated_path))
stopifnot(!file.exists(file.path(existing_dir, "RJ-2099-005.bib")))
stopifnot(identical(result$generated, 1L))
stopifnot(identical(result$skipped_existing, 1L))

bib <- readLines(generated_path, warn = FALSE)
stopifnot(any(grepl("@article{RJ-2099-004,", bib, fixed = TRUE)))
stopifnot(any(grepl("TITLE = {{Generated Citation Title}}", bib, fixed = TRUE)))
stopifnot(any(grepl("AUTHOR = {Ada Lovelace and Grace Hopper}", bib, fixed = TRUE)))
stopifnot(any(grepl("JOURNAL = {{The R Journal}}", bib, fixed = TRUE)))
stopifnot(any(grepl("YEAR = {2099}", bib, fixed = TRUE)))
stopifnot(any(grepl("VOLUME = {91}", bib, fixed = TRUE)))
stopifnot(any(grepl("NUMBER = {3}", bib, fixed = TRUE)))
stopifnot(any(grepl("PAGES = {10-18}", bib, fixed = TRUE)))
stopifnot(any(grepl("DOI = {10.32614/RJ-2099-004}", bib, fixed = TRUE)))
stopifnot(any(grepl("URL = {https://journal.r-project.org/articles/RJ-2099-004/}", bib, fixed = TRUE)))
