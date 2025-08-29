#!/bin/bash
repo_dir="${_%/*}" # needs to be first thing in the file
set -e

if [ -z "$1" ]; then
  echo "usage: $0 /path/to/.file"
  exit 1
fi
if [ -n "$(git -C "${repo_dir}" status --porcelain)" ]; then
  echo "error: non-clean git working directory"
  exit 1
fi

file_path="$1" ; shift

file_name="$(basename "${file_path}")"
file_repo_path="${repo_dir}/${file_name}"
if ! [ -r "${file_path}" ]; then
  echo "error: ${file_path} not found or not readable"
  exit 1
fi
if [ -r "${file_repo_path}" ]; then
  echo "error: ${file_repo_path} already exists"
  exit 1
fi

mv "${file_path}" "${file_repo_path}"
ln -s "${file_repo_path}" "${file_path}"

git -C "${repo_dir}" add "${file_repo_path}"
git -C "${repo_dir}" commit -m "feat: add ${file_name}"

