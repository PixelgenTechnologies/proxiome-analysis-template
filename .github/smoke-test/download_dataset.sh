#!/usr/bin/env bash
# Download and MD5-verify PXL files listed in dataset.yaml (CI smoke-test helper).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DATASET_YAML="${SCRIPT_DIR}/dataset.yaml"

if [[ ! -f "${DATASET_YAML}" ]]; then
  echo "Missing ${DATASET_YAML}" >&2
  exit 1
fi

# Parse simple list entries: "- url:", "path:", "md5:" (order-independent within each item).
mapfile -t ENTRIES < <(
  awk '
    /^[[:space:]]*-[[:space:]]*url:[[:space:]]*/ {
      if (url != "" && path != "" && md5 != "") print url "\t" path "\t" md5
      url = $0; sub(/^[[:space:]]*-[[:space:]]*url:[[:space:]]*/, "", url)
      path = ""; md5 = ""
      next
    }
    /^[[:space:]]*path:[[:space:]]*/ {
      path = $0; sub(/^[[:space:]]*path:[[:space:]]*/, "", path)
      next
    }
    /^[[:space:]]*md5:[[:space:]]*/ {
      md5 = $0; sub(/^[[:space:]]*md5:[[:space:]]*/, "", md5)
      next
    }
    END {
      if (url != "" && path != "" && md5 != "") print url "\t" path "\t" md5
    }
  ' "${DATASET_YAML}"
)

if [[ ${#ENTRIES[@]} -eq 0 ]]; then
  echo "No files listed in ${DATASET_YAML}" >&2
  exit 1
fi

for entry in "${ENTRIES[@]}"; do
  IFS=$'\t' read -r url rel_path expected_md5 <<< "${entry}"
  expected_md5="$(echo "${expected_md5}" | tr '[:upper:]' '[:lower:]')"
  dest="${ROOT}/${rel_path}"
  mkdir -p "$(dirname "${dest}")"

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
done

echo "All dataset files ready."
