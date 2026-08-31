is_absolute_path <- function(path) {
  return(grepl("^(?:[A-Za-z]:[\\\\/]|\\\\\\\\|/)", path))
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
  file_path <- path.expand(trimws(as.character(file_path)))
  if (!nzchar(file_path)) {
    stop("A data file path was empty. Check metadata.csv and data_dir.")
  }

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
      "\nSet `data_dir` in modules/common_setup.R or use a full path in metadata.csv."
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

if (packageVersion("pixelatorR") < "0.18.3") {
  stop(
    "Please update the pixelatorR package to version 0.18.3 or higher to run this analysis workflow."
  )
}

# Global seed for reproducibility. common_setup.R is sourced at the top of every
# module, so setting the seed here makes stochastic steps (UMAP, clustering, PLS,
# etc.) reproducible across runs. 42 matches Seurat's default seed.use. The
# stochastic Seurat calls in module 02 also pass analysis_seed explicitly
# (seed.use / random.seed).
analysis_seed <- 42
set.seed(analysis_seed)

options(
  export_plot.overwrite = TRUE
)
options(export_plot.file_formats = c("png", "pdf"))

min_p_value_threshold <- 1e-300

# Default location for metadata.csv and PXL files (filenames in metadata).
# Override here, or set the PAT_DATA_DIR environment variable.
# Examples:
#   data_dir <- here::here("data")
#   data_dir <- "/mnt/shared/pxl_files"
#   data_dir <- here::here("..", "experiment_data")
data_dir <- here::here("data")
if (nzchar(Sys.getenv("PAT_DATA_DIR"))) {
  data_dir <- path.expand(Sys.getenv("PAT_DATA_DIR"))
}

metadata_path <- tryCatch(
  resolve_data_file("metadata.csv", data_dir),
  error = function(e) {
    stop(
      "metadata.csv not found in ", data_dir, ".\n",
      "Place metadata.csv there, set `data_dir` in modules/common_setup.R, ",
      "or set the PAT_DATA_DIR environment variable."
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
