script_dir <- function(default_subdir = "_scripts") {
  files <- vapply(sys.frames(), function(frame) {
    if (is.null(frame$ofile)) {
      NA_character_
    } else {
      frame$ofile
    }
  }, character(1))
  files <- files[!is.na(files)]
  if (length(files) > 0) {
    return(dirname(normalizePath(files[[length(files)]], mustWork = TRUE)))
  }

  file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (length(file_arg) > 0) {
    return(dirname(normalizePath(sub("^--file=", "", file_arg[[1]]), mustWork = TRUE)))
  }

  file.path(getwd(), default_subdir)
}

source_script_file <- function(file, envir = parent.frame()) {
  source(file.path(script_dir(), file), local = envir)
}

source_script_files <- function(files, envir = parent.frame()) {
  for (file in files) {
    source_script_file(file, envir = envir)
  }
  invisible(files)
}
