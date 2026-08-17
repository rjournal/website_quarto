FROM rocker/r2u:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=UTC \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    bwidget \
    curl \
    pandoc \
    r-cran-broom \
    r-cran-coda \
    r-cran-data.table \
    r-cran-dbi \
    r-cran-dt \
    r-cran-emd \
    r-cran-fixest \
    r-cran-flextable \
    r-cran-gt \
    r-cran-htmltools \
    r-cran-htmlwidgets \
    r-cran-jsonlite \
    r-cran-kableextra \
    r-cran-knitr \
    r-cran-lme4 \
    r-cran-logger \
    r-cran-marginaleffects \
    r-cran-modelsummary \
    r-cran-mvtnorm \
    r-cran-patchwork \
    r-cran-r.utils \
    r-cran-ragg \
    r-cran-readxl \
    r-cran-remotes \
    r-cran-renv \
    r-cran-rmarkdown \
    r-cran-sandwich \
    r-cran-sf \
    r-cran-snow \
    r-cran-snowfall \
    r-cran-gwidgets2tcltk \
    r-cran-tcltk2 \
    r-cran-tidyverse \
    r-cran-tinytex \
    r-cran-tkrplot \
    r-cran-vroom \
    r-cran-yaml12 \
    r-cran-zip \
    tcl \
    tcllib \
    tklib \
    tk \
    tk-table \
    x11-utils \
    xauth \
    xvfb \
    xz-utils \
  && rm -rf /var/lib/apt/lists/*

RUN Rscript -e 'options(repos = c(CRAN = "https://cloud.r-project.org")); if (requireNamespace("bspm", quietly = TRUE)) bspm::enable(); remotes::install_github("rjournal/rjtools")'

COPY entrypoint.sh /usr/local/bin/rjournal-render-entrypoint
RUN chmod +x /usr/local/bin/rjournal-render-entrypoint

WORKDIR /work
