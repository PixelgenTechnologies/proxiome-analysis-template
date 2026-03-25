# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Updated 

- The PAT is now renderable as an .html file.

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
