#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
ignore_script="$repo_root/packages/opencode/.opencode/scripts/ensure-workflow-state-ignore.sh"
temp_dir="$(mktemp -d)"

cleanup() {
  rm -rf "$temp_dir"
}

trap cleanup EXIT

source_repo="$temp_dir/source"
ticket_worktree="$temp_dir/ticket"
mkdir -p "$source_repo"
git -C "$source_repo" init --quiet
git -C "$source_repo" config user.name 'BBQ Test'
git -C "$source_repo" config user.email 'bbq-test@example.com'
printf '%s\n' 'test repository' > "$source_repo/README.md"
git -C "$source_repo" add README.md
git -C "$source_repo" commit --quiet -m 'test: initialize repository'
git -C "$source_repo" worktree add --quiet -b feat/test-workflow-state "$ticket_worktree" HEAD

mkdir -p "$ticket_worktree/.opencode/.bbq-state"
mkdir -p "$ticket_worktree/.opencode/.bbq-runtime"
printf '%s\n' 'local workflow state' > "$ticket_worktree/.opencode/.bbq-state/feat-test.md"
printf '%s\n' 'local runtime rules' > "$ticket_worktree/.opencode/.bbq-runtime/HOUSE_RULES.md"
if git -C "$ticket_worktree" check-ignore --quiet .opencode/.bbq-state/feat-test.md; then
  printf '%s\n' 'Workflow state was already ignored before helper setup' >&2
  exit 1
fi
if git -C "$ticket_worktree" check-ignore --quiet .opencode/.bbq-runtime/HOUSE_RULES.md; then
  printf '%s\n' 'Workflow runtime was already ignored before helper setup' >&2
  exit 1
fi

bash "$ignore_script" "$ticket_worktree"
bash "$ignore_script" "$ticket_worktree"

if ! git -C "$ticket_worktree" check-ignore --quiet .opencode/.bbq-state/feat-test.md; then
  printf '%s\n' 'Workflow state was not ignored in linked worktree' >&2
  exit 1
fi
if ! git -C "$ticket_worktree" check-ignore --quiet .opencode/.bbq-runtime/HOUSE_RULES.md; then
  printf '%s\n' 'Workflow runtime was not ignored in linked worktree' >&2
  exit 1
fi

common_git_dir="$(git -C "$source_repo" rev-parse --path-format=absolute --git-common-dir)"
if [ "$(rg --fixed-strings --count '/.opencode/.bbq-state/' "$common_git_dir/info/exclude")" -ne 1 ]; then
  printf '%s\n' 'Workflow state ignore helper was not idempotent' >&2
  exit 1
fi
if [ "$(rg --fixed-strings --count '/.opencode/.bbq-runtime/' "$common_git_dir/info/exclude")" -ne 1 ]; then
  printf '%s\n' 'Workflow runtime ignore helper was not idempotent' >&2
  exit 1
fi

printf '%s\n' 'PASS: workflow state ignore'
