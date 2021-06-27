#!/bin/bash
# Exit with an error code if the current commit contains files with
# lines having spaces or tabs at EOL.

CHANGED_FILES="${HOME}/changed_files.txt"

set -o errexit
set -o nounset

readonly tmpfile="$(mktemp)"
# shellcheck disable=SC2064
trap "rm -f ${tmpfile}" 0

# Basic command line parsing:
if [[ $# -ne 2 ]]; then
  echo >&2 "Use: program [check_all_files{0|1}] [source_dir]"
  exit 1
fi

readonly source_dir="${2}"
check_all_files="${1}"

echo "Check for trailing spaces inside text files"
echo "==========================================="

# If PR_NUMBER is not defined, assume we want to check all files
# (We need the indirection below to be able to use set -o nounset).
pr=${PR_NUMBER:-}
if [[ -z "${pr}" ]]; then
  echo -e "Note: The PR_NUMBER environment variable is not set. Checking all files.\n"
  check_all_files=1
fi

# Check arguments (argv[1] exists and is not null)
# This matches the check_all_files parameter in action.yml
if (( check_all_files )); then
  find "${source_dir}" -name .git -type d -prune -o -type f -print | sort >"${CHANGED_FILES}"
else
  # Retrieve list of changes files.
  URL="https://api.github.com/repos/${GITHUB_REPOSITORY}/pulls/${PR_NUMBER}/files"
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