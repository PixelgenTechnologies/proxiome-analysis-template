FROM ghcr.io/pixelgentechnologies/pixelatorr:0.18.3

ARG QUARTO_VERSION="1.5.54"

RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/* && \
    export QUARTO_VERSION=${QUARTO_VERSION} && \
    mkdir -p /opt/quarto/${QUARTO_VERSION} && \
    curl -o quarto.tar.gz -L "https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-amd64.tar.gz" && \
    tar -zxvf quarto.tar.gz -C "/opt/quarto/${QUARTO_VERSION}" --strip-components=1 && \
    rm quarto.tar.gz

ENV PATH=/opt/quarto/${QUARTO_VERSION}/bin:$PATH

WORKDIR /workspace

RUN mkdir -p /workspace/data

# pixelatorR is pre-installed in the base image; install remaining PAT dependencies.
RUN R -e "pak::pak(c( \
  'tidyverse', 'Seurat', 'here', 'Matrix', 'ggraph', 'pls', \
  'ggplotify', 'harmony', 'ggbeeswarm', 'RcppML', 'ComplexHeatmap', \
  'clusterProfiler', 'org.Hs.eg.db', 'AnnotationDbi', 'limma' \
))"

COPY proxiome_analysis_template.qmd /workspace/proxiome_analysis_template.qmd
COPY proxiome_analysis_template.Rproj /workspace/proxiome_analysis_template.Rproj
COPY modules/ /workspace/modules/
COPY data/metadata.csv /workspace/data/metadata.csv
COPY README.md /workspace/README.md
COPY LICENSE.md /workspace/LICENSE.md
