project_output_dir <- function(config_path = "_quarto.yml") {
  env_output_dir <- Sys.getenv("QUARTO_PROJECT_OUTPUT_DIR", unset = "")
  if (nzchar(env_output_dir)) {
    return(env_output_dir)
  }

  if (!file.exists(config_path)) {
    return("_site")
  }

  config <- yaml::read_yaml(config_path)
  output_dir <- config$project[["output-dir"]]
  if (!is.null(output_dir) && nzchar(as.character(output_dir))) {
    return(as.character(output_dir))
  }

  "_site"
}

find_template_source <- function(template_html, template_cache) {
  if (file.exists(template_cache)) {
    template_cache
  } else if (file.exists(template_html)) {
    template_html
  } else {
    NULL
  }
}

validate_template <- function(template) {
  if (!grepl("RJOURNAL_TITLE_SENTINEL", template, fixed = TRUE)) {
    stop("Rendered template is missing RJOURNAL_TITLE_SENTINEL")
  }
  if (!grepl("RJOURNAL_CONTENT_SENTINEL", template, fixed = TRUE)) {
    stop("Rendered template is missing RJOURNAL_CONTENT_SENTINEL")
  }

  invisible(template)
}
