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
styler::style_file("modules/01_quality_control.qmd", transformers = pixelatorR::pixelatorR_style())

# Style all module files
for (f in list.files("modules", pattern = "\\.qmd$", full.names = TRUE)) {
  styler::style_file(f, transformers = pixelatorR::pixelatorR_style())
}

# Style master document
styler::style_file("proxiome_analysis_template.qmd", transformers = pixelatorR::pixelatorR_style())
```

---

## Smoke-test / example HTML render

Workflow: [`.github/workflows/render-example.yaml`](.github/workflows/render-example.yaml)

**Triggers:** `workflow_dispatch` and `release.published` (independent of the slim-zip workflow).

**What it does:**

1. Frees disk on the GitHub-hosted runner.
2. Downloads the public 1k PBMC `.layout.pxl` files via [`.github/smoke-test/download_dataset.sh`](.github/smoke-test/download_dataset.sh) / [`dataset.yaml`](.github/smoke-test/dataset.yaml) (no Actions cache; re-downloads each run).
3. Pulls `quay.io/pixelgen-technologies/proxiome-analysis-template:latest`.
4. Runs `quarto render proxiome_analysis_template.qmd`.
5. Uploads `proxiome-analysis-template-example-vX.Y.Z-html.zip` as an Actions artifact; on a published Release, also attaches it as a Release asset.

**Dataset config:** Keep [`dataset.yaml`](.github/smoke-test/dataset.yaml) and [`data/metadata.csv`](data/metadata.csv) in sync. When the public dataset is republished:

1. Update each file’s `url`, `path`, and `md5` in `dataset.yaml` (MD5s are listed on the [dataset page](https://software.pixelgen.com/datasets/1k-human-pbmcs-v1.0-proxiome-immuno-155/)).
2. Update `file_path` (and aliases if needed) in `data/metadata.csv`.
3. Keep `condition` values as `resting` / `PHA` so module defaults (`reference_condition`, etc.) still apply.

**Runner notes:** Standard `ubuntu-latest` only guarantees ~14 GB free disk and limited RAM. This job downloads ~8.6 GB of PXLs plus a Docker image; if it fails on disk or OOM, switch `runs-on` to a larger GitHub-hosted runner available to the org.

## Docker Image

The Docker image provides a pre-configured environment for users who prefer not to install R packages locally. It is built from [`Dockerfile`](Dockerfile) on every pull request (build only) and pushed to Quay on merges to `main` and version tags.

**Base image:** `ghcr.io/pixelgentechnologies/pixelatorr:0.18.2`

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
