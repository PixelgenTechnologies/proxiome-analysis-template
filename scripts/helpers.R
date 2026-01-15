#' Check the presence of required columns in metadata
#'
#' This function checks whether a metadata data.frame or tibble contains
#' the required columns: "sample_id", "sample_alias", "file_path", and "condition".
#' If any of these columns are missing, the function stops execution and
#' returns an informative error message.
#'
#' @param metadata A data.frame or tibble containing metadata for samples.
#'
#' @return Invisible NULL. Stops with error if required columns are missing.
#' @examples
#' # Example usage:
#' metadata <- data.frame(
#'   sample_id = 1:3,
#'   sample_alias = c("A", "B", "C"),
#'   file_path = c("file1", "file2", "file3"),
#'   condition = c("control", "case", "case")
#' )
#' check_metadata_columns(metadata) # No error
#'
#' # Example with missing column
#' bad_metadata <- metadata[, -1]
#' \dontrun{
#'   check_metadata_columns(bad_metadata) # This will throw an error
#' }
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

#' Save Plot Helper Function
#'
#' Saves a ggplot2 plot to one or more file formats with options for size and directory creation.
#'
#' @param filename Character. The path and base filename (without extension) for saving the plot.
#' @param plot ggplot object. The plot to save. Defaults to the last plot produced (`last_plot()`).
#' @param width Numeric. The width of the plot in inches. Default is 10.
#' @param height Numeric. The height of the plot in inches. Default is 10.
#' @param create_dir Logical. Whether to create the directory if it does not exist. Default is TRUE.
#' @param file_formats Character vector. File formats to save to (e.g., "png", "pdf"). Default is c("png", "pdf").
#'
#' @return Invisibly returns NULL. Used for its side effect of writing plot files.
#' @examples
#' \dontrun{
#'   save_plot("results/myplot", plot = myplot, width = 8, height = 6)
#' }
save_plot <-
  function(
    filename,
    plot = last_plot(),
    width = 10,
    height = 10,
    create_dir = TRUE,
    file_formats = c("png", "pdf")
  ) {
    for (format in file_formats) {
      ggsave(
        filename = file.path(paste0(filename, ".", format)),
        plot = plot,
        width = width,
        height = height,
        create.dir = create_dir
      )
    }
    invisible(NULL)
  }

#' Partial Least Squares Regression for background factor regression
#'
#' This function performs Partial Least Squares (PLS) regression to model and extract
#' a background factor using isotype controls from single-cell data. It can optionally
#' residualize the data against covariates before fitting the PLS model.
#'
#' @param pg_data A PNA object containing single-cell data.
#' @param isotype_markers A character vector of isotype control marker names.
#' @param model_mat An optional matrix of covariates for residualization (cells × covariates).
#' @param remove_covariates Logical; if TRUE, residualizes data against model_mat before PLS.
#' @param layer String; the data layer in pg_data to use (default is "scale.data").
#'
#' @return A list containing the PLS model, scores, and loadings.
isotype_pls <-
  function(pg_data, isotype_markers, model_mat = NULL, remove_covariates = FALSE, layer = "scale.data") {

    library(pls)

    residualize <- function(M, covariates) {
      Q <- qr(covariates)
      M - covariates %*% qr.coef(Q, M)
    }

    # transpose to cells × features
    X <-
      pg_data |>
      LayerData(layer = layer) |>
      t() |>
      as.matrix()

    # Residualize X
    if (remove_covariates) X <- residualize(X, model_mat)

    X_no_isotype <-
      X[, !colnames(X) %in% isotype_markers]
    X_isotype <-
      X[, colnames(X) %in% isotype_markers]

    model <-
      plsr(
        X_isotype ~ X_no_isotype,
        ncomp = 1,
        scale = FALSE,
        validation = "none",
        segments = 10
      )

    score <-
      scores(model)[, 1]

    loadings <-
      loadings(model)[, 1]

    if (cor(score, rowMeans(X_isotype)) < 0) {
      score <- -score
      loadings <- -loadings
    }

    return(
      list(
        model = model,
        scores = score,
        loadings = loadings
      )
    )

  }
