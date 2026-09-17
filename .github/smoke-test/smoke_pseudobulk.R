#!/usr/bin/env Rscript
# Prepare checkpoints for an optional limma-pseudobulk smoke after the HTML smoke.
#
# The bundled example has one sample_alias per condition, so limma cannot run.
# This script splits each sample into two technical replicates (rep1/rep2),
# optionally downsamples, and trims markers_to_test for speed. It is not a
# biological design — only plumbing coverage for §§5.4–5.7.
#
# Usage (from repo root, after modules 01–02 checkpoints exist):
#   PAT_SMOKE_PSEUDOBULK=1 Rscript .github/smoke-test/smoke_pseudobulk.R
#   PAT_SMOKE_PSEUDOBULK=1 quarto render modules/05_statistical_testing.qmd
# (module 05 sources apply_module05_overrides.R to enable limma / skip Wilcoxon)

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg) > 0) {
  normalizePath(sub("^--file=", "", file_arg[[1]]))
} else {
  normalizePath(".github/smoke-test/smoke_pseudobulk.R")
}
root <- normalizePath(file.path(dirname(script_path), "..", ".."))
setwd(root)

suppressPackageStartupMessages({
  library(here)
})
here::i_am(".github/smoke-test/smoke_pseudobulk.R")
source(here::here("modules", "common_setup.R"))

max_cells <- as.integer(Sys.getenv("PAT_SMOKE_PSEUDOBULK_MAX_CELLS", "80"))
max_markers <- as.integer(Sys.getenv("PAT_SMOKE_PSEUDOBULK_MAX_MARKERS", "12"))
if (is.na(max_cells) || max_cells < 10L) {
  stop("PAT_SMOKE_PSEUDOBULK_MAX_CELLS must be an integer >= 10")
}
if (is.na(max_markers) || max_markers < 2L) {
  stop("PAT_SMOKE_PSEUDOBULK_MAX_MARKERS must be an integer >= 2")
}

pg_data <- load_checkpoint("annotated_seurat_object.rds")
markers_to_test <- load_checkpoint("markers_to_test.rds")

set.seed(42)
# Cell-level metadata (sample_alias, condition, …) from the Seurat object
meta <- pg_data[[]] |>
  as_tibble(rownames = "component") |>
  group_by(sample_alias, condition) |>
  mutate(
    .rep = sample(rep(c("rep1", "rep2"), length.out = n())),
    sample_alias = paste(as.character(sample_alias), .rep, sep = "_"),
    sample_id = paste(as.character(sample_id), .rep, sep = "_")
  ) |>
  ungroup() |>
  select(-.rep)

# Per-group downsample: slice_sample(n = ...) needs a scalar, so don't call n() there
meta_small <- meta |>
  group_by(sample_alias) |>
  mutate(.rid = sample.int(n())) |>
  filter(.rid <= max_cells) |>
  select(-.rid) |>
  ungroup()

pg_data <- subset(pg_data, cells = meta_small$component)
idx <- match(colnames(pg_data), meta_small$component)
pg_data$sample_alias <- meta_small$sample_alias[idx]
pg_data$sample_id <- meta_small$sample_id[idx]

rep_check <- meta_small |>
  distinct(sample_alias, condition) |>
  count(condition, name = "n_samples")
message("Technical-replicate sample counts per condition:")
print(rep_check)
if (!all(rep_check$n_samples >= 2L)) {
  stop("Failed to create ≥2 sample_alias values per condition")
}

markers_to_test <- lapply(markers_to_test, function(m) {
  head(as.character(m), max_markers)
})
# Drop cell types with too few markers after trimming
markers_to_test <- markers_to_test[lengths(markers_to_test) >= 2L]
if (length(markers_to_test) == 0L) {
  stop("No cell types left in markers_to_test after trimming")
}

# Keep only annotated cells that belong to retained cell types (faster proximity)
keep_types <- names(markers_to_test)
pg_data <- subset(pg_data, cell_annotation %in% keep_types)

save_checkpoint("annotated_seurat_object.rds", pg_data)
save_checkpoint("markers_to_test.rds", markers_to_test)

message(
  "Wrote smoke checkpoints: ",
  ncol(pg_data), " cells, ",
  length(markers_to_test), " cell types, ",
  "max ", max_markers, " markers/type, ",
  "max ", max_cells, " cells/sample_alias"
)
message("Next: PAT_SMOKE_PSEUDOBULK=1 quarto render modules/05_statistical_testing.qmd")
