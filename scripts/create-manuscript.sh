#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CHAPTERS_DIR="${REPO_ROOT}/chapters"
OUTPUT_FILE="${REPO_ROOT}/OUTLINE.md"

if [[ ! -d "${CHAPTERS_DIR}" ]]; then
  echo "Chapters directory not found: ${CHAPTERS_DIR}" >&2
  exit 1
fi

shopt -s nullglob

normalize_part_heading() {
  local part_name="$1"

  if [[ "${part_name}" =~ ^Part[[:space:]]+([0-9]+)[[:space:]]*-[[:space:]]*(.+)$ ]]; then
    printf 'Part %s - %s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
    return
  fi

  printf '%s\n' "${part_name}"
}

normalize_chapter_heading() {
  local chapter_file_name="$1"
  local chapter_name="${chapter_file_name%.md}"

  if [[ "${chapter_name}" =~ ^Chapter[[:space:]]+([0-9]+)[[:space:]]*-[[:space:]]*(.+)$ ]]; then
    printf 'Chapter %s - %s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
    return
  fi

  printf '%s\n' "${chapter_name}"
}

append_chapter_content() {
  local chapter_file="$1"

  awk '
    NR == 1 && $0 ~ /^# Chapter / {
      skipped_title = 1
      next
    }
    skipped_title && NR == 2 && $0 == "" {
      next
    }
    {
      print
    }
  ' "${chapter_file}"
}

{
  printf '# The House Without Walls\n\n'
  printf 'A Novel by Joshua Szepietowski\n'
} > "${OUTPUT_FILE}"

for part_dir in "${CHAPTERS_DIR}"/*/; do
  [[ -d "${part_dir}" ]] || continue

  part_dir="${part_dir%/}"
  part_heading="$(normalize_part_heading "$(basename "${part_dir}")")"

  printf '\n\n## %s\n' "${part_heading}" >> "${OUTPUT_FILE}"

  for chapter_file in "${part_dir}"/*.md; do
    [[ -f "${chapter_file}" ]] || continue

    chapter_heading="$(normalize_chapter_heading "$(basename "${chapter_file}")")"

    printf '\n\n### %s\n\n' "${chapter_heading}" >> "${OUTPUT_FILE}"
    append_chapter_content "${chapter_file}" >> "${OUTPUT_FILE}"
  done
done

printf '\n' >> "${OUTPUT_FILE}"

echo "Wrote ${OUTPUT_FILE}"