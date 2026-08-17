about_path <- file.path("pages", "about.qmd")
about <- readLines(about_path, warn = FALSE)

resource_refs <- regmatches(
  about,
  gregexpr('"(resources/[^"]+)"', about)
)
resource_refs <- unlist(resource_refs, use.names = FALSE)
stopifnot(length(resource_refs) == 0L)

asset_refs <- regmatches(
  about,
  gregexpr('"((\\.\\./)?assets/[^"]+)"', about)
)
asset_refs <- unlist(asset_refs, use.names = FALSE)
asset_refs <- gsub('^"|"$', "", asset_refs)
asset_paths <- sub("^\\.\\./", "", asset_refs)

stopifnot("assets/time_to_accept_plot.png" %in% asset_paths)
stopifnot("assets/article_status_plot.png" %in% asset_paths)
stopifnot(all(file.exists(asset_paths)))
