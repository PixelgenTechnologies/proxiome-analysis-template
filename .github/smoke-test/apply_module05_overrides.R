# CI / local smoke overrides for modules/05_statistical_testing.qmd.
# Sourced from the §5.0 setup chunk when this file exists (repo clones).
# No-op unless PAT_SMOKE_PSEUDOBULK=1.
#
# Usage (after modules 01–02 checkpoints exist):
#   PAT_SMOKE_PSEUDOBULK=1 Rscript .github/smoke-test/smoke_pseudobulk.R
#   PAT_SMOKE_PSEUDOBULK=1 quarto render modules/05_statistical_testing.qmd

if (identical(Sys.getenv("PAT_SMOKE_PSEUDOBULK"), "1")) {
  run_pseudobulk <- TRUE
  run_cell_level <- FALSE
  message(
    "PAT_SMOKE_PSEUDOBULK=1: enabling limma pseudobulk; ",
    "skipping cell-level Wilcoxon"
  )
}
