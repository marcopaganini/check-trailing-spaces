#!/bin/bash
# Exit with an error code if the current commit contains files with
# lines having spaces or tabs at EOL.

CHANGED_FILES="${HOME}/changed_files.txt"

set -o errexit
set -o nounset

readonly tmpfile
tmpfile="$(mktemp)"
# shellcheck disable=SC2064
trap "rm -f ${tmpfile}" 0

# Read and process INPUT_* and other global variables.
readonly source_dir="${INPUT_SOURCE_DIRECTORY:-.}"
readonly pr_number="${INPUT_PR_NUMBER:-}"
readonly github_repository=${GITHUB_REPOSITORY:-}
check_all_files="${INPUT_CHECK_ALL_FILES:-0}"

echo "Check for trailing spaces inside text files"
echo "==========================================="

# If pr_number or github_repository are empty, check all files.
if [[ -z "${pr_number}" ]] || [[ -z "${github_repository}" ]]; then
  echo -e "Note: INPUT_PR_NUMBER or GITHUB_REPOSITORY not set. Checking all files.\n"
  check_all_files=1
fi

# Note: source_dir is ignored unless check_all_files is set.
if (( check_all_files )); then
  find "${source_dir}" -name .git -type d -prune -o -type f -print | sort >"${CHANGED_FILES}"
else
  # Retrieve list of changes files.
  URL="https://api.github.com/repos/${GITHUB_REPOSITORY}/pulls/${pr_number}/files"
  curl -s -X GET -G "${URL}" | jq -r '.[] | .filename' > "${CHANGED_FILES}"
fi

while read -r fname; do
  # Only check text files with size > 0.
  if [[ -s "${fname}" ]] && file --mime "${fname}" | grep -q " text/"; then
    grep -HPn '[ \t]+$' "${fname}" >>"${tmpfile}" || true
  fi
done < "${CHANGED_FILES}"

if [[ -s "${tmpfile}" ]]; then
  echo "Found files containing lines with spaces or tabs at end-of-line."
  echo "Please remove all lines containing only spaces and any extra"
  echo "spaces or tabs after the last non-blank character in the files"
  echo "and lines indicated below:"
  echo
  while read -r line; do
    fname=$(echo "${line}" | cut -d: -f1)
    linenum=$(echo "${line}" | cut -d: -f2)
    echo "${fname}:${linenum}: Line contains trailing whitespaces."
    # TODO(investigate why this prints no file or linenumber)
    #echo "::error file=${fname},line=${linenum}::Line contains trailing whitespaces."
  done < "${tmpfile}"
  exit 1
fi

echo "Test successful"
exit 0
