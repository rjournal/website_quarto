reviewers_page <- readLines("pages/contribute_reviewers.qmd", warn = FALSE)
reviewers_text <- paste(reviewers_page, collapse = "\n")
reviewer_form_url <- "https://docs.google.com/forms/d/e/1FAIpQLSf8EmpF85ASWqPHXqV0vdQd-GHhNBaAZZEYf4qxO3gTl-eGyA/viewform"

stopifnot(grepl(reviewer_form_url, reviewers_text, fixed = TRUE))
stopifnot(grepl("[complete the reviewer volunteer form]", reviewers_text, fixed = TRUE))
stopifnot(!grepl("contact the managing editor", reviewers_text, fixed = TRUE))
stopifnot(!grepl("mailto:r-journal@r-project.org", reviewers_text, fixed = TRUE))
