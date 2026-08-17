metadata_text <- function(value) {
  if (is.null(value)) {
    return(NULL)
  }

  value <- trimws(as.character(value[[1]]))
  if (nzchar(value)) value else NULL
}

text_sentence <- function(text) {
  text <- trimws(as.character(text))
  if (grepl("[.!?]$", text)) {
    text
  } else {
    paste0(text, ".")
  }
}

metadata_page_range <- function(metadata) {
  first <- metadata_text(metadata$journal$firstpage)
  last <- metadata_text(metadata$journal$lastpage)

  if (!is.null(first) && !is.null(last)) {
    return(paste0(first, "-", last))
  }
  if (!is.null(first)) {
    return(first)
  }
  if (!is.null(last)) {
    return(last)
  }

  NULL
}

metadata_author_names <- function(author) {
  if (is.null(author)) {
    return(character())
  }

  if (is.character(author)) {
    return(author[nzchar(author)])
  }

  if (!is.list(author)) {
    return(character())
  }

  names <- vapply(author, function(entry) {
    if (is.character(entry)) {
      entry[[1]]
    } else if (is.list(entry) && !is.null(entry$name)) {
      as.character(entry$name)
    } else if (is.list(entry) && (!is.null(entry$first_name) || !is.null(entry$last_name))) {
      trimws(paste(
        c(as.character(entry$first_name), as.character(entry$last_name)),
        collapse = " "
      ))
    } else {
      NA_character_
    }
  }, character(1))

  names[!is.na(names) & nzchar(names)]
}

article_journal_citation <- function(metadata) {
  journal <- "The R Journal"
  volume <- metadata_text(metadata$volume)
  issue <- metadata_text(metadata$issue)
  pages <- metadata_page_range(metadata)

  if (!is.null(volume) && !is.null(issue)) {
    journal <- paste0(journal, ", ", volume, "(", issue, ")")
  } else if (!is.null(volume)) {
    journal <- paste0(journal, ", ", volume)
  } else if (!is.null(issue)) {
    journal <- paste0(journal, ", issue ", issue)
  }

  if (!is.null(pages)) {
    journal <- paste0(journal, ", ", pages)
  }

  journal
}

formatted_article_citation <- function(slug, metadata) {
  title <- metadata_text(metadata$title)
  if (is.null(title)) {
    title <- slug
  }

  author <- author_text(metadata$author)
  year <- article_year(slug, metadata)

  prefix <- if (!is.null(author) && !is.null(year)) {
    paste0(author, " (", year, "). ")
  } else if (!is.null(author)) {
    paste0(author, ". ")
  } else if (!is.null(year)) {
    paste0(year, ". ")
  } else {
    ""
  }

  citation <- paste(
    paste0(prefix, text_sentence(title)),
    text_sentence(article_journal_citation(metadata))
  )

  doi <- doi_url(metadata$doi)
  if (!is.null(doi)) {
    citation <- paste(citation, doi)
  }

  citation
}

bibtex_field <- function(name, value) {
  if (is.null(value)) {
    return(character())
  }

  value <- gsub("[\r\n]+", " ", as.character(value))
  value <- trimws(value)
  if (!nzchar(value)) {
    return(character())
  }

  paste0("  ", name, " = {", value, "}")
}

generated_bibtex_citation <- function(slug, metadata) {
  author <- metadata_author_names(metadata$author)
  fields <- c(
    bibtex_field("title", metadata_text(metadata$title)),
    bibtex_field("author", if (length(author) > 0) paste(author, collapse = " and ") else NULL),
    bibtex_field("journal", "The R Journal"),
    bibtex_field("year", article_year(slug, metadata)),
    bibtex_field("volume", metadata_text(metadata$volume)),
    bibtex_field("number", metadata_text(metadata$issue)),
    bibtex_field("pages", metadata_page_range(metadata)),
    bibtex_field("doi", metadata_text(metadata$doi)),
    bibtex_field("url", paste0("https://journal.r-project.org/articles/", slug, "/"))
  )

  paste(
    c(
      paste0("@article{", slug, ","),
      paste0(fields, collapse = ",\n"),
      "}"
    ),
    collapse = "\n"
  )
}

