#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"

for command in bbq.fire.md bbq.taste.md; do
  command_file="$repo_root/packages/opencode/.opencode/commands/$command"
  for required in \
    '.opencode/bbq-config.json' \
    'runtime == "herdr"' \
    'HERDR_ENV=1' \
    'herdr' \
    'herdr worktree list' \
    'herdr worktree open' \
    'herdr worktree create' \
    '--path' \
    '.result.worktrees' \
    '.result.worktree.path' \
    '.result.workspace.workspace_id' \
    'sync-worktree-local-files.sh' \
    'git-worktree-prepare' \
    'git-worktree-find'; do
    if ! rg --fixed-strings --quiet -- "$required" "$command_file"; then
      printf 'Missing provider contract %s in %s\n' "$required" "$command_file" >&2
      exit 1
    fi
  done
done

printf '%s\n' 'PASS: worktree provider contract'
