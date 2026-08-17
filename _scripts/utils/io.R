item_dirs <- function(root) {
  if (dir.exists(root)) {
    list.dirs(root, recursive = FALSE, full.names = FALSE)
  } else {
    character()
  }
}

read_text <- function(path) {
  paste(readLines(path, warn = FALSE), collapse = "\n")
}
