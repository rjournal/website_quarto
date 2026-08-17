read_metadata <- function(root, slug) {
  metadata_path <- file.path(root, slug, "metadata.yaml")
  if (!file.exists(metadata_path)) {
    return(list())
  }

  metadata <- yaml::read_yaml(metadata_path)
  if (is.list(metadata)) {
    metadata
  } else {
    list()
  }
}
