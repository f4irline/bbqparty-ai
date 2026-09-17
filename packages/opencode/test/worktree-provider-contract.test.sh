#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
opencode_root="$repo_root/packages/opencode/.opencode"

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

fire_command="$opencode_root/commands/bbq.fire.md"
for required in \
  'BBQ_WORKFLOW_ROOT' \
  'BBQ_WORKTREE_PATH' \
  'BBQ_BRANCH_NAME' \
  'pre-resolved'; do
  if ! rg --fixed-strings --quiet -- "$required" "$fire_command"; then
    printf 'Missing orchestrated Fire handoff contract %s\n' "$required" >&2
    exit 1
  fi
done

for command in bbq.pantry.md bbq.prep.md; do
  command_file="$opencode_root/commands/$command"
  if ! rg --fixed-strings --quiet -- 'BBQ_WORKFLOW_ROOT' "$command_file"; then
    printf 'Missing orchestrated workflow root contract in %s\n' "$command_file" >&2
    exit 1
  fi
done
if ! rg --fixed-strings --quiet -- 'BBQ_WORKFLOW_ROOT' "$opencode_root/prompts/sous-chef.txt"; then
  printf '%s\n' 'Missing orchestrated workflow root contract in sous-chef prompt' >&2
  exit 1
fi
for config in opencode.github-pat.json opencode.github-app.json; do
  config_file="$repo_root/packages/opencode/$config"
  if [ "$(jq --raw-output '.agent["sous-chef"].tools.bash' "$config_file")" != "true" ] || \
    [ "$(jq --raw-output '.agent["sous-chef"].permission.bash["printenv BBQ_WORKFLOW_ROOT"]' "$config_file")" != "allow" ] || \
    [ "$(jq --raw-output '.agent["sous-chef"].permission.bash["git -C * rev-parse --show-toplevel"]' "$config_file")" != "allow" ]; then
    printf 'Sous-chef lacks narrow workflow-root shell access in %s\n' "$config_file" >&2
    exit 1
  fi
done

station_command="$opencode_root/commands/bbq.station.md"
station_agent="$opencode_root/agents/station.md"
for file in "$station_command" "$station_agent"; do
  if [ ! -f "$file" ]; then
    printf 'Missing station agent artifact %s\n' "$file" >&2
    exit 1
  fi
done
if rg --quiet '^model:' "$station_agent"; then
  printf '%s\n' 'Station agent pins a model' >&2
  exit 1
fi

for required in \
  'agent: station' \
  'BBQ_STATION_BRANCH:' \
  'BBQ_STATION_RESULT:'; do
  if ! rg --fixed-strings --quiet -- "$required" "$station_command"; then
    printf 'Missing station command contract %s\n' "$required" >&2
    exit 1
  fi
done

for config in opencode.github-pat.json opencode.github-app.json; do
  config_file="$repo_root/packages/opencode/$config"
  if [ "$(jq --raw-output '.agent.station.model // empty' "$config_file")" != "" ]; then
    printf 'Station agent pins a model in %s\n' "$config_file" >&2
    exit 1
  fi
done

if rg --fixed-strings --quiet 'base_ref="$(git -C "$repo_root" branch --show-current)"' "$repo_root/packages/opencode/bbq-orchestrate.sh"; then
  printf '%s\n' 'Herdr base resolution falls back to the current branch' >&2
  exit 1
fi

printf '%s\n' 'PASS: worktree provider contract'
