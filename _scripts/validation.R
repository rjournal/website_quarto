library(tinytable)

common_metadata_fields <- c(
  "title",
  "abstract",
  "author",
  "date",
  "date_received",
  "journal.firstpage",
  "journal.lastpage",
  "volume",
  "issue",
  "slug",
  "packages",
  "packages.cran",
  "packages.bioc",
  "CTV"
)

required_metadata_fields <- list(
  `_articles` = append(common_metadata_fields, "doi", after = match("slug", common_metadata_fields)),
  `_news` = common_metadata_fields
)

metadata_fields_for_item <- function(collection, slug) {
  if (identical(collection, "_articles") && startsWith(slug, "RJ-")) {
    return(required_metadata_fields[["_articles"]])
  }

  common_metadata_fields
}

unexpected_metadata_fields_for_item <- function(collection, slug) {
  if (identical(collection, "_news") || startsWith(slug, "RN-")) {
    return("doi")
  }

  character()
}

path_value <- function(x, field) {
  parts <- strsplit(field, ".", fixed = TRUE)[[1]]
  value <- x

  for (part in parts) {
    if (!is.list(value) || is.null(value[[part]])) {
      return(NULL)
    }
    value <- value[[part]]
  }

  value
}

is_blank_value <- function(x) {
  if (is.null(x)) {
    return(TRUE)
  }

  if (length(x) == 0) {
    return(TRUE)
  }

  if (is.character(x)) {
    return(all(is.na(x) | trimws(x) == ""))
  }

  if (is.list(x)) {
    return(length(x) == 0)
  }

  if (all(is.na(x))) {
    return(TRUE)
  }

  FALSE
}

read_metadata <- function(path) {
  tryCatch(
    yaml::read_yaml(path),
    error = function(e) {
      structure(
        list(message = conditionMessage(e)),
        class = "metadata_parse_error"
      )
    }
  )
}

validation_table <- function(dat) {
  if (nrow(dat) == 0) {
    return("No rows to report.")
  }

  tt(dat)
}

validate_item <- function(collection, item_dir) {
  slug <- basename(item_dir)
  metadata_path <- file.path(item_dir, "metadata.yaml")
  archive_path <- file.path(item_dir, "archive.zip")
  pdf_path <- file.path(item_dir, paste0(slug, ".pdf"))

  file_check <- data.frame(
    collection = collection,
    slug = slug,
    has_metadata = file.exists(metadata_path),
    has_archive = file.exists(archive_path),
    has_pdf = file.exists(pdf_path),
    stringsAsFactors = FALSE
  )
  file_check$ok_all_expected <- with(
    file_check,
    has_metadata & has_archive & has_pdf
  )

  parse_error <- data.frame(
    collection = character(),
    slug = character(),
    error = character(),
    stringsAsFactors = FALSE
  )
  missing_fields <- data.frame(
    collection = character(),
    slug = character(),
    field = character(),
    stringsAsFactors = FALSE
  )
  unexpected_fields <- data.frame(
    collection = character(),
    slug = character(),
    field = character(),
    stringsAsFactors = FALSE
  )

  if (!file_check$has_metadata) {
    parse_error <- data.frame(
      collection = collection,
      slug = slug,
      error = "metadata.yaml is missing",
      stringsAsFactors = FALSE
    )
  } else {
    metadata <- read_metadata(metadata_path)

    if (inherits(metadata, "metadata_parse_error")) {
      parse_error <- data.frame(
        collection = collection,
        slug = slug,
        error = metadata$message,
        stringsAsFactors = FALSE
      )
    } else {
      metadata_slug <- if (is_blank_value(metadata$slug)) slug else as.character(metadata$slug)
      metadata_fields <- metadata_fields_for_item(collection, metadata_slug)
      missing <- metadata_fields[vapply(
        metadata_fields,
        function(field) is_blank_value(path_value(metadata, field)),
        logical(1)
      )]

      if (length(missing) > 0) {
        missing_fields <- data.frame(
          collection = collection,
          slug = slug,
          field = missing,
          stringsAsFactors = FALSE
        )
      }

      unexpected <- unexpected_metadata_fields_for_item(collection, metadata_slug)
      unexpected <- unexpected[vapply(
        unexpected,
        function(field) !is.null(path_value(metadata, field)),
        logical(1)
      )]

      if (length(unexpected) > 0) {
        unexpected_fields <- data.frame(
          collection = collection,
          slug = slug,
          field = unexpected,
          stringsAsFactors = FALSE
        )
      }
    }
  }

  list(
    file_check = file_check,
    parse_error = parse_error,
    missing_fields = missing_fields,
    unexpected_fields = unexpected_fields
  )
}

bind_rows <- function(items, name) {
  rows <- lapply(items, `[[`, name)
  rows <- rows[vapply(rows, nrow, integer(1)) > 0]

  if (length(rows) == 0) {
    return(data.frame())
  }

  do.call(rbind, rows)
}

validate_collection <- function(collection_dir,
                                collection = basename(collection_dir)) {
  item_dirs <- sort(list.dirs(collection_dir, recursive = FALSE, full.names = TRUE))
  results <- lapply(
    item_dirs,
    function(item_dir) validate_item(collection, item_dir)
  )

  list(
    file_checks = bind_rows(results, "file_check"),
    parse_errors = bind_rows(results, "parse_error"),
    missing_fields = bind_rows(results, "missing_fields"),
    unexpected_fields = bind_rows(results, "unexpected_fields")
  )
}

