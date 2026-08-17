WARNING: THIS REPOSITORY INCLUDES PUBLIC DATA. IT MUST NOT INCLUDE ANY PRIVATE INFORMATION SUCH AS CORRESPONDENCE WITH REVIEWERS OR AUTHORS.

# R Journal Public Archive Data

This repository stores public R Journal and R News publication assets in a directory layout that can be validated and rendered as a Quarto website.

The main components are:

- `_articles/`: one directory per scholarly article.
- `_news/`: one directory per editorial, CRAN/Bioconductor note, conference report, or other news item.
- `_issues/`: one directory per complete issue, including the issue source and complete-issue PDF.
- `_scripts/`: scripts for validation, rendering, and website generation.
- `docs/`: the rendered website output to be published on Github Pages
- `Makefile`: a Makefile for running validation and rendering commands.
- `.nojekyll`: otherwise Github Pages does not style the file properly.
- `index.qmd`, `assets/`, `pages/`: website pages and components
- `style.css`: website styling

Generated website files are disposable and should NOT be committed to the git repository: `generated/`, `pages/`, `issues/`, .

## Publish an article

Create one directory under `_articles/` named with the article slug:

```text
_articles/<slug>/
  <slug>.pdf        # mandatory
  <slug>.html       # optional
  <slug>.bib        # optional
  metadata.yaml     # mandatory
  archive.zip       # mandatory
```

Use these slug patterns:

- `RJ-YYYY-NNN` for R Journal articles, for example `RJ-2025-001`.
- `RN-YYYY-NNN` for legacy R News articles, for example `RN-2005-001`.

Directory components:

### `<slug>.pdf`

Mandatory

The public article PDF created using the Rmarkdown or LaTeX style sheet.

### `<slug>.html`

An HTML rendering of the article body.

Do *NOT* include headers or meta-data such as title, author, abstract, etc. This information is retrieved from `metadata.yaml` automatically when building the website. The HTML file should be minimalist, and only include the article body content, from the introduction to the references and endnoes.

### `<slug>.bib`

Optional

A BibTeX entry for citing the article. When present, this file is published with the article assets and linked from the article page beside the PDF download. If it is absent, the website build can generate one from `metadata.yaml`.

Generate missing article BibTeX files in bulk with:

```sh
Rscript _scripts/generate_article_bib.R
```

### `metadata.yaml`

Public metadata used for the article archive and issue grouping.

R Journal article metadata includes `doi`. Legacy R News article metadata must not include `doi`.

### `archive.zip`

Mandatory

The public source bundle for the item. Save all public files, markup, images, and other assets used to generate `<slug>.html` and `<slug>.pdf`.

Do not include private correspondence, reviewer comments, author emails, or any other non-public material.

## Publish a news or note

Create one directory under `_news/` named with the news or note slug:

```text
_news/<slug>/
  metadata.yaml     # mandatory
  archive.zip       # mandatory
  <slug>.pdf        # mandatory
  <slug>.html       # optional
```

Use these slug patterns:

- `RJ-YYYY-I-topic` for R Journal news and notes, for example `RJ-2025-4-bioconductor`.
- `RN-YYYY-I-topic` for legacy R News items, for example `RN-2001-1-editorial`.

Here `I` is the issue number and `topic` is the short item label used in the archive. Existing migrated items keep their original source slugs.

Directory components:

### `<slug>.pdf`

Mandatory

The public PDF for the news item or note.

### `<slug>.html`

Optional

An HTML rendering of the item body.

Do *NOT* include headers or meta-data such as title, author, abstract, etc. This information is retrieved from `metadata.yaml` automatically when building the website. The HTML file should be minimalist, and only include the item body content. If this file is missing or empty, the generated page embeds `<slug>.pdf`.

### `metadata.yaml`

Public metadata used for the news archive and issue grouping.

News metadata uses the same common fields as articles:

```yaml
title:
abstract:
author:
date:
date_received:
journal:
  firstpage:
  lastpage:
volume:
issue:
slug:
packages:
  cran:
  bioc:
CTV:
```

News items must not include `doi`. The `volume`, `issue`, and `journal.firstpage` fields determine which generated issue page the item appears on and where it appears in that issue. The news archive page at `pages/news.qmd` is generated from `_news/*/metadata.yaml`.

### `archive.zip`

Mandatory

The public source bundle for the item. Save all public files, markup, images, and other assets used to generate `<slug>.html` and `<slug>.pdf`.

Do not include private correspondence, reviewer comments, author emails, or any other non-public material.

Other public assets can live beside these files and are copied to `docs/_news/<slug>/`, excluding `metadata.yaml`, `archive.zip`, and `<slug>.html`.

