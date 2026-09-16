#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
opencode_root="$repo_root/packages/opencode/.opencode"
fire_command="$opencode_root/commands/bbq.fire.md"
taste_command="$opencode_root/commands/bbq.taste.md"
progress_skill="$opencode_root/skills/progress-doc/SKILL.md"
commit_skill="$opencode_root/skills/git-commit/SKILL.md"
reviewer_prompt="$opencode_root/prompts/health-inspector.txt"
pitmaster_prompt="$opencode_root/prompts/pitmaster.txt"
compaction_prompt="$opencode_root/prompts/compaction.txt"
package_readme="$repo_root/packages/opencode/README.md"
state_ignore_script="$opencode_root/scripts/ensure-workflow-state-ignore.sh"

require_text() {
  local file="$1"
  local text="$2"

  if ! rg --fixed-strings --quiet -- "$text" "$file"; then
    printf 'Missing workflow commit contract %s in %s\n' "$text" "$file" >&2
    exit 1
  fi
}

forbid_text() {
  local file="$1"
  local text="$2"

  if rg --fixed-strings --quiet -- "$text" "$file"; then
    printf 'Obsolete workflow commit contract %s remains in %s\n' "$text" "$file" >&2
    exit 1
  fi
}

require_text "$opencode_root/.gitignore" '.bbq-state/'
require_text "$progress_skill" '.opencode/.bbq-state/{branch-name}.md'
require_text "$progress_skill" 'Never stage or commit workflow state.'
forbid_text "$progress_skill" 'docs/progress/{branch-name}.md'
forbid_text "$progress_skill" 'Commit learnings if any'
forbid_text "$progress_skill" 'Commit progress doc update'

require_text "$fire_command" 'Stage the complete candidate change'
require_text "$fire_command" 'ensure-workflow-state-ignore.sh'
require_text "$fire_command" 'git write-tree'
require_text "$fire_command" 'Commit only after the Implementation Review Gate passes'
require_text "$fire_command" 'Mark the ignored workflow state complete'
forbid_text "$fire_command" 'commit changes as you go'
forbid_text "$fire_command" 'Commit any new learnings'
forbid_text "$fire_command" 'Commit this update'
forbid_text "$fire_command" 'progress document'

require_text "$reviewer_prompt" 'git -C "<worktree_path>" diff --cached --check'
require_text "$reviewer_prompt" 'git -C "<worktree_path>" diff --cached --stat'
require_text "$reviewer_prompt" 'git -C "<worktree_path>" diff --cached'
require_text "$reviewer_prompt" 'unstaged or untracked implementation files'

require_text "$taste_command" 'Create one commit for the coherent review pass'
require_text "$taste_command" 'ensure-workflow-state-ignore.sh'
require_text "$taste_command" 'Start a fresh review-pass checklist'
require_text "$taste_command" 'git write-tree'
require_text "$taste_command" 'pre-reviewed staged candidate mode'
forbid_text "$taste_command" 'Create a focused commit addressing that specific comment'
forbid_text "$taste_command" 'Commit learnings if any'
forbid_text "$taste_command" 'progress document'

require_text "$pitmaster_prompt" '.opencode/.bbq-state/'
require_text "$pitmaster_prompt" 'Never stage or commit workflow state.'
forbid_text "$pitmaster_prompt" 'docs/progress/*'
forbid_text "$pitmaster_prompt" 'Commits were made incrementally'

require_text "$compaction_prompt" 'Workflow State: <path|NONE FOUND>'
require_text "$compaction_prompt" 'Resolve or resume the ticket branch and worktree'
forbid_text "$compaction_prompt" 'Progress Doc:'

require_text "$commit_skill" 'Pre-reviewed staged candidate'
require_text "$commit_skill" 'Do not run `git add`'

require_text "$package_readme" 'ignored `.opencode/.bbq-state/`'
require_text "$package_readme" 'ensure-workflow-state-ignore.sh'
forbid_text "$package_readme" 'Track progress in `docs/progress/`'
forbid_text "$package_readme" 'Auto-runs lint/build/test after commits'

if [ ! -f "$state_ignore_script" ]; then
  printf 'Missing workflow state ignore helper %s\n' "$state_ignore_script" >&2
  exit 1
fi

printf '%s\n' 'PASS: workflow commit contract'
