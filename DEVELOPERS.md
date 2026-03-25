# Developer Guide

This document contains instructions for developers working on the Proxiome Analysis Template.

## Table of Contents

- [Code Style](#code-style)
- [Linting](#linting)
- [Styler](#styler)
- [Managing the renv Environment](#managing-the-renv-environment)
- [Setting Up on a Virtual Machine](#setting-up-on-a-virtual-machine)

---

## Code Style

This project uses `lintr` for linting and `styler` for code formatting. The configuration is compatible with `pixelatorR` style conventions.

---

## Linting

To run the linter, you need to install `lintr`. Then you can use one of the the following commands:

```r
# Lint entire package
lintr::lint_package()

# Lint single file
lintr::lint("path/to/file.R")
```

Alternatively, you can run the linter from RStudio through Addins -> Lint current file or Addins -> Lint current package.

The configuration file `.lintr` is used to specify the rules that the linter should follow. For compatibility with styler, some linting rules have been disabled.

---

## Styler

To style the code, you need to install `styler`. You can then use one of the following command:

```r
# Style single file
styler::style_file("proxiome_analysis_template.qmd", transformers = pixelatorR::pixelatorR_style())
```

---

## Managing the renv Environment

### Creating a New Environment

To create a new `renv` environment from scratch:

```r
renv::init(bare = TRUE)
```

### Installing Dependencies

```r
# Install BiocManager to enable installation of Bioconductor packages
install.packages("BiocManager")

# Add Bioconductor repos
options(repos = BiocManager::repositories())

# Install yaml to enable parsing of dependencies
install.packages("yaml")

install.packages(
  "duckdb",
  repos = c("https://duckdb.r-universe.dev", "https://cloud.r-project.org")
)

# Locate dependencies
deps <- unique(renv::dependencies()$Package)
gh_deps <- c(pixelatorR = "PixelgenTechnologies/pixelatorR")

deps <- setdiff(deps, names(gh_deps))

# Add missing dependencies
deps <- c(deps, "RcppML", "pls")

# Install dependencies
renv::install(deps)
renv::install(gh_deps)
```

### Creating a Snapshot

After installing or updating packages, create a snapshot to update `renv.lock`:

```r
renv::settings$snapshot.type("all")

renv::snapshot()
```

### Restoring an Environment

To restore an existing `renv` environment from `renv.lock`:

```r  
renv::restore()
```

---

## Setting Up on a Virtual Machine

### Install System Dependencies

Run this in the terminal:

```bash
sudo apt install cmake libglpk-dev libhdf5-dev libfreetype6-dev libpng-dev libtiff5-dev libjpeg-dev libwebp-dev
```

### Restore the renv Environment

```r  
renv::restore()
```