## Publish an issue

Complete issue files are stored in `_issues/`. Each issue has its own directory which follows this naming convention:

- `_issues/YYYY-I/`

where `YYYY` is the calendar year and `I` is the issue number, for example `_issues/2026-1/`.

The issue directory includes three _mandatory_ files:

```text
_issues/YYYY-I/
  YYYY-I.pdf       # complete issue in a single PDF file
  doi.xml          # DOI deposit metadata
  archive.zip      # public source bundle
  YYYY-I.yml       # optional issue metadata, when available
```

Directory components:

### `YYYY-I.pdf`

Mandatory

The complete issue PDF in a single file.

### `doi.xml`

Mandatory

The public DOI deposit metadata for the issue.

### `archive.zip`

Mandatory

The public source bundle for the issue. Save all public files, markup, images, and other assets used to generate `YYYY-I.pdf` and `doi.xml`.

Do not include private correspondence, reviewer comments, author emails, or any other non-public material.

### `YYYY-I.yml`

Optional

Legacy issue metadata. Keep this file beside `YYYY-I.pdf` when it is available.

## Validate and render

Run validation after adding or changing article/news directories:

```sh
Rscript _scripts/validation.R
```

This writes:

- `validation_report.rds`
- `validation_report.html`

Render missing article/news HTML from archived sources with the Docker renderer:

```sh
_scripts/render_rmarkdown_to_html_v2.sh
```

The script builds `_scripts/render/docker/Dockerfile` into `rjournal-rmarkdown-renderer:v2` when the image is missing, asks the internal R renderer for pending items, and then creates one container per item with a `[current/total]` progress indicator. The image is based on `rocker/r2u:24.04`; standard render packages plus common article dependencies such as `tidyverse`, `data.table`, `marginaleffects`, `modelsummary`, and `sf` are installed as r2u apt packages. The image also installs `rjournal/rjtools` from GitHub. Docker render runs require and enable `bspm` before runtime package installs so missing CRAN dependencies are resolved through r2u binaries instead of compiling from source.

Use `--workers=<n>` or `RJOURNAL_RENDER_DOCKER_WORKERS` to run multiple item containers in parallel. The wrapper asks R for item directories that do not already have the expected `<slug>.html` file. `RJOURNAL_RENDER_DOCKER_MEMORY` and `RJOURNAL_RENDER_DOCKER_CPUS` are applied per container. Each item container also has an outer timeout controlled by `--container-timeout=<seconds>` or `RJOURNAL_RENDER_DOCKER_ITEM_TIMEOUT`; the default is 300 seconds, and `0` disables it. The inner `rmarkdown::render()` timeout defaults to 300 seconds and can be changed with `--timeout=<seconds>`.

When parallel containers discover missing R packages, package installation is serialized with a shared lock under `tmp/` because apt/r2u installs cannot run concurrently.

For Docker rendering, custom `--log=<path>` values must live under `tmp/` so the log path is writable inside the container.

Per-item container stdout/stderr is written under `tmp/render-container-logs/<collection>/<slug>.log`; failed items print the tail of that log. Xvfb startup logs are written next to them as `<slug>.xvfb.log`.

Useful environment variables:

- `RJOURNAL_RENDER_DOCKER_MEMORY` sets the per-item container memory limit, default `8g`.
- `RJOURNAL_RENDER_DOCKER_CPUS` sets the per-item CPU quota, default `2`.
- `RJOURNAL_RENDER_DOCKER_WORKERS` sets the number of item containers to run in parallel, default `1`.
- `RJOURNAL_RENDER_DOCKER_ITEM_TIMEOUT` sets the outer per-item Docker container timeout in seconds, default `300`; use `0` to disable.
- `RJOURNAL_RENDER_DOCKER_BUILD=0` skips automatic image builds.
- `RJOURNAL_RENDER_DOCKER_IMAGE` overrides the image tag.
- `RJOURNAL_RENDER_DOCKER_CONFIG` overrides the isolated Docker CLI config directory, default `tmp/docker-config`.
- `RJOURNAL_RENDER_DOCKER_BUILDKIT` controls the Docker build backend, default `0` to avoid host credential helpers during public base-image resolution.
- `RJOURNAL_RENDER_INSTALL_LOCK_TIMEOUT` sets the package-install lock timeout in seconds, default `1800`.

Render the website with:

```sh
quarto render
```

The Quarto project intentionally renders only the homepage, static pages, the article template, and generated issue source pages. Final per-article and per-news pages are created in the post-render step from `assets/article-template/index.qmd`.
