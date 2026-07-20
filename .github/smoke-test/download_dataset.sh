#!/usr/bin/env bash
# Download and MD5-verify PXL files listed in dataset.tsv (CI smoke-test helper).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DATASET_TSV="${SCRIPT_DIR}/dataset.tsv"

if [[ ! -f "${DATASET_TSV}" ]]; then
  echo "Missing ${DATASET_TSV}" >&2
  exit 1
fi

n_files=0
while IFS=$'\t' read -r url rel_path expected_md5 description || [[ -n "${url:-}" ]]; do
  # Skip comments, blank lines, and header
  [[ -z "${url}" || "${url}" =~ ^# ]] && continue
  [[ "${url}" == "url" ]] && continue

  expected_md5="$(printf '%s' "${expected_md5}" | tr '[:upper:]' '[:lower:]')"
  dest="${ROOT}/${rel_path}"
  mkdir -p "$(dirname "${dest}")"
  n_files=$((n_files + 1))

  if [[ -f "${dest}" ]]; then
    actual_md5="$(md5sum "${dest}" | awk '{print $1}')"
    if [[ "${actual_md5}" == "${expected_md5}" ]]; then
      echo "Already present and verified: ${dest}"
      continue
    fi
    echo "Existing file failed MD5 check; re-downloading: ${dest}"
    rm -f "${dest}"
  fi

  echo "Downloading ${url}"
  echo "  -> ${dest}"
  curl -fL --retry 3 --retry-delay 5 -o "${dest}" "${url}"

  actual_md5="$(md5sum "${dest}" | awk '{print $1}')"
  if [[ "${actual_md5}" != "${expected_md5}" ]]; then
    rm -f "${dest}"
    echo "MD5 mismatch for ${dest}" >&2
    echo "  expected: ${expected_md5}" >&2
    echo "  actual:   ${actual_md5}" >&2
    exit 1
  fi
  echo "Verified MD5: ${actual_md5}"
done < "${DATASET_TSV}"

if [[ "${n_files}" -eq 0 ]]; then
  echo "No files listed in ${DATASET_TSV}" >&2
  exit 1
fi

echo "All dataset files ready."
