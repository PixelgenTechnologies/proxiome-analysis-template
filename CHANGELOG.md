# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Added an annotation checkpoint where the user can decide which annotation to use for the downstream analysis.
- Added content to visualize the final cell annotation.

### Updated

- Plots are now overwritten by default.
- Plots are now shown directly in the IDE.
- The reference condition for differential testing is now selected at the beginning of the statistical analysis section.
- Samples should now generally be ordered in plots according to their order in the sample metadata file.

### Fixed
- Fixed bug where `slot` was used instead of `layer`, causing an error.
- `RcppML` and `pls` are now added as dependencies and installed when creating the `renv` environment.
- Fixed issue in isotype fraction violin plot, where the displayed median would be rounded to zero. 
- Typos.

## [0.2.1] 2026-02-26

### Updated

- README file updated with instructions for installing required R packages and preparing input data.
- Rebranded from "SOP" to "Template", e.g. the main analysis `.qmd` was renamed to `proxiome_analysis_template.qmd`.
- Updated `metadata.csv` template file.

## [0.2.0] 2026-02-25

### Updated

- The SOP now uses functions from `pixelatorR` for colors and saving plots.

### Fixed

- Fixed bug in DimRed marker selection that normalized counts per protein instead of per cell.


## [0.1.0] 2025-11-25

### Added

- Initiated repository.
