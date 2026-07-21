# Developer Guide

This document contains instructions for developers working on the Proxiome Analysis Template.

## Table of Contents

- [Code Style](#code-style)
- [Linting](#linting)
- [Styler](#styler)
- [Docker image and CI](#docker-image-and-ci)
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

## Docker image and CI

The PAT is distributed as a Docker image on Quay. GitHub Actions builds it in [`build-docker-image.yaml`](.github/workflows/build-docker-image.yaml). On a published Release (or a manual workflow run with smoke test enabled), the same job also renders the full Quarto HTML using the image built for that commit.

### Docker image

The Docker image provides a pre-configured environment for users who prefer not to install R packages locally. It is built from [`Dockerfile`](Dockerfile).

**Base image:** `ghcr.io/pixelgentechnologies/pixelatorr:0.18.3`

**Additional installs at build time:** Quarto and the remaining PAT R packages via `pak::pak()`.

**Bundled at `/workspace`:** master QMD, modules, example `metadata.csv`, and project file.

Build locally:

```bash
docker build -t proxiome-analysis-template .
```

On merges to `main` and version tags, the image is pushed to `quay.io/pixelgen-technologies/proxiome-analysis-template`.

### CI workflow

- **Pull requests:** image is built to verify the Dockerfile; nothing is pushed; smoke test is skipped.
- **`main` / version tags:** image is built and pushed to Quay; smoke test is skipped (use a Release or workflow_dispatch to smoke-test).
- **Release / workflow_dispatch (smoke on):** image is built for the commit, used for the HTML smoke test, then pushed to Quay when not a PR.

To smoke-test a branch without publishing: Actions → **Build** → Run workflow → leave “run smoke test” checked → choose the branch.

### HTML smoke test

When the smoke test runs, CI downloads the public 1k PBMC dataset and runs `quarto render proxiome_analysis_template.qmd` in the image from the same build.

**When it runs**

- **Published Release** — always (HTML zip attached to the Release)
- **workflow_dispatch** — when “run smoke test” is enabled (default on)
- **Not** on ordinary `main` pushes or pull requests (too expensive: ~8.6 GB download + long render)

**What it does**

1. Download PXLs via [`.github/smoke-test/download_dataset.sh`](.github/smoke-test/download_dataset.sh) / [`dataset.tsv`](.github/smoke-test/dataset.tsv).
2. Render the master QMD in the built image.
3. Upload `proxiome-analysis-template-example-vX.Y.Z-html.zip` as an Actions artifact (and Release asset on publish).

**Dataset config:** Keep [`dataset.tsv`](.github/smoke-test/dataset.tsv) and [`data/metadata.csv`](data/metadata.csv) in sync. When the public dataset is republished:

1. Update each row’s `url`, `path`, and `md5` in `dataset.tsv` (MD5s are listed on the [dataset page](https://software.pixelgen.com/datasets/1k-human-pbmcs-v1.0-proxiome-immuno-155/)).
2. Update `file_path` (and aliases if needed) in `data/metadata.csv`.
3. Keep `condition` values as `resting` / `PHA` so module defaults (`reference_condition`, etc.) still apply.

**Runner notes:** Standard `ubuntu-latest` only guarantees ~14 GB free disk and limited RAM. If the smoke test fails on disk or OOM, switch `runs-on` to a larger GitHub-hosted runner available to the org.

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
