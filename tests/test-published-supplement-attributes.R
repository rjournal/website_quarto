git_attr <- function(path, attr) {
  output <- system2(
    "git",
    c("check-attr", attr, "--", path),
    stdout = TRUE,
    stderr = TRUE
  )
  prefix <- paste0(path, ": ", attr, ": ")
  stopifnot(length(output) == 1L)
  stopifnot(startsWith(output, prefix))
  sub(prefix, "", output, fixed = TRUE)
}

published_supplement <- "docs/_articles/RJ-2099-001/supplement.zip"
source_archive <- "_articles/RJ-2099-001/archive.zip"

stopifnot(identical(git_attr(source_archive, "filter"), "lfs"))
stopifnot(identical(git_attr(source_archive, "diff"), "lfs"))
stopifnot(identical(git_attr(source_archive, "merge"), "lfs"))

stopifnot(identical(git_attr(published_supplement, "filter"), "unset"))
stopifnot(identical(git_attr(published_supplement, "diff"), "unset"))
stopifnot(identical(git_attr(published_supplement, "merge"), "unset"))
