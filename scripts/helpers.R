#' Create a violin/quasirandom plot with median overlays for PNA object metadata
#'
#' @param data Seurat object containing cell metadata
#' @param var_x String; variable for the x-axis (categorical, e.g., sample/group)
#' @param var_y String; variable for the y-axis (e.g., n_umi, reads_in_component, etc.)
#' @param palette Optional named vector of colors for each level of var_x;
#'   if NULL, a new palette is generated.
#' @param data_cutoff Numeric [0,1]; quantile cutoff for y-axis (e.g. 0.99 drops
#'   top 1% as outliers). If NULL, no cutoff is applied.
#'
#' @return A ggplot object (beeswarm plot with median overlays)
create_violin_plot <- function(
  data, # Seurat object with cell metadata
  var_x, # grouping variable (string) - x axis
  var_y, # value variable (string) - y axis
  palette = NULL, # named vector of colors; names must match unique values of var_x
  data_cutoff = NULL # quantile cutoff (e.g., 0.99 = keep <=99th percentile of var_y)
) {
  # If palette is not provided, auto-generate based on unique values of var_x
  if (is.null(palette)) {
    vars_to_plot <- FetchData(data, c(var_x)) |>
      pull(var_x) |> # extract the grouping variable column
      unique() # get unique values (e.g. sample IDs)
    palette <- set_names(
      pixelatorES::create_sample_palette(
        # generate (enough) distinct colors
        vars_to_plot
      )[seq_len(n_distinct(vars_to_plot))],
      vars_to_plot
    )
  }

  # Determine y-axis upper cutoff (removes extreme outliers if specified)
  if (!is.null(data_cutoff)) {
    cutoff_value <- quantile(
      FetchData(data, var_y) |> pull(var_y),
      data_cutoff
    )
  } else {
    cutoff_value <- 1 # Only show up to 1 unless cutoff specified
  }

  # Construct the plot
  FetchData(data, c(var_x, var_y)) |>
    ggplot(aes(
      !!sym(var_x), # x-axis: group
      !!sym(var_y), # y-axis: measurement
      color = !!sym(var_x) # color by group for scatter
    )) +
    ggbeeswarm::geom_quasirandom() + # beeswarm/jittered scatter plot
    coord_cartesian(ylim = c(0, cutoff_value)) + # y limits, removing outliers if needed
    stat_summary(
      # add median as black diamond
      fun = median,
      geom = "point",
      shape = 23,
      size = 3,
      fill = "black",
      color = "black",
      position = position_dodge(width = 0.75)
    ) +
    stat_summary(
      # annotate median values above points
      fun = median,
      geom = "text",
      aes(label = round(..y.., 1)),
      vjust = -1,
      size = 5,
      color = "black",
      position = position_dodge(width = 0.75)
    ) +
    theme_bw() +
    labs(
      x = var_x,
      y = var_y
    ) +
    scale_color_manual(values = palette) +
    theme(
      legend.position = "bottom",
      axis.text.x = element_text(size = 12, face = "bold"),
      axis.text.y = element_text(size = 12, face = "bold"),
      axis.title.x = element_text(size = 14, face = "bold"),
      axis.title.y = element_text(size = 14, face = "bold")
    )
}

check_metadata_columns <- function(metadata) {
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
}
