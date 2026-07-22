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

options(
  export_plot.overwrite = TRUE
)
options(export_plot.file_formats = c("png", "pdf"))

min_p_value_threshold <- 1e-300

metadata_path <- here::here("data", "metadata.csv")
if (!file.exists(metadata_path)) {
  stop(
    "metadata.csv not found in the data/ folder. ",
    "Please create the file and try again."
  )
}
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
