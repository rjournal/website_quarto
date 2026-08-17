metadata_firstpage <- function(metadata) {
  if (!is.null(metadata$journal) && !is.null(metadata$journal$firstpage)) {
    firstpage <- suppressWarnings(as.integer(metadata$journal$firstpage))
    if (!is.na(firstpage)) {
      return(firstpage)
    }
  }

  NULL
}
