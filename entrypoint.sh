#!/bin/bash
# Exit with an error code if the current commit contains files with
# lines having spaces or tabs at EOL.
#
# Jun/2021 by Marco Paganini <paganini@paganini.net>

set -o errexit
set -o nounset

CHANGED_FILES="${HOME}/changed_files.txt"

tmpfile="$(mktemp)"
# shellcheck disable=SC2064
trap "rm -f ${tmpfile}" 0

# Read and process INPUT_* and other global variables.
readonly source_dir="${INPUT_SOURCE_DIRECTORY:-.}"
readonly pr_number="${INPUT_PR_NUMBER:-}"
readonly check_empty_line_at_eof="${INPUT_CHECK_EMPTY_LINE_AT_EOF:-1}"
readonly check_missing_newline_at_eof="${INPUT_CHECK_MISSING_NEWLINE_AT_EOF:-1}"
readonly ignore_regex="${INPUT_IGNORE_REGEX:-}"
readonly github_repository=${GITHUB_REPOSITORY:-}
check_all_files="${INPUT_CHECK_ALL_FILES:-0}"

function is_text_file() {
  [[ -s "${1}" ]] && file --mime "${1}" | grep -q " text/"
}

function main() {
  local ret=0

  echo "Check for trailing spaces inside text files"
  echo "==========================================="

  # If pr_number or github_repository are empty, check all files.
  if [[ -z "${pr_number}" ]] || [[ -z "${github_repository}" ]]; then
    echo -e "Note: INPUT_PR_NUMBER or GITHUB_REPOSITORY not set. Checking all files.\n"
    check_all_files=1
  fi

  # Note: source_dir is ignored unless check_all_files is set.
  if (( check_all_files )); then
    fcmd=(find "${source_dir}" "-name" ".git" "-type" "d" "-prune" "-o" "-type" "f")
    if [[ -n "${ignore_regex}" ]]; then
      fcmd+=("!" "-regex" "${ignore_regex}")
    fi
    fcmd+=("-print")
    "${fcmd[@]}" | sort >"${CHANGED_FILES}"
  else
    # Retrieve list of changes files.
    URL="https://api.github.com/repos/${GITHUB_REPOSITORY}/pulls/${pr_number}/files"
    curl -s -X GET -G "${URL}" | jq -r '.[] | .filename' > "${CHANGED_FILES}"
  fi

  while read -r fname; do
    if is_text_file "${fname}"; then
      grep -HPn '[ \t]+$' "${fname}" >>"${tmpfile}" || true
    fi
  done < "${CHANGED_FILES}"

  if [[ -s "${tmpfile}" ]]; then
    ret=1
    echo "Found files containing lines with spaces or tabs at end-of-line."
    echo "Please replace all lines containing only spaces with empty lines"
    echo "and remove any extra spaces or tabs after the last non-blank"
    echo "character in the files and lines indicated below:"
    echo "================================================================"
    while read -r line; do
      fname=$(echo "${line}" | cut -d: -f1)
      linenum=$(echo "${line}" | cut -d: -f2)
      echo "* ${fname}:${linenum}"
    done < "${tmpfile}"
    echo ""
  fi

  # Check for empty lines at EOF.
  found=0
  if (( check_empty_line_at_eof )); then
    while read -r fname; do
      is_text_file "${fname}" || continue

      last_line="$(tail -n 1 "$fname")"
      if [[ -z "$last_line" ]]; then
        if (( ! found )); then
          echo "Found files ending in blank lines. Please remove all blank"
          echo "lines at the end of the files listed below:"
          echo "=========================================================="
          found=1
          ret=1
        fi
        echo "* $fname"
      fi
    done < "${CHANGED_FILES}"

    # Add a blank line to the output.
    (( found )) && echo ""
  fi

  # Check for EOF_MISSING_NEWLINE.
  found=0
  if (( check_missing_newline_at_eof )); then
    while read -r fname; do
      is_text_file "${fname}" || continue

      last_char="$(tail -c 1 "$fname")"
      if [[ -n "$last_char" ]]; then
        if (( ! found )); then
          echo "Found files where the last line does not end in a newline."
          echo "Please add a newline (not an empty line) to the files below."
          echo ""
          echo "TIP: If you're using VSCode, see this Stack Overflow question:"
          echo "https://stackoverflow.com/questions/44704968/visual-studio-code-insert-newline-at-the-end-of-files"
          echo "=============================================================="
          found=1
          ret=1
        fi
        echo "* $fname"
      fi
    done < "${CHANGED_FILES}"

    # Add a blank line to the output.
    (( found )) && echo ""
  fi

  return "${ret}"
}

main "$@"
