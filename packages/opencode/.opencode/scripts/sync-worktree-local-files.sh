#!/usr/bin/env bash

set -euo pipefail

usage() {
  printf '%s\n' "Usage: sync-worktree-local-files.sh <source-repo-root> <worktree-path>" >&2
}

if [ "$#" -ne 2 ]; then
  usage
  exit 64
fi

source_root="$1"
worktree_path="$2"

if [ ! -d "$source_root" ]; then
  printf 'Source repository root does not exist: %s\n' "$source_root" >&2
  exit 1
fi

if [ ! -d "$worktree_path" ]; then
  printf 'Worktree path does not exist: %s\n' "$worktree_path" >&2
  exit 1
fi

sync_list="$source_root/.opencode/worktree-local-files"
linked_count=0
copied_count=0

if [ -f "$sync_list" ]; then
  while IFS= read -r relative_path || [ -n "$relative_path" ]; do
    case "$relative_path" in
      ""|\#*)
        continue
        ;;
      /*|..|../*|*/../*|*/..)
        printf 'Invalid worktree-local-files entry: %s\n' "$relative_path" >&2
        exit 1
        ;;
    esac

    source_path="$source_root/$relative_path"
    target_path="$worktree_path/$relative_path"

    if [ ! -e "$source_path" ] && [ ! -L "$source_path" ]; then
      continue
    fi

    if [ -e "$target_path" ] || [ -L "$target_path" ]; then
      continue
    fi

    mkdir -p "$(dirname "$target_path")"
    if ln -s "$source_path" "$target_path" 2>/dev/null; then
      linked_count=$((linked_count + 1))
    else
      cp -R "$source_path" "$target_path"
      copied_count=$((copied_count + 1))
    fi
  done < "$sync_list"
fi

printf 'Local files linked: %s\n' "$linked_count"
printf 'Local files copied: %s\n' "$copied_count"
