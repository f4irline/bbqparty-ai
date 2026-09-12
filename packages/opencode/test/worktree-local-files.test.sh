#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
sync_script="$repo_root/packages/opencode/.opencode/scripts/sync-worktree-local-files.sh"
temp_dir="$(mktemp -d)"

cleanup() {
  rm -rf "$temp_dir"
}

trap cleanup EXIT

source_root="$temp_dir/source repo"
worktree_path="$temp_dir/worktree path"
mkdir -p "$source_root/.opencode" "$source_root/config/nested" "$worktree_path/config"
printf '%s\n' 'nested secret' > "$source_root/config/nested/.env"
printf '%s\n' 'space secret' > "$source_root/local file.env"
printf '%s\n' 'source value' > "$source_root/keep.env"
printf '%s\n' 'worktree value' > "$worktree_path/keep.env"

cat > "$source_root/.opencode/worktree-local-files" <<'EOF'
# Local configuration shared by ticket worktrees.

config/nested/.env
missing.env
local file.env
keep.env
EOF

output="$("$sync_script" "$source_root" "$worktree_path")"
expected_output=$'Local files linked: 2\nLocal files copied: 0'
if [ "$output" != "$expected_output" ]; then
  printf 'Unexpected sync output:\n%s\n' "$output" >&2
  exit 1
fi

if [ ! -L "$worktree_path/config/nested/.env" ]; then
  printf '%s\n' 'Nested source file was not symlinked' >&2
  exit 1
fi

if [ "$(readlink "$worktree_path/config/nested/.env")" != "$source_root/config/nested/.env" ]; then
  printf '%s\n' 'Nested symlink points at the wrong source file' >&2
  exit 1
fi

if [ ! -L "$worktree_path/local file.env" ]; then
  printf '%s\n' 'Path containing spaces was not symlinked' >&2
  exit 1
fi

if [ "$(<"$worktree_path/keep.env")" != "worktree value" ]; then
  printf '%s\n' 'Existing worktree file was overwritten' >&2
  exit 1
fi

if [ -e "$worktree_path/missing.env" ]; then
  printf '%s\n' 'Missing source entry created a worktree file' >&2
  exit 1
fi

printf '%s\n' '/tmp/outside-worktree' > "$source_root/.opencode/worktree-local-files"
if "$sync_script" "$source_root" "$worktree_path" > /dev/null 2>&1; then
  printf '%s\n' 'Absolute allowlist path was accepted' >&2
  exit 1
fi
printf '%s\n' '../outside-worktree' > "$source_root/.opencode/worktree-local-files"
if "$sync_script" "$source_root" "$worktree_path" > /dev/null 2>&1; then
  printf '%s\n' 'Parent-directory allowlist path was accepted' >&2
  exit 1
fi
if [ -e "$temp_dir/outside-worktree" ]; then
  printf '%s\n' 'Traversal allowlist path created a file outside the worktree' >&2
  exit 1
fi

before_count="$(rg --files "$worktree_path" | wc -l | tr -d ' ')"
if "$sync_script" "$temp_dir/missing-source" "$worktree_path" > /dev/null 2>&1; then
  printf '%s\n' 'Missing source root was accepted' >&2
  exit 1
fi
if "$sync_script" "$source_root" "$temp_dir/missing-worktree" > /dev/null 2>&1; then
  printf '%s\n' 'Missing worktree path was accepted' >&2
  exit 1
fi
after_count="$(rg --files "$worktree_path" | wc -l | tr -d ' ')"
if [ "$before_count" != "$after_count" ]; then
  printf '%s\n' 'Invalid invocation changed the worktree' >&2
  exit 1
fi
