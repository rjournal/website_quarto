copy_item_assets <- function(root, slug) {
  src_dir <- file.path(root, slug)
  asset_paths <- list.files(src_dir, recursive = TRUE, full.names = TRUE)
  excluded_paths <- file.path(src_dir, c("metadata.yaml", "archive.zip", paste0(slug, ".html")))
  asset_paths <- setdiff(asset_paths, excluded_paths)
  asset_paths <- asset_paths[file.exists(asset_paths)]

  if (length(asset_paths) == 0) {
    return(FALSE)
  }

  output_dir <- file.path(site_dir, root, slug)
  dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
  copied <- vapply(asset_paths, function(asset_path) {
    relative_path <- substring(asset_path, nchar(src_dir) + 2)
    target_path <- file.path(output_dir, relative_path)
    dir.create(dirname(target_path), showWarnings = FALSE, recursive = TRUE)
    file.copy(asset_path, target_path, overwrite = TRUE)
  }, logical(1))
  if (!all(copied)) {
    stop("Failed to copy assets for ", file.path(root, slug))
  }
  TRUE
}

copy_issue_pdfs <- function() {
  if (!dir.exists("_issues")) {
    return(FALSE)
  }

  pdf_paths <- list.files("_issues", pattern = "\\.pdf$", recursive = TRUE, full.names = TRUE)
  if (length(pdf_paths) == 0) {
    return(FALSE)
  }

  copied <- vapply(pdf_paths, function(pdf_path) {
    relative_path <- substring(pdf_path, nchar("_issues") + 2)
    target_path <- file.path(site_dir, "_issues", relative_path)
    dir.create(dirname(target_path), showWarnings = FALSE, recursive = TRUE)
    file.copy(pdf_path, target_path, overwrite = TRUE)
  }, logical(1))
  if (!all(copied)) {
    stop("Failed to copy issue PDFs")
  }
  TRUE
}
