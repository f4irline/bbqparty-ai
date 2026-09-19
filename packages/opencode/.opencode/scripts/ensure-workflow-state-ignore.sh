#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -ne 1 ]; then
  printf 'Usage: %s <repository-or-worktree-path>\n' "$0" >&2
  exit 64
fi

worktree_path="$1"
ignore_patterns=(
  '/.opencode/.bbq-state/'
  '/.opencode/.bbq-runtime/'
)

if [ ! -d "$worktree_path" ]; then
  printf 'Repository or worktree path does not exist: %s\n' "$worktree_path" >&2
  exit 1
fi

if ! common_git_dir="$(git -C "$worktree_path" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)"; then
  exit 0
fi

exclude_file="$common_git_dir/info/exclude"
mkdir -p "$(dirname "$exclude_file")"
for ignore_pattern in "${ignore_patterns[@]}"; do
  if [ ! -f "$exclude_file" ] || ! grep -Fqx "$ignore_pattern" "$exclude_file"; then
    printf '%s\n' "$ignore_pattern" >> "$exclude_file"
  fi
done
