config <- yaml::read_yaml("_quarto.yml")
resources <- config$project$resources

stopifnot(file.exists(".nojekyll"))
stopifnot(".nojekyll" %in% resources)
stopifnot(file.exists("assets/BibTeX_logo.svg"))
stopifnot("assets/BibTeX_logo.svg" %in% resources)
stopifnot("rss.xml" %in% resources)
