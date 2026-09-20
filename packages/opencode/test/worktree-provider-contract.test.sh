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
  if ! rg --fixed-strings --quiet -- '.opencode/.bbq-runtime/HOUSE_RULES.md' "$command_file"; then
    printf 'Missing worktree-local House Rules contract in %s\n' "$command_file" >&2
    exit 1
  fi
  if ! rg --fixed-strings --quiet -- '[BBQ_HOUSE_RULES_PATH=...]' "$command_file" || \
    ! rg --fixed-strings --quiet -- 'authoritative `house_rules_path`' "$command_file"; then
    printf 'House Rules mode is inferred rather than explicit in %s\n' "$command_file" >&2
    exit 1
  fi
  if ! rg --fixed-strings --quiet -- '[BBQ_WORKTREE_PATH=...]' "$command_file" || \
    ! rg --fixed-strings --quiet -- '`worktree_path` as the only repository root' "$command_file" || \
    ! rg --fixed-strings --quiet -- 'authoritative `worktree_path`' "$command_file"; then
    printf 'Missing explicit worktree boundary in %s\n' "$command_file" >&2
    exit 1
  fi
done
if ! rg --fixed-strings --quiet -- '.opencode/.bbq-runtime/HOUSE_RULES.md' "$opencode_root/prompts/sous-chef.txt"; then
  printf '%s\n' 'Missing worktree-local House Rules contract in sous-chef prompt' >&2
  exit 1
fi
if ! rg --fixed-strings --quiet -- '[BBQ_HOUSE_RULES_PATH=...]' "$opencode_root/prompts/sous-chef.txt" || \
  ! rg --fixed-strings --quiet -- '[BBQ_WORKTREE_PATH=...]' "$opencode_root/prompts/sous-chef.txt" || \
  ! rg --fixed-strings --quiet -- '`worktree_path` as the only repository root' "$opencode_root/prompts/sous-chef.txt"; then
  printf '%s\n' 'Sous-chef lacks explicit Herdr path boundaries' >&2
  exit 1
fi
for config in opencode.github-pat.json opencode.github-app.json; do
  config_file="$repo_root/packages/opencode/$config"
  if [ "$(jq --raw-output '.agent["sous-chef"].tools.bash' "$config_file")" != "false" ]; then
    printf 'Sous-chef unexpectedly has shell access in %s\n' "$config_file" >&2
    exit 1
  fi
done
for file in "$opencode_root/commands/bbq.fire.md" "$opencode_root/prompts/pitmaster.txt"; do
  if ! rg --fixed-strings --quiet -- '.opencode/.bbq-runtime/HOUSE_RULES.md' "$file"; then
    printf 'Missing worktree-local House Rules contract in %s\n' "$file" >&2
    exit 1
  fi
done
for file in "$opencode_root/commands/bbq.fire.md" "$opencode_root/prompts/pitmaster.txt"; do
  if rg --fixed-strings --quiet -- 'git -C "$BBQ_WORKFLOW_ROOT"' "$file" || \
    rg --fixed-strings --quiet -- 'do not require or load a copy from the ticket worktree' "$file"; then
    printf 'Pre-resolved Fire still accesses external House Rules context in %s\n' "$file" >&2
    exit 1
  fi
  if ! rg --fixed-strings --quiet -- 'trust the orchestrator-validated `BBQ_WORKFLOW_ROOT`' "$file"; then
    printf 'Pre-resolved Fire does not trust the orchestrator source-root validation in %s\n' "$file" >&2
    exit 1
  fi
done
if ! rg --fixed-strings --quiet -- 'Read only the authoritative `house_rules_path`' "$opencode_root/prompts/health-inspector.txt" || \
  ! rg --fixed-strings --quiet -- 'authoritative `house_rules_path`' "$opencode_root/commands/bbq.fire.md"; then
  printf '%s\n' 'Fire review does not receive an explicit authoritative House Rules path' >&2
  exit 1
fi
if rg --fixed-strings --quiet -- 'Give it the ticket ID, user context, `workflow_root`, `worktree_path`' "$opencode_root/commands/bbq.fire.md"; then
  printf '%s\n' 'Fire passes the source checkout to health-inspector' >&2
  exit 1
fi
if ! rg --fixed-strings --quiet -- '`worktree_path` is the only repository root' "$opencode_root/prompts/health-inspector.txt" || \
  ! rg --fixed-strings --quiet -- 'Never access `workflow_root`' "$opencode_root/prompts/health-inspector.txt"; then
  printf '%s\n' 'Health-inspector is not confined to the supplied worktree' >&2
  exit 1
fi

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
  if [ "$(jq --raw-output '.agent.station.description' "$config_file")" != "Non-interactive branch resolver for Herdr worktree orchestration" ]; then
    printf 'Baseline station agent description is missing in %s\n' "$config_file" >&2
    exit 1
  fi
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
