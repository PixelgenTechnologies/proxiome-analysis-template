# User settings (edit these for your project)
#
# Default location for metadata.csv and PXL files (filenames in metadata).
# Override this if your files live elsewhere. Examples:
#   data_dir <- here::here("data")
#   data_dir <- "/mnt/shared/pxl_files"
#   data_dir <- here::here("..", "experiment_data")
data_dir <- here::here("data")

# Global seed for reproducibility. common_setup.R is sourced at the top of every
# module, so setting the seed here makes stochastic steps (UMAP, clustering, PLS,
# etc.) reproducible across runs. 42 matches Seurat's default seed.use. The
# stochastic Seurat calls in module 02 also pass analysis_seed explicitly
# (seed.use / random.seed).
analysis_seed <- 42
set.seed(analysis_seed)

is_absolute_path <- function(path) {
  return(
    startsWith(path, "/") ||
      startsWith(path, "\\\\") ||
      grepl("^[A-Za-z]:[/\\\\]", path)
  )
}

#' Resolve a data file from a filename, relative path, or absolute path.
#'
#' Filenames are looked up in `data_dir`. Absolute paths (and `~` paths) are
#' used as given. Relative paths that already exist from the working directory
#' are accepted so `data/file.pxl`-style values still work.
#'
#' @param file_path Character path from metadata or configuration.
#' @param data_dir Directory used when `file_path` is a filename or relative path.
#' @return Normalized absolute path to an existing file.
#' @noRd
resolve_data_file <- function(file_path, data_dir) {
  if (
    length(file_path) != 1L ||
      is.na(file_path) ||
      !nzchar(trimws(as.character(file_path)))
  ) {
    stop(
      "A data file path was missing or empty. Check metadata.csv and data_dir."
    )
  }
  file_path <- path.expand(trimws(as.character(file_path)))

  candidates <- if (is_absolute_path(file_path)) {
    file_path
  } else {
    unique(c(
      file.path(data_dir, file_path),
      file_path,
      if (requireNamespace("here", quietly = TRUE)) {
        here::here(file_path)
      }
    ))
  }

  found <- candidates[file.exists(candidates)]
  if (length(found) == 0L) {
    stop(
      "Could not find file: ", file_path, "\n",
      "Looked in:\n",
      paste0("  - ", candidates, collapse = "\n"),
      "\nSet `data_dir` at the top of modules/common_setup.R or use a full path in metadata.csv."
    )
  }

  return(normalizePath(found[[1L]], winslash = "/", mustWork = TRUE))
}

save_checkpoint <- function(name, object) {
  dir.create(
    here::here("results", "checkpoint_data"),
    recursive = TRUE,
    showWarnings = FALSE
  )
  saveRDS(object, here::here("results", "checkpoint_data", name))
}

load_checkpoint <- function(name, required = TRUE) {
  path <- here::here("results", "checkpoint_data", name)
  if (!file.exists(path)) {
    if (required) {
      stop(
        "Checkpoint not found: ", path, "\n",
        "Run the upstream module first to create it."
      )
    }
    return(NULL)
  }
  readRDS(path)
}

#' Load a module `03` statistical testing results table, if it exists
#'
#' Module `03` (statistical testing) now runs before modules `04` (abundance)
#' and `05` (proximity), so both can optionally check their plotted markers
#' against module `03` results. Module `03` remains independent otherwise
#' (its outputs are plain `.rds` files under `results/03_statistical_testing/`,
#' not a `results/checkpoint_data/` checkpoint), so this returns `NULL`
#' instead of erroring when module `03` has not been run yet.
#'
#' @param relative_path Path to the `.rds` file, relative to the project root
#'   (e.g. `"results/03_statistical_testing/abundance/differential_abundance_analysis.rds"`).
#' @return The deserialized object, or `NULL` if the file does not exist.
#' @noRd
load_statistical_testing_results <- function(relative_path) {
  path <- here::here(relative_path)
  if (!file.exists(path)) {
    return(NULL)
  }
  return(readRDS(path))
}