article_bibtex_citation <- function(root, slug, metadata) {
  bib <- file.path(root, slug, paste0(slug, ".bib"))
  if (file.exists(bib)) {
    return(read_text(bib))
  }

  generated_bibtex_citation(slug, metadata)
}

article_copyable_code <- function(id, label, text, button_label) {
  paste0(
    "<h3>", html_escape(label), "</h3>",
    "\n",
    '<div class="article-copyable-code">',
    '<button type="button" class="article-copy-button" data-copy-target="',
    html_escape(id),
    '" aria-label="',
    html_escape(button_label),
    '">',
    rjournal_copy_icon,
    rjournal_check_icon,
    "</button>",
    '<pre><code id="',
    html_escape(id),
    '">',
    html_escape(text),
    "</code></pre>",
    "</div>"
  )
}

article_citation_copy_script <- function() {
  paste0(
    "<script>",
    "(function(){",
    "if(window.rJournalCitationCopyInit){return;}",
    "window.rJournalCitationCopyInit=true;",
    "function copied(button,label){button.classList.add('is-copied');button.setAttribute('aria-label','Copied');window.setTimeout(function(){button.classList.remove('is-copied');button.setAttribute('aria-label',label);},1600);}",
    "function fallback(text,done){var textarea=document.createElement('textarea');textarea.value=text;textarea.setAttribute('readonly','');textarea.style.position='fixed';textarea.style.top='-9999px';document.body.appendChild(textarea);textarea.select();try{document.execCommand('copy');}finally{document.body.removeChild(textarea);}done();}",
    "document.addEventListener('click',function(event){var button=event.target.closest?event.target.closest('.article-copy-button'):null;if(!button){return;}var target=document.getElementById(button.getAttribute('data-copy-target'));if(!target){return;}var text=target.innerText||target.textContent||'';var label=button.getAttribute('aria-label')||'Copy';var done=function(){copied(button,label);};if(navigator.clipboard&&navigator.clipboard.writeText){navigator.clipboard.writeText(text).then(done,function(){fallback(text,done);});}else{fallback(text,done);}});",
    "})();",
    "</script>"
  )
}

item_citation_section <- function(root, slug, metadata) {
  bib <- file.path(root, slug, paste0(slug, ".bib"))
  download <- if (file.exists(bib)) {
    paste0(
      '<p class="article-page-bibtex-download-row"><a class="article-page-bibtex-download" href="../../',
      html_escape(bib),
      '">Download BibTeX</a></p>'
    )
  } else {
    character()
  }

  paste(
    c(
      '<section id="citation" class="article-page-citation">',
      "<h2>Citation</h2>",
      article_copyable_code(
        paste0("citation-formatted-", slug),
        "Formatted citation",
        formatted_article_citation(slug, metadata),
        "Copy formatted citation"
      ),
      article_copyable_code(
        paste0("citation-bibtex-", slug),
        "BibTeX",
        article_bibtex_citation(root, slug, metadata),
        "Copy BibTeX citation"
      ),
      download,
      "</section>",
      article_citation_copy_script()
    ),
    collapse = "\n"
  )
}

item_action_links <- function(root, slug, include_citation = FALSE) {
  pdf <- file.path(root, slug, paste0(slug, ".pdf"))
  supplement <- file.path(root, slug, "supplement.zip")
  has_supplement <- isTRUE(include_citation) && file.exists(supplement)
  if (!file.exists(pdf) && !has_supplement && !isTRUE(include_citation)) {
    return(character())
  }

  links <- character()
  if (file.exists(pdf)) {
    if (isTRUE(include_citation)) {
      links <- c(
        links,
        paste0(
          '<a class="article-page-action article-page-pdf" href="../../',
          html_escape(pdf),
          '">',
          rjournal_pdf_icon,
          '<span class="article-page-action-label">PDF</span></a>'
        )
      )
    } else {
      links <- c(
        links,
        paste0(
          '<a class="issue-complete-pdf" href="../../',
          html_escape(pdf),
          '">Download PDF ',
          rjournal_pdf_icon,
          "</a>"
        )
      )
    }
  }

  if (has_supplement) {
    links <- c(
      links,
      paste0(
        '<a class="article-page-action article-page-supplement" href="../../',
        html_escape(supplement),
        '" download="',
        html_escape(paste0(slug, "-supplement.zip")),
        '">',
        rjournal_supplement_icon,
        '<span class="article-page-action-label">Supplement</span></a>'
      )
    )
  }

  if (isTRUE(include_citation)) {
    links <- c(
      links,
      paste0(
        '<a class="article-page-action article-page-cite" href="#citation">',
        rjournal_cite_icon,
        '<span class="article-page-action-label">Cite</span></a>'
      )
    )
  }

  paste0(
    '<p class="article-page-actions">',
    paste(links, collapse = "\n"),
    "</p>"
  )
}

