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
