# check-trailing-spaces

## Name

check-trailing-spaces - Checks for trailing spaces in text files.

## Description

This Github action checks the files being submitted and flags any files
that contains lines with trailing spaces.

## Arguments

*  `check_all_files`: Set to 1 to check _all_ files in the Github directory,
   not only the modified files.

* `source_directory`: When `check_all_files` is set, use this directory as
   the root of the tree to be checked, instead of the Git repository root.

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
Jul/2021
