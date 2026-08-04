# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unpublished

### Changed

- Module 07 UniProt mapping for ORA now keeps only the first UniProt ID per marker.

## [0.6.2] 2026-07-31

### Added

- `sessionInfo()` at the end of the master `proxiome_analysis_template.qmd`, so the fully rendered report includes the R session details it was generated with.

### Changed

- Global seed set in `common_setup.R`, applied consistently at the start of every module; clustering functions in `02_clustering_annotation.qmd` (including `FindClusters`) now use the same seed.

## [0.6.1] 2026-07-30

### Fixed

- Bug in `statistical_testing_differential_colocalization_plot` that would throw an error if there were less than 2 significant markers between conditions for a cell type. Now plotting is skipped in these cases.

## [0.6.0] 2026-07-30

### Added

- Optional module `07_data_interpretation.qmd` (scaffold): registered in the master QMD for upcoming enrichment / interpretation work after module `05`.
- Module 07 GO Biological Process enrichment via `clusterProfiler::enricher` (panel UniProt universe); Docker/README deps include `clusterProfiler`, `org.Hs.eg.db`, and `AnnotationDbi`.
- Module 07 enrichment plots: term overview bars and term × marker point maps (effect size / significance); saves `term_marker_hits.csv`.

### Changed

- Example / smoke-test data switched from the 1k PBMC resting/PHA pair to donors 1 and 3 from [Resting PBMCs from 16 healthy donors](https://software.pixelgen.com/datasets/PBMC-16-healthy-donors-v2.0-proxiome-immuno-155/) (UniProt-bearing Proxiome Immuno 155 v2 panel). `condition` is `donor1` / `donor3`; module `05` `reference_condition` defaults to `"donor1"`.
- HTML smoke-test release asset is now a self-contained `proxiome-analysis-template-example.html` (no zip, no version in the filename) for a stable `releases/latest/download/...` URL.

## [0.5.2] 2026-07-21

### Added

- HTML smoke test in the **Build** workflow: after building the image for the current commit, optionally downloads the public 1k PBMC dataset and renders the full PAT to HTML (on Release and `workflow_dispatch`). Build, smoke test, and Quay push are separate jobs; smoke pulls a Quay `sha-…` staging tag (promoted after smoke passes).
- [.github/smoke-test/download_dataset.sh](.github/smoke-test/download_dataset.sh) + [dataset.tsv](.github/smoke-test/dataset.tsv) for fetch + MD5 verify.



### Changed

- Example `data/metadata.csv` now matches the public [1k Human PBMCs](https://software.pixelgen.com/datasets/1k-human-pbmcs-v1.0-proxiome-immuno-155/) dataset (2 samples: `resting` / `PHA`).
- Quarto HTML output uses the `cosmo` theme with a left TOC and code-copy buttons for a more tutorial-like look.
- Docker base image bumped to `pixelatorr:0.18.3`.



### Fixed

- Bug in `statistical_testing_marker_selection` where the `isotype_pls` would throw an error if there is only a single sample containing a certain cell type.



## [0.5.1] 2026-07-20



### Added

- The PAT is now automatically released as a .zip artifact on GitHub upon release for users who want to download the minimal file set to run the template.



## [0.5.0] 2026-06-24



### Added

- Module `06_cell_visualization.qmd` (optional): single-cell graph visualization for one cell type and a set of markers, using pixelatorR's `Plot2DGraphM` (2D marker × cell grid) and `Plot3DGraph` (interactive 3D). Example uses CD8 T cells with the CD82/CD81 colocalization pair. Requires `pixelatorR > 0.18.2` (adds `cpmds_3d` support to `Plot2DGraphM`); on `pixelatorR ≤ 0.18.2`, set the 2D plot's `layout_method` to a supported value instead (`wpmds_3d`, `pmds_3d`, `wpmds`, or `pmds`).



## [0.4.0] 2026-06-02



### Removed

- `qc_thresholds.rds` checkpoint — QC thresholds are applied in module `01` before saving `pg_data_merged.rds`.
- `renv` project environment (`renv.lock`, `renv/`, `.Rprofile`). Local install uses `pak::pak()`; reproducibility is provided by the Docker image.
- Module `00_project_setup.qmd` — data loading is now the first section of module `01`.



### Added

- Modular analysis workflow: numbered notebooks in `modules/` (`01`–`05`) for interactive, stage-by-stage analysis.
- Thin master `proxiome_analysis_template.qmd` that includes all modules for full re-render.
- `[modules/common_setup.R](modules/common_setup.R)`: shared packages, metadata, palettes, and checkpoint helpers.
- Checkpoint files in `results/checkpoint_data/` for all cross-module state (`pg_data_merged`, `selected_markers`, `annotated_seurat_object`, `markers_to_test`).



### Updated

- Cell QC filtering moved from module `02` to module `01` (section 1.3.5); `pg_data_merged.rds` now contains filtered cells only.
- Simplified `common_setup.R`: removed `load_pat_common()`, `pat_results()`, and `checkpoint_path()`; setup runs on `source()` and checkpoints use `here::here("results", "checkpoint_data", ...)` directly.
- Results subfolders renamed to match module names: `02_clustering_annotation`, `04_proximity` (replacing `02_data_processing`, `04_raw_proximity`).
- Module `01` now loads PXL data, runs QC, filters cells, and saves the filtered object; modules `02`–`05` load required checkpoints automatically.
- Docker image: installs PAT dependencies via `pak::pak()` on top of `pixelatorr:0.17.1` instead of `renv::restore()`; bundles full template at `/workspace`.
- Docker CI: builds on pull requests (verify only); pushes to Quay on `main` and version tags only.
- README: workflow paths, checkpoint table, Docker as advanced install option.
- The PAT now depends on `pixelatorR >= 0.17.1`.
- The PAT now includes clear labels for decision checkpoints.



### Fixed

- `isotype_pls` is now using the "data" layer to avoid issues when markers are missing from the "scale.data" layer.
- Removed incorrect reference to non-existent `scripts/helpers.R`; helpers remain inline in `common_setup.R`.
- Cold-start for modules `03`–`05`: `cell_palette` and `markers_to_test` now available via shared setup and checkpoints.
- Marker UMAP plots in module `02` now save to project-root `results/` (fixed missing `here::here()` when running the module interactively).



## [0.3.2] 2026-03-27



### Added

- README: Link to the [Getting Started with R guide](https://rstudio-education.github.io/hopr/starting.html) for new R users.
- README: Rtools installation instructions for Windows users (required for compiling R packages from source).
- README: New "Working Directory and Project File" section emphasising that users should always open the project by double-clicking `proxiome_analysis_template.Rproj`.
- README: `proxiome_analysis_template.Rproj` added to the folder structure diagram.
- README: Note that the row order of `metadata.csv` controls the order samples appear in plots.
- README: Note that both comma-separated (`,`) and semicolon-separated (`;`) CSV files are supported for `metadata.csv`.
- README: [GitHub Desktop](https://desktop.github.com/download/) download option in Quick Start (Option 2, no command line needed).
- README: Advanced Quick Start options (GitHub Template, Git clone, QMD-only) moved into collapsible `<details>` dropdowns.
- README: Advanced package installation options (Docker, renv) moved into collapsible `<details>` dropdowns.
- README: File-not-found troubleshooting entry.
- README: Maintainers section listing authors and contact details.
- README: Badges for R version, Quarto, and license in header.
- README: Table of contents with emoji section markers.
- QMD: Auto-detection of CSV separator (comma or semicolon) when reading `metadata.csv`.
- QMD: User-friendly file-existence check for `metadata.csv` with a clear error message.



### Updated

- README: Complete UX redesign for better approachability — cleaner layout, more whitespace, consolidated sections, and better visual hierarchy.
- README: Quick Start restructured so that Download ZIP is the recommended beginner option (Option 1) and advanced options are clearly labelled.
- README: Manual package installation is now the recommended install path; renv and Docker demoted to "Advanced" with collapsible sections.
- README: `harmony` and `ggbeeswarm` added to the manual package installation list with inline comments indicating which sections use them.
- README: Metadata example updated to match the actual `data/metadata.csv` column order and values.
- README: "QC thresholds (Section 1)" corrected to "Section 1.3.1" with threshold variable names listed in a sub-list.
- README: Running the Analysis section now starts with opening the `.Rproj` file, includes keyboard shortcuts for running individual chunks, and provides clearer marker selection guidance.
- README: Troubleshooting section updated to remove renv-centric advice and provide per-OS package compilation guidance.
- README: Key checkpoints and metadata columns now displayed as clean tables.



### Fixed

- Fixed a bug in `lintr` installation in CI.



## [0.3.1] 2026-03-25



### Added

- Comprehensive README with step-by-step getting started guide
- Multiple installation paths: GitHub template, clone, or direct QMD download
- Detailed prerequisites section covering R, RStudio/VS Code, and Quarto installation
- Clear instructions for using renv to restore the package environment
- Troubleshooting section with expandable solutions for common issues
- Quick reference table for metadata file columns



### Updated

- The PAT is now renderable as an .html file.
- Clarified that `file_path` in metadata should be filename only, not full path
- Improved folder structure documentation with clearer explanations



### Fixed

- The `duckdb` installation should now work with `renv::restore()`



## [0.3.0] 2026-03-20



### Added

- Added an annotation checkpoint where the user can decide which annotation to use for the downstream analysis.
- Added content to visualize the final cell annotation.
- Added a cell annotation assignment matrix that can be used to assess the results of automatic annotation per cluster.
- Added new gradient palette. 
- Added `min_p_value_threshold` global variable to floor p-values before `-log10()` transforms in volcano plots, preventing `Inf` values when `p_adj == 0`.
- Added instructional text in Section 1.4 explaining how to customize the marker selection, and a `print(selected_markers)` statement to display selected markers in the IDE.
- Added `heatmap_grouping_column` variable (default: `"condition"`) to control whether colocalization heatmaps (Sections 4.1.1 and 4.1.2) are summarized per condition or per sample; set to `"sample_alias"` to restore the previous per-sample behavior.
- Added `max_heatmap_markers` (default: `60`) variable to limit colocalization heatmaps to the top most abundant proteins when many markers are present.
- Added `markers_for_abundance_plots` variable to restrict marker-wise abundance distribution plots to a user-defined subset (default: first 20 markers); users should replace this with their markers of interest.
- Added `abundance_plots_grouping_column` variable (default: `"condition"`) to control whether per-cell-type abundance plots are faceted by condition or by sample; set to `"sample_alias"` to facet by individual sample.
- Added `network_grouping_column` variable (default: `"condition"`) to control whether colocalization network plots (Section 4.2) are faceted by condition or by sample; set to `"sample_alias"` for per-sample faceting.



### Updated

- Plots are now overwritten by default.
- Plots are now shown directly in the IDE.
- The reference condition for differential testing is now selected at the beginning of the statistical analysis section.
- Samples should now generally be ordered in plots according to their order in the sample metadata file.
- Updated some text in the PAT to be short and concise. 
- The differential colocalization heatmap now only shows differentially colocalized proteins instead of all pairs.
- QC section violin plots: replaced `geom_quasirandom()` with `geom_violin()` for better handling of large datasets; switched to condition-based fill coloring; reduced plot dimensions from 10×8 to 7×5.
- QC annotated molecule rank plot: changed from `theme_minimal(base_size = 18)` to `theme_bw()`.
- UMAP/PCA plots: reduced point size to 0.5 and removed grid lines.
- `data_processing_differential_abundance_markers_per_cluster` plot: increased dimensions from 10×4 to 14×5.
- `differential_abundance_heatmap` and `differential_clustering_heatmap`: transposed to landscape orientation with improved dimension heuristics.
- Moved `data_processing_marker_abundance_per_cluster` and `data_processing_mean_marker_abundance_per_cluster_heatmap` to the `cluster_specific_markers/` subfolder.
- Unified volcano plot styling across sections with consistent gradient colors, reference lines, grid removal, and point sizing.
- Colocalization heatmap color scale is now capped to `c(-1, 1)` for more consistent and readable visualizations.
- Section 4.1.1 (`colocalization_raw_heatmap_per_sample`) now groups heatmaps by `heatmap_grouping_column` (default: condition) instead of always grouping by sample; the combined output file is named `all_{heatmap_grouping_column}s_combined_raw_colocalization_heatmap`.
- Per-cell-type colocalization heatmaps (Section 4.1.2) likewise group by `heatmap_grouping_column`.
- Abundance distribution plots (Section 3) now only plot a user-defined subset of markers and facet "per cell type" plots by `abundance_plots_grouping_column` (default: condition) rather than always by sample.
- Colocalization network plots (Section 4.2) now facet by `network_grouping_column` (default: condition) instead of always faceting by sample.



### Fixed

- Fixed bug where `slot` was used instead of `layer`, causing an error.
- `RcppML` and `pls` are now added as dependencies and installed when creating the `renv` environment.
- Fixed issue in isotype fraction violin plot, where the displayed median would be rounded to zero. 
- Typos.
- Fixed hardcoded reference sample (`"S1_resting"`) in Section 4.1.1 reference heatmap; it now automatically uses the first group in the data.



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