#' Warn when none of the plotted markers were significant in module `03`
#'
#' Modules `04` (abundance) and `05` (proximity) plot every marker the user
#' selected, regardless of whether module `03` (statistical testing) found it
#' significant - no outputs are suppressed. This helper adds a safety net on
#' top of that: for each cell type / comparison combination in a module `03`
#' results table, it checks whether at least one of the currently selected
#' markers was significant, and raises a `warning()` for every combination
#' where none were. This flags likely-uninformative plots instead of letting
#' them pass silently.
#'
#' @param stats_results A module `03` results tibble (e.g.
#'   `differential_abundance_analysis`), with a `group` column (cell type),
#'   optionally a `target` column (comparison), a `p_adj` column, and one or
#'   more marker identifier columns. `NULL` (module `03` not yet run) is
#'   allowed and simply skips the check.
#' @param marker_cols Character vector naming the marker identifier column(s)
#'   in `stats_results`, e.g. `"marker"` or `c("marker_1", "marker_2")`.
#' @param selected_markers Character vector of markers that will actually be
#'   plotted in the current section.
#' @param p_adj_threshold Significance cutoff applied to `p_adj`. Default `0.05`.
#' @param analysis_label Short, human-readable label for the statistical test
#'   used in the warning message, e.g. `"differential abundance"`.
#' @return Invisibly, a tibble with one row per flagged cell type / comparison
#'   combination (empty if none were flagged).
#' @noRd
warn_if_no_significant_markers <- function(stats_results,
                                            marker_cols,
                                            selected_markers,
                                            p_adj_threshold = 0.05,
                                            analysis_label = "statistical testing") {
  if (is.null(stats_results) || nrow(stats_results) == 0 || length(selected_markers) == 0) {
    return(invisible(tibble()))
  }

  grouping_cols <- intersect(c("group", "target"), colnames(stats_results))
  if (length(grouping_cols) == 0) {
    return(invisible(tibble()))
  }

  marker_selected <- Reduce(
    `|`,
    lapply(marker_cols, function(col) stats_results[[col]] %in% selected_markers)
  )

  flagged <-
    stats_results |>
    mutate(marker_selected = marker_selected) |>
    group_by(across(all_of(grouping_cols))) |>
    summarise(
      any_significant = any(marker_selected & p_adj < p_adj_threshold, na.rm = TRUE),
      .groups = "drop"
    ) |>
    filter(!any_significant) |>
    select(-any_significant)

  if (nrow(flagged) > 0) {
    pwalk(flagged, function(...) {
      combo <- list(...)
      combo_label <- paste(
        paste(names(combo), unlist(combo), sep = " = "),
        collapse = ", "
      )
      warning(
        glue::glue(
          "None of the markers selected for plotting reached significance ",
          "(p_adj < {p_adj_threshold}) in the module `03` {analysis_label} results ",
          "for {combo_label}. The plot below is still generated from all selected ",
          "markers, but it may not show any significant findings."
        ),
        call. = FALSE
      )
    })
  }

  return(invisible(flagged))
}

suppressPackageStartupMessages({
  library(tidyverse)
  library(Seurat)
  library(pixelatorR)
  library(harmony)
  library(ComplexHeatmap)
  library(ggplotify)
  library(here)
  library(Matrix)
  library(ggraph)
})

if (packageVersion("pixelatorR") < "0.23.0") {
  stop(
    "Please update the pixelatorR package to version 0.23.0 or higher to run this analysis workflow."
  )
}

options(
  export_plot.overwrite = TRUE
)
options(export_plot.file_formats = c("png", "pdf"))

min_p_value_threshold <- 1e-300

metadata_path <- tryCatch(
  resolve_data_file("metadata.csv", data_dir),
  error = function(e) {
    stop(
      "metadata.csv not found in ", data_dir, ".\n",
      "Place metadata.csv there, or set `data_dir` at the top of modules/common_setup.R."
    )
  }
)
metadata_raw <- readLines(metadata_path, n = 1)
metadata_sep <- if (grepl(";", metadata_raw)) ";" else ","
metadata <- read.csv(metadata_path, sep = metadata_sep) |> as_tibble()

if (
  !all(
    c("sample_id", "sample_alias", "file_path", "condition") %in%
      colnames(metadata)
  )
) {
  stop(
    "Metadata file must contain the columns: sample_id, sample_alias, file_path and condition"
  )
}

cluster_palette <-
  c(
    pixelatorR::PixelgenAccentColors(
      level = 7,
      hue = c(
        "blues",
        "reds",
        "cyans",
        "oranges",
        "pinks",
        "greens",
        "purples",
        "yellows",
        "greys",
        "beiges"
      )
    ),
    pixelatorR::PixelgenAccentColors(
      level = 9,
      hue = c(
        "blues",
        "pinks",
        "reds",
        "yellows",
        "greys",
        "beiges"
      )
    ),
    pixelatorR::PixelgenAccentColors(
      level = 5,
      hue = c(
        "purples",
        "blues",
        "cyans",
        "greens",
        "reds",
        "oranges"
      )
    ),
    pixelatorR::PixelgenAccentColors(
      level = 3,
      hue = c("blues", "reds")
    ),
    pixelatorR::PixelgenAccentColors(
      level = 12,
      hue = c("blues", "reds")
    )
  ) |>
  unname() |>
  rep(10)

unique_conditions <- unique(metadata$condition)
condition_palette <-
  set_names(
    create_discrete_palette(unique_conditions)[seq_along(unique_conditions)],
    unique_conditions
  )

unique_samples <- unique(metadata$sample_alias)
sample_palette <-
  set_names(
    create_discrete_palette(unique_samples)[seq_along(unique_samples)],
    unique_samples
  )

cell_palette <- Pixelgen_cell_palette

gradient_palette <-
  c(
    "#1F395F",
    "#44628E",
    "#718BB2",
    "#A8B9D1",
    "#DBE1EA",
    "#F1EEE9",
    "#F0D7E0",
    "#E3A6B8",
    "#CB6E8B",
    "#A23F5E",
    "#781534"
  )

format_thousands <- function(x) {
  ifelse(
    abs(x) >= 1000,
    paste0(round(x / 1000, 1), "k"),
    as.character(round(x, 1))
  )
}