summarise_validation <- function(file_checks, parse_errors, missing_fields, unexpected_fields) {
  collections <- sort(unique(file_checks$collection))

  collection_summary <- do.call(rbind, lapply(collections, function(collection) {
    checks <- file_checks[file_checks$collection == collection, , drop = FALSE]
    data.frame(
      collection = collection,
      directories = nrow(checks),
      missing_metadata = sum(!checks$has_metadata),
      missing_archive = sum(!checks$has_archive),
      missing_pdf = sum(!checks$has_pdf),
      parse_errors = sum(parse_errors$collection == collection),
      metadata_missing_field_rows = sum(missing_fields$collection == collection),
      metadata_unexpected_field_rows = sum(unexpected_fields$collection == collection),
      stringsAsFactors = FALSE
    )
  }))

  missing_file_summary <- do.call(rbind, lapply(collections, function(collection) {
    checks <- file_checks[file_checks$collection == collection, , drop = FALSE]
    data.frame(
      collection = collection,
      file = c("metadata.yaml", "archive.zip", "<slug>.pdf"),
      missing = c(
        sum(!checks$has_metadata),
        sum(!checks$has_archive),
        sum(!checks$has_pdf)
      ),
      stringsAsFactors = FALSE
    )
  }))

  parse_error_summary <- data.frame(
    collection = collections,
    parse_errors = vapply(
      collections,
      function(collection) sum(parse_errors$collection == collection),
      integer(1)
    ),
    stringsAsFactors = FALSE
  )

  missing_field_summary <- data.frame()
  if (nrow(missing_fields) > 0) {
    field_pairs <- unique(missing_fields[c("collection", "field")])
    field_pairs <- field_pairs[order(field_pairs$collection, field_pairs$field), ]
    missing_field_summary <- do.call(rbind, lapply(seq_len(nrow(field_pairs)), function(i) {
      collection <- field_pairs$collection[[i]]
      field <- field_pairs$field[[i]]
      rows <- missing_fields[
        missing_fields$collection == collection & missing_fields$field == field,
        ,
        drop = FALSE
      ]
      data.frame(
        collection = collection,
        field = field,
        missing_or_blank = nrow(rows),
        stringsAsFactors = FALSE
      )
    }))
  }

  unexpected_field_summary <- data.frame()
  if (nrow(unexpected_fields) > 0) {
    field_pairs <- unique(unexpected_fields[c("collection", "field")])
    field_pairs <- field_pairs[order(field_pairs$collection, field_pairs$field), ]
    unexpected_field_summary <- do.call(rbind, lapply(seq_len(nrow(field_pairs)), function(i) {
      collection <- field_pairs$collection[[i]]
      field <- field_pairs$field[[i]]
      rows <- unexpected_fields[
        unexpected_fields$collection == collection & unexpected_fields$field == field,
        ,
        drop = FALSE
      ]
      data.frame(
        collection = collection,
        field = field,
        present_but_unexpected = nrow(rows),
        stringsAsFactors = FALSE
      )
    }))
  }

  list(
    collection_summary = collection_summary,
    missing_file_summary = missing_file_summary,
    parse_error_summary = parse_error_summary,
    missing_field_summary = missing_field_summary,
    unexpected_field_summary = unexpected_field_summary
  )
}

build_validation_report <- function(root = ".") {
  collections <- c("_articles", "_news")
  collection_dirs <- file.path(root, collections)
  names(collection_dirs) <- collections

  missing_collections <- names(collection_dirs)[!dir.exists(collection_dirs)]
  if (length(missing_collections) > 0) {
    stop(
      "Missing collection directories: ",
      paste(missing_collections, collapse = ", "),
      call. = FALSE
    )
  }

  validations <- Map(
    function(collection_dir, collection) {
      validate_collection(collection_dir, collection)
    },
    collection_dirs,
    names(collection_dirs)
  )

  file_checks <- do.call(rbind, lapply(validations, `[[`, "file_checks"))
  parse_errors <- bind_rows(validations, "parse_errors")
  missing_fields <- bind_rows(validations, "missing_fields")
  unexpected_fields <- bind_rows(validations, "unexpected_fields")
  summaries <- summarise_validation(file_checks, parse_errors, missing_fields, unexpected_fields)

  list(
    generated_at = Sys.time(),
    metadata_fields = required_metadata_fields,
    collection_summary = summaries$collection_summary,
    missing_file_summary = summaries$missing_file_summary,
    parse_error_summary = summaries$parse_error_summary,
    file_checks = file_checks,
    file_failures = file_checks[!file_checks$ok_all_expected, , drop = FALSE],
    parse_errors = parse_errors,
    missing_field_summary = summaries$missing_field_summary,
    missing_fields = missing_fields,
    unexpected_field_summary = summaries$unexpected_field_summary,
    unexpected_fields = unexpected_fields
  )
}

write_validation_report <- function(report, path = "validation_report.rds") {
  saveRDS(report, path)
  invisible(path)
}
