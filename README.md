# Single Cell PNA analysis SOP

This repository holds the Analysis Standard Operating Procedure (SOP) for single cell PNA data. 

The SOP is a Quarto (.qmd) file that you can use as a starting point for analysis, 
and includes analysis steps that are typically performed for an analysis of PNA data. 
However, you are free to customize it as needed for your specific dataset and research questions.

## Folder structure

The SOP Quarto file assumes that you have this folder structure:

```
.
├── data/                       # Input data (optional, can be placed elsewhere)
├── results/                    # Output results
└── scripts/                    # Analysis scripts
    └── single_cell_pna_sop.qmd # SOP Quarto file (can be renamed)
```

## Samplesheet

The analysis requires a metadata file (samplesheet) in CSV format that maps sample information to file paths. This file must contain the following required columns:

- **sample_id**: A short, unique identifier for each sample (e.g., `S1`, `S2`, `S3`)
- **sample_alias**: A more descriptive name for the sample (e.g., `S1_resting`, `S2_PHA`)
- **file_path**: The full path to the corresponding PNA file for each sample
- **condition**: A description of the sample condition

You can include additional columns as needed (e.g., `donor`, `time_point`, `treatment`). These will be automatically added to the PNA object as metadata columns and can be used for downstream analysis and visualization.

Example samplesheet:

```
sample_id,sample_alias,file_path,condition,donor
S1,S1_resting,/User/username/data/S1_resting.pna,resting,D1
S2,S2_PHA,/User/username/data/S2_PHA.pna,stimulated,D2
S3,S3_IL2,/User/username/data/S3_IL2.pna,IL2_treated,D1
```