author_header_entry_name <- function(entry) {
  if (is.character(entry)) {
    name <- entry[!is.na(entry) & nzchar(entry)]
    return(if (length(name) > 0L) trimws(name[[1]]) else NULL)
  }

  if (!is.list(entry)) {
    return(NULL)
  }

  if (!is.null(entry$name)) {
    name <- as.character(entry$name)
    name <- name[!is.na(name) & nzchar(name)]
    return(if (length(name) > 0L) trimws(name[[1]]) else NULL)
  }

  if (!is.null(entry$first_name) || !is.null(entry$last_name)) {
    name <- as.character(c(entry$first_name, entry$last_name))
    name <- name[!is.na(name) & nzchar(name)]
    return(if (length(name) > 0L) trimws(paste(name, collapse = " ")) else NULL)
  }

  NULL
}

clean_author_affiliation_value <- function(affiliation) {
  affiliation <- as.character(affiliation)
  affiliation <- affiliation[!is.na(affiliation)]
  if (length(affiliation) == 0L) {
    return(NA_character_)
  }

  affiliation <- paste(affiliation, collapse = " ")
  affiliation <- gsub("[\r\n]+", " ", affiliation)
  affiliation <- gsub("[[:space:]]+", " ", affiliation)
  affiliation <- trimws(affiliation)
  if (!nzchar(affiliation) || tolower(affiliation) %in% c(".na.character", "na", "n/a", "none", "null")) {
    return(NA_character_)
  }

  affiliation
}

clean_author_affiliations <- function(affiliation) {
  if (is.null(affiliation)) {
    return(character())
  }

  if (is.list(affiliation)) {
    affiliation <- unlist(affiliation, recursive = TRUE, use.names = FALSE)
  }

  affiliations <- vapply(affiliation, clean_author_affiliation_value, character(1))
  unique(affiliations[!is.na(affiliations) & nzchar(affiliations)])
}

author_header_entry <- function(entry) {
  name <- author_header_entry_name(entry)
  if (is.null(name) || !nzchar(name)) {
    return(NULL)
  }

  affiliations <- if (is.list(entry) && !is.null(entry$affiliation)) {
    clean_author_affiliations(entry$affiliation)
  } else {
    character()
  }

  list(name = name, affiliations = affiliations)
}

author_header_entries <- function(author) {
  if (is.null(author)) {
    return(list())
  }

  if (is.character(author)) {
    author <- author[!is.na(author) & nzchar(author)]
    return(lapply(author, function(name) list(name = trimws(name), affiliations = character())))
  }

  if (!is.list(author)) {
    return(list())
  }

  if (!is.null(author$name) || !is.null(author$first_name) || !is.null(author$last_name)) {
    entry <- author_header_entry(author)
    return(if (is.null(entry)) list() else list(entry))
  }

  entries <- lapply(author, author_header_entry)
  Filter(Negate(is.null), entries)
}

author_affiliations <- function(entries) {
  affiliations <- unlist(lapply(entries, function(entry) entry$affiliations), use.names = FALSE)
  unique(affiliations[nzchar(affiliations)])
}

