load_pat_common <- function() {
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
 
  # Set global options for saving plots
  options(
    # Overwrite existing files when saving plots - set to FALSE if you want to keep old versions of the plots
    export_plot.overwrite = TRUE
  )
  # Set global options for file formats to save plots in both PNG and PDF
  options(export_plot.file_formats = c("png", "pdf"))
 
  # Minimum p-value to use in -log10 transformations for volcano plots.
  # When p_val_adj == 0 (floating-point underflow), -log10(0) becomes Inf and
  # data-point labels are clipped. Coerce any p-value below this threshold to
  # this value before computing -log10.
  min_p_value_threshold <<- 1e-300
 
  metadata_path <- here::here("data", "metadata.csv")
  if (!file.exists(metadata_path)) {
    stop(
      "metadata.csv not found in the data/ folder. ",
      "Please create the file and try again."
    )
  }
  metadata_raw <- readLines(metadata_path, n = 1)
  metadata_sep <- if (grepl(";", metadata_raw)) ";" else ","
  metadata <<- read.csv(metadata_path, sep = metadata_sep) |> as_tibble()
 
  # Theme/palettes (used across modules)
  cluster_palette <<-
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
 
  # Create palettes based on metadata ordering
  unique_conditions <- unique(metadata$condition)
  condition_palette <<-
    set_names(
      create_discrete_palette(unique_conditions)[seq_along(unique_conditions)],
      unique_conditions
    )
 
  unique_samples <- unique(metadata$sample_alias)
  sample_palette <<-
    set_names(
      create_discrete_palette(unique_samples)[seq_along(unique_samples)],
      unique_samples
    )
 
  gradient_palette <<-
    colorRampPalette(
      c("#FFFFFF", "#F1EEE9", "#F0D7E0", "#E3A6B8", "#CB6E8B", "#A23F5E", "#781534")
    )(100)
 
  # Helper function to format large numbers compactly (e.g., 11234 -> "11.2k")
  format_thousands <<- function(x) {
    ifelse(
      abs(x) >= 1000,
      paste0(round(x / 1000, 1), "k"),
      as.character(round(x, 1))
    )
  }
 
  invisible(TRUE)
}

