<div align="center">

# Proxiome Analysis Template

**A complete, reproducible workflow for single-cell Proximity Network Analysis**

[![R](https://img.shields.io/badge/R-4.1+-blue?logo=r)](https://www.r-project.org/)
[![Quarto](https://img.shields.io/badge/Quarto-Document-purple)](https://quarto.org/)
[![License: GPL v2](https://img.shields.io/badge/License-GPL_v2-green.svg)](LICENSE.md)

*Analyze PNA data from the [nf-core/pixelator](https://nf-co.re/pixelator) pipeline with quality control, clustering, annotation, and publication-ready visualizations.*

[**Get Started →**](#-quick-start) · [Tutorials](https://software.pixelgen.com/pna-analysis/introduction/) · [pixelatorR](https://github.com/PixelgenTechnologies/pixelatorR)

</div>

---

<br>

## 📋 Contents

- [Quick Start](#-quick-start)
- [Environment Setup](#-first-time-r-setup)
- [Prepare Your Data](#-prepare-your-data)
- [Run the Analysis](#-run-the-analysis)
- [Troubleshooting](#-troubleshooting)
- [Maintainers](#-maintainers)

---

<br>

## 🚀 Quick Start

Choose the method that works best for you:

### Download ZIP *(Recommended)*

The simplest way to get started - no GitHub account or special tools needed.

1. Click the green **Code** button above → **Download ZIP**
2. Extract to a folder (e.g., `Documents/my-analysis`)
3. Continue to [Environment Setup](#-environment-setup)

> 💡 **Tip:** Always open your project by double-clicking `proxiome_analysis_template.Rproj` - this sets up file paths automatically.

<br>

<details>
<summary><strong>Advanced: Using git to clone this repository</strong></summary>

<br>

#### GitHub Desktop

A visual interface for managing repositories - no command line needed.

1. Install [GitHub Desktop](https://desktop.github.com/download/)
2. **File → Clone repository** → paste: `https://github.com/PixelgenTechnologies/proxiome-analysis-template`
3. Click **Clone**

#### Git Clone

```bash
git clone https://github.com/PixelgenTechnologies/proxiome-analysis-template.git
cd proxiome-analysis-template
```

#### Use as Template

1. Click **Use this template** at the top of this page (requires GitHub account)
2. Create your new repository
3. Download your repository via GitHub Desktop or `git clone`

</details>

---

<br>

## ⚙️ First-Time R Setup

### 1. Install R and RStudio

| Software | Download |
|----------|----------|
| **R** (4.1+) | [CRAN](https://cran.r-project.org/) |
| **RStudio** | [Posit](https://posit.co/download/rstudio-desktop/) |

> 🆕 **New to R?** Read the [Getting Started with R](https://rstudio-education.github.io/hopr/starting.html) guide first.

<br>

### 2. Install Compiler Tools

Some R packages require compilation. Install the appropriate tools for your operating system:

<br>

<details>
<summary><strong>Windows</strong></summary>

Also install [Rtools](https://cran.r-project.org/bin/windows/Rtools/). Choose the version matching your R installation (required for some packages).

</details>

<details>
<summary><strong>macOS</strong></summary>

Press Command + Spacebar to open Spotlight search, type "Terminal," and hit Enter to open the terminal.

Install Xcode tools by running this in the terminal: 

```bash
xcode-select --install
```

</details>

<details>
<summary><strong>Linux</strong></summary>

After installing R, install system libraries: 

```bash
sudo apt install cmake libglpk-dev libhdf5-dev libfreetype6-dev libpng-dev libtiff5-dev libjpeg-dev libwebp-dev
```

</details>

<br>

### 3. Install R Packages

Open the R project file in RStudio (by opening `proxiome_analysis_template.Rproj`) and run in the console:

```r
# Core packages
install.packages(c("tidyverse", "Seurat", "here", "Matrix", 
                   "ggraph", "pls", "ggplotify", "harmony", "ggbeeswarm"))

# Bioconductor
install.packages("BiocManager")
BiocManager::install("ComplexHeatmap")

# pixelatorR
install.packages("pak")
pak::pak("PixelgenTechnologies/pixelatorR")
```

<details>
<summary><strong>Advanced: Docker or renv</strong></summary>

<br>

**Docker:** Pre-built images available at [quay.io/pixelgen-technologies/proxiome-analysis-template](https://quay.io/pixelgen-technologies/proxiome-analysis-template)

**renv:** Run `renv::restore()` to install exact package versions from `renv.lock`.

</details>

---

<br>

## 📁 Prepare Your Data

When you have everything installed, add your `.pxl` data files and a `metadata.csv` to the `data/` folder as shown below.

### Project structure

```
proxiome-analysis-template/           ← Your project folder (can be renamed to whatever you want)
├── data/
│   ├── metadata.csv                  ← Your sample info
│   └── *.layout.pxl                  ← Your PXL files
├── results/                          ← Created automatically when running the PAT
├── proxiome_analysis_template.Rproj  ← Double-click to open the project in RStudio
└── proxiome_analysis_template.qmd    ← The Proxiome Analysis Template QMD file
```

### Create metadata.csv

The `metadata.csv` file describes **your** samples and links them to the corresponding PXL files. 

| Column | Required | Description | Example |
|--------|:--------:|-------------|---------|
| `sample_id` | ✓ | Unique identifier | `S1` |
| `sample_alias` | ✓ | Descriptive name | `S1_resting` |
| `condition` | ✓ | Experimental group | `resting` |
| `file_path` | ✓ | PXL filename (not full path) | `Sample1.layout.pxl` |
| *other* | | Any extra columns (`donor`, `batch`, etc.) | - |

> 💡 Extra columns are available as variables in the template for grouping or covariates.

**Example file:**

You can use the placeholder `data/metadata.csv` as a template. Just replace the example rows with your own sample information and filenames:

```csv
sample_id,sample_alias,condition,file_path
S1,S1_resting,resting,PNA064_Sample_1_S1.layout.pxl
S2,S2_PHA,PHA,PNA064_Sample_2_S2.layout.pxl
```

> 📝 Row order controls plot order. Both `,` and `;` separators work.

---

<br>

## ▶️ Run the Analysis

1. **Open** `proxiome_analysis_template.Rproj` (double-click)
2. **Open** `proxiome_analysis_template.qmd` in RStudio
3. **Run chunks** in order (click ▶ or press `Ctrl+Shift+Enter` / `Cmd+Shift+Enter`)

### Key checkpoints

| Section | What to review |
|---------|----------------|
| **1.3.1** | QC thresholds (`n_umi_min_threshold`, `n_umi_max_threshold`, `isotype_percent_threshold`) |
| **1.4** | Marker selection - edit the `selected_markers` vector |
| **2** | Cell type annotations |

### Output

Results are saved to `results/` in PDF and PNG formats:

```
results/
├── 01_quality_control/
├── 02_data_processing/
├── 03_abundance/
├── 04_raw_proximity/
└── 05_statistical_testing/
```

---

<br>

## 🎨 Make it yours

This template is a starting point, not a rulebook.

Adapt it to fit your science, your questions, and how you like to work.

- Remove sections that don't apply to your data
- Rewrite code until it makes sense to you
- Swap out methods, thresholds, or visualizations
- Add new analysis steps wherever you need them

If it works better for you, it's the right way.

Happy analyzing!

---

<br>

## ❓ Troubleshooting

<details>
<summary><strong>Package installation fails</strong></summary>

Install compiler tools for your OS:
- **Windows:** [Rtools](https://cran.r-project.org/bin/windows/Rtools/)
- **macOS:** `xcode-select --install`
- **Linux:** `sudo apt install cmake libglpk-dev libhdf5-dev libfreetype6-dev libpng-dev libtiff5-dev libjpeg-dev libwebp-dev`

</details>

<details>
<summary><strong>"Cannot find function" error</strong></summary>

Run the Setup chunk (Section 0.1) first by clicking the green ▶ button.

</details>

<details>
<summary><strong>File not found</strong></summary>

1. Open the project via `proxiome_analysis_template.Rproj`
2. Check that PXL files are in `data/`
3. Verify filenames in `metadata.csv` match exactly

</details>

<details>
<summary><strong>Memory errors</strong></summary>

- Close other applications
- Process fewer samples
- Use a machine with 16GB+ RAM

</details>

<br>

**Need more help?** [Open an issue](https://github.com/PixelgenTechnologies/proxiome-analysis-template/issues) · [pixelatorR issues](https://github.com/PixelgenTechnologies/pixelatorR/issues)

---

<br>

## 👥 Maintainers

| | |
|---|---|
| **Max Karlsson** [@maxkarlsson](https://github.com/maxkarlsson) | [max.karlsson@pixelgen.com](mailto:max.karlsson@pixelgen.com) · [ORCID](https://orcid.org/0000-0002-7000-4416) |
| **Vincent Van Hoef** [@vincent-van-hoef](https://github.com/vincent-van-hoef) | [vincent.vanhoef@pixelgen.com](mailto:vincent.vanhoef@pixelgen.com) · [ORCID](https://orcid.org/0000-0003-1707-7066) |

---

<div align="center">

**License:** [GNU GPL v2](LICENSE.md)

*Made with ❤️ by [Pixelgen Technologies](https://pixelgen.com)*

</div>
