# Cloud Agent base image for the Proxiome Analysis Template.
#
# Reuses the project's own maintained image, which is published to Quay from this
# repository's root Dockerfile on every merge to main (see DEVELOPERS.md and
# .github/workflows/build-docker-image.yaml). It ships the full analysis stack
# already validated by CI: R 4.6.1, Quarto, pixelatorR 0.18.3 + Seurat and the
# rest of the PAT dependencies, plus the lintr/styler developer tooling. Basing
# the Cloud Agent on this image keeps setup fast and reproducible instead of
# recompiling the Bioconductor stack from source on every environment build.
FROM quay.io/pixelgen-technologies/proxiome-analysis-template:main

# The runtime image is built for rendering and omits git, but Cloud Agents need
# it to stage, commit, and push work. Add git (and CA certs for HTTPS remotes).
RUN apt-get update \
    && apt-get install -y --no-install-recommends git ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
