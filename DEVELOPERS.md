## Linting

To run the linter, you need to install `lintr`. Then you can use one of the the following commands:

```r
# Lint entire package
lintr::lint_package()

# Lint single file
lintr::lint("path/to/file.R")
```

Alternatively, you can run the linter from RStudio through Addins -> Lint current file or Addins -> Lint current package.

The configuration file `.lintr` is used to specify the rules that the linter should follow. For compatibility with styler, some linting rules have been disabled.

## Styler

To style the code, you need to install `styler`. You can then use one of the following command:

```r
# Style single file
styler::style_file("proxiome_analysis_template.qmd", transformers = pixelatorR::pixelatorR_style())
```

## renv environment

To create a new `renv` environment, you can use the following command:

```r
renv::init(bare = TRUE)
```

Install dependencies:

```r
# Install BiocManager to enable installation of Bioconductor packages
install.packages("BiocManager")

# Add Bioconductor repos
options(repos = BiocManager::repositories())

# Install yaml to enable parsing of dependencies
install.packages("yaml")

# Locate dependencies
deps <- unique(renv::dependencies()$Package)
gh_deps <- c(pixelatorR = "PixelgenTechnologies/pixelatorR")

deps <- setdiff(deps, names(gh_deps))

# Install dependencies
renv::install(deps)
renv::install(gh_deps)
```

Create snapshot: 

```r
renv::settings$snapshot.type("all")

renv::snapshot()
```

To restore the `renv` environment, you can use the following command:
```r  
renv::restore()
```

