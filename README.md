# check-trailing-spaces

## Name

check-trailing-spaces - Checks for trailing spaces in text files and other conditions.

## Description

This Github action checks the files being submitted and flags any files
that contains one of the following conditions:

* Trailing spaces at end of line.
* Files ending with blank lines.
* Files ending with a line that does not terminate in a new line character.

## Arguments

*  `check_all_files`: Set to 1 to check _all_ files in the Github directory,
   not only the modified files in the current PR.

*  `check_empty_line_at_eof`: Set to 1 (default) to check for empty lines
   at the end of the file.

*  `check_missing_newline_at_eof`: Set to 1 (default) to check for files having
   a last line that does not end in a newline character (common with misconfigured
   VSCode configurations).

*  `ignore_regex`: A regular expression matching full paths to ignore. Paths
   usually start with "./", unless `source_directory` is also specified.
   Example: `"\./content.*"` will ignore all files under the "./content"
   directory. For further information, look at the man page for the "find"
   command, option "-regex". Please note that files in the "./.git" directory
   will be automatically ignored.

* `source_directory`: When `check_all_files` is set, use this directory as
  the root of the tree to be checked, instead of the Git repository root.
  This action will only check text files.

* `pr_number`: The number of the PR to check. There's usually no need to
  change this. The default is the current PR number.

## Example

**.github/workflows/main.yml**

```
on: [push]

jobs:
  example-workflow:
    name: Example workflow using the check-trailing-spaces action.

  steps:
    - name: Checkout repository contents.
      uses: actions/checkout@v1

    - name: Check lines in files for trailing whitespaces.
      uses: marcopaganini/check-trailing-spaces@v1

    - with: # Most people won't need this.
        check_all_files: 1
        source_directory: /ext
```

## Author

Marco Paganini (https://github.com/marcopaganini)<br>