author_header_lines <- function(author) {
  entries <- author_header_entries(author)
  if (length(entries) == 0L) {
    return(character())
  }

  affiliations <- author_affiliations(entries)
  has_missing_affiliation <- any(vapply(entries, function(entry) length(entry$affiliations) == 0L, logical(1)))
  use_superscripts <- length(affiliations) > 1L || (length(affiliations) == 1L && has_missing_affiliation)

  author_markup <- vapply(entries, function(entry) {
    name <- html_escape(entry$name)
    if (use_superscripts && length(entry$affiliations) > 0L) {
      affiliation_ids <- match(entry$affiliations, affiliations)
      affiliation_ids <- affiliation_ids[!is.na(affiliation_ids)]
      if (length(affiliation_ids) > 0L) {
        affiliation_ids <- sort(unique(affiliation_ids))
        name <- paste0(name, "<sup>", paste(affiliation_ids, collapse = ","), "</sup>")
      }
    }
    name
  }, character(1))

  lines <- paste0('<p class="article-page-authors">', paste(author_markup, collapse = ", "), "</p>")
  if (length(affiliations) == 0L) {
    return(lines)
  }

  if (!use_superscripts) {
    return(c(
      lines,
      paste0('<p class="article-page-affiliations">', html_escape(affiliations[[1]]), "</p>")
    ))
  }

  c(
    lines,
    '<ol class="article-page-affiliations" aria-label="Author affiliations">',
    paste0("<li>", html_escape(affiliations), "</li>"),
    "</ol>"
  )
}

item_header <- function(
  root,
  slug,
  metadata,
  include_issue = FALSE,
  include_citation = FALSE,
  include_affiliations = FALSE
) {
  lines <- character()

  if (isTRUE(include_affiliations)) {
    lines <- c(lines, author_header_lines(metadata$author))
  } else {
    author <- author_text(metadata$author)
    if (!is.null(author) && nzchar(author)) {
      lines <- c(lines, paste0('<p class="article-page-authors">', html_escape(author), "</p>"))
    }
  }

  meta <- character()
  if (isTRUE(include_issue)) {
    current_issue_slug <- issue_slug(metadata, slug)
    current_issue_title <- issue_title(metadata)
    if (!is.null(current_issue_slug) && !is.null(current_issue_title)) {
      meta <- c(
        meta,
        paste0(
          '<a class="article-page-issue" href="../../issues/',
          html_escape(current_issue_slug),
          '/">',
          html_escape(current_issue_title),
          "</a>"
        )
      )
    }
  }

  doi <- doi_url(metadata$doi)
  if (!is.null(doi)) {
    meta <- c(
      meta,
      paste0(
        '<a class="article-page-doi" href="',
        html_escape(doi),
        '">',
        html_escape(doi),
        "</a>"
      )
    )
  }
  if (length(meta) > 0) {
    lines <- c(
      lines,
      paste0(
        '<p class="article-page-meta">',
        paste(meta, collapse = '<span class="article-page-meta-separator">·</span>'),
        "</p>"
      )
    )
  }

  c(lines, item_action_links(root, slug, include_citation = include_citation))
}

write_item_page <- function(template, section, root, slug) {
  embed <- build_embed(root, slug, include_toc = identical(section, "articles"))
  if (is.null(embed)) {
    return(FALSE)
  }

  metadata <- read_metadata(root, slug)
  page_title <- if (!is.null(metadata$title) && nzchar(as.character(metadata$title))) {
    as.character(metadata$title)
  } else {
    slug
  }
  include_citation <- identical(section, "articles")
  content <- paste(
    c(
      item_header(
        root,
        slug,
        metadata,
        include_issue = identical(section, "articles"),
        include_citation = include_citation,
        include_affiliations = identical(section, "articles")
      ),
      embed$content,
      if (include_citation) item_citation_section(root, slug, metadata) else character()
    ),
    collapse = "\n"
  )

  page <- gsub(
    "RJOURNAL_TITLE_SENTINEL",
    html_escape(page_title),
    template,
    fixed = TRUE
  )
  page <- gsub(
    "<!-- RJOURNAL_CONTENT_SENTINEL -->",
    content,
    page,
    fixed = TRUE
  )
  if (!is.null(embed$toc)) {
    page <- apply_article_toc_layout(page, embed$toc)
  }

  output_dir <- file.path(site_dir, section, slug)
  dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
  writeLines(page, file.path(output_dir, "index.html"))
  TRUE
}
