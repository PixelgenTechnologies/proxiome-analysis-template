# Developer Guide

This document contains instructions for developers working on the Proxiome Analysis Template.

## Table of Contents

- [Code Style](#code-style)
- [Linting](#linting)
- [Styler](#styler)
- [Docker Image](#docker-image)
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
styler::style_file("modules/00_project_setup.qmd", transformers = pixelatorR::pixelatorR_style())

# Style all module files
for (f in list.files("modules", pattern = "\\.qmd$", full.names = TRUE)) {
  styler::style_file(f, transformers = pixelatorR::pixelatorR_style())
}

# Style master document
styler::style_file("proxiome_analysis_template.qmd", transformers = pixelatorR::pixelatorR_style())
```

---

## Docker Image

The Docker image provides a pre-configured environment for users who prefer not to install R packages locally. It is built from [`Dockerfile`](Dockerfile) on every pull request (build only) and pushed to Quay on merges to `main` and version tags.

**Base image:** `ghcr.io/pixelgentechnologies/pixelatorr:0.17.1` (includes `pixelatorR`)

**Additional installs at build time:** Quarto and the remaining PAT R packages via `pak::pak()`.

**Bundled at `/workspace`:** master QMD, modules, example `metadata.csv`, and project file.

### Build locally

```bash
docker build -t proxiome-analysis-template .
```

### CI workflow

- **Pull requests:** image is built to verify the Dockerfile; nothing is pushed.
- **`main` / version tags / releases:** image is built and pushed to `quay.io/pixelgen-technologies/proxiome-analysis-template`.

---

## Setting Up on a Virtual Machine

### Install System Dependencies

Run this in the terminal:

```bash
sudo apt install cmake libglpk-dev libhdf5-dev libfreetype6-dev libpng-dev libtiff5-dev libjpeg-dev libwebp-dev
```

### Install R Packages

Use the same `pak::pak()` commands documented in the README.

```r
install.packages("pak")
pak::pak(c(
  "tidyverse", "Seurat", "here", "Matrix", "ggraph", "pls",
  "ggplotify", "harmony", "ggbeeswarm", "RcppML", "ComplexHeatmap",
  "PixelgenTechnologies/pixelatorR"
))
```
