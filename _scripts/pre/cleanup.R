remove_article_resources <- function() {
  if (file.exists("_article-resources.yml")) {
    unlink("_article-resources.yml")
  }
}

reset_issues_dir <- function(issues_dir) {
  if (dir.exists(issues_dir)) {
    unlink(issues_dir, recursive = TRUE)
  }
}
