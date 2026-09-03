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

The PAT is distributed as a Docker image on Quay. GitHub Actions builds it in [`build-docker-image.yaml`](.github/workflows/build-docker-image.yaml) as three jobs: **build** → optional **HTML smoke test** → **push to Quay**. On a published Release (or a manual workflow run with smoke test enabled), smoke runs against a Quay `sha-…` staging tag; branch/semver tags are promoted only after smoke passes.

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

Jobs in [`build-docker-image.yaml`](.github/workflows/build-docker-image.yaml):

1. **Build Docker Image** (`ubuntu-latest`) — build the image. On ordinary `main`/tag pushes it publishes all tags to Quay. When smoke will run, it pushes only a `sha-…` staging tag.
2. **HTML smoke test** (`ubuntu-latest`, conditional) — `docker pull` the staging tag, download public PXLs, `quarto render --embed-resources`, upload the self-contained HTML (and attach to the GitHub Release when applicable).
3. **Push image to Quay** (`ubuntu-latest`, smoke path only) — after a successful smoke test, promote the staging image to the publish tag list computed in the build job (passed as a multiline job output) via `docker buildx imagetools create` (registry-side retag, no image tarball).

Behavior by event:

- **Pull requests:** image is built to verify the Dockerfile; nothing is pushed; smoke test is skipped.
- **`main` / version tags:** image is built and pushed to Quay in the build job; smoke test is skipped (use a Release or workflow_dispatch to smoke-test).
- **Release / workflow_dispatch (smoke on):** staging `sha-…` tag is pushed, smoke-tested, then promoted to publish tags.

To smoke-test a branch: Actions → **Build** → Run workflow → leave “run smoke test” checked → choose the branch.

### HTML smoke test

When the smoke test runs, CI downloads donors 1 and 3 from the public [16 healthy donors](https://software.pixelgen.com/datasets/PBMC-16-healthy-donors-v2.0-proxiome-immuno-155/) dataset (~7.1 GiB) and runs `quarto render proxiome_analysis_template.qmd --embed-resources` in the image from the same build (single self-contained HTML file).

**When it runs**

- **Published Release** — always (self-contained HTML attached to the Release)
- **workflow_dispatch** — when “run smoke test” is enabled (default on)
- **Not** on ordinary `main` pushes or pull requests (too expensive: ~7.1 GiB download + long render)

**What it does**

1. Download PXLs via [`.github/smoke-test/download_dataset.sh`](.github/smoke-test/download_dataset.sh) / [`dataset.tsv`](.github/smoke-test/dataset.tsv).
2. Render the master QMD in the built image with `--embed-resources`.
3. Upload the self-contained HTML as an Actions artifact named `proxiome-analysis-template-example`. On Release, attach `proxiome-analysis-template-example.html` to the GitHub Release (stable filename for `releases/latest/download/...`).

### Optional limma pseudobulk smoke

The default example has one `sample_alias` per `condition`, so limma pseudobulk is skipped (`run_pseudobulk <- FALSE`). To exercise §§5.4–5.7 without changing the Release HTML path:

1. Actions → **Build** → Run workflow → enable **run smoke test** and **run pseudobulk smoke**.
2. After the full HTML render, CI runs [`.github/smoke-test/smoke_pseudobulk.R`](.github/smoke-test/smoke_pseudobulk.R) (technical `rep1`/`rep2` split + downsample of the annotated checkpoint), then `quarto render modules/05_statistical_testing.qmd` with `PAT_SMOKE_PSEUDOBULK=1`. That env var is handled by [`.github/smoke-test/apply_module05_overrides.R`](.github/smoke-test/apply_module05_overrides.R) (sourced from module `05` setup): it turns on `run_pseudobulk` and turns off `run_cell_level` so Wilcoxon chunks are skipped.
3. Asserts that `results/05_statistical_testing/{abundance,clustering,colocalization}/pseudobulk/*.rds` exist.

Release publishes and ordinary smoke (flag off) are unchanged. Locally, after modules 01–02:

```bash
PAT_SMOKE_PSEUDOBULK=1 Rscript .github/smoke-test/smoke_pseudobulk.R
PAT_SMOKE_PSEUDOBULK=1 quarto render modules/05_statistical_testing.qmd
```

**Dataset config:** Keep [`dataset.tsv`](.github/smoke-test/dataset.tsv) and [`data/metadata.csv`](data/metadata.csv) in sync. When the public dataset is republished:

1. Update each row’s `url`, `path`, and `md5` in `dataset.tsv` (MD5s are listed on the [dataset page](https://software.pixelgen.com/datasets/PBMC-16-healthy-donors-v2.0-proxiome-immuno-155/)).
2. Update `file_path` (and aliases if needed) in `data/metadata.csv`.
3. Keep `condition` values in sync with module `05` `reference_condition` (example uses `donor1` / `donor3` because both samples are resting).

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
  "clusterProfiler", "org.Hs.eg.db", "AnnotationDbi", "limma",
  "PixelgenTechnologies/pixelatorR"
))
```

