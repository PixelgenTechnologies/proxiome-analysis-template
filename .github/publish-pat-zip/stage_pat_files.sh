#!/usr/bin/env bash
# Stage the slim PAT file set for release zip packaging (CI helper; runnable locally).
# After staging: zip -r "proxiome-analysis-template-VERSION.zip" "proxiome-analysis-template-VERSION"
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

usage() {
  echo "Usage: $(basename "$0") VERSION" >&2
  echo "  VERSION: release tag (e.g. v1.0.0) or 'dev'" >&2
  exit 1
}

[[ $# -eq 1 ]] || usage

VERSION="$1"
if [[ "${VERSION}" != v* && "${VERSION}" != "dev" ]]; then
  VERSION="v${VERSION}"
fi

FOLDER="proxiome-analysis-template-${VERSION}"
STAGING="${ROOT}/${FOLDER}"

cd "${ROOT}"
mkdir -p "${STAGING}/data" "${STAGING}/modules"
cp proxiome_analysis_template.qmd "${STAGING}/"
cp proxiome_analysis_template.Rproj "${STAGING}/"
cp README.md LICENSE.md "${STAGING}/"
cp -r modules/. "${STAGING}/modules/"
# Blank template metadata (header only) for naive users
printf 'sample_id,sample_alias,condition,file_path\n' > "${STAGING}/data/metadata.csv"

# Sanity: no CI/dev-only paths
if [[ -e "${STAGING}/.github" || -e "${STAGING}/Dockerfile" ]]; then
  echo "Unexpected files included in slim zip staging" >&2
  exit 1
fi

echo "Staged ${FOLDER}:"
find "${STAGING}" -type f | sort
