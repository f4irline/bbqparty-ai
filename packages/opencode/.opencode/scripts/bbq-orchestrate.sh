#!/usr/bin/env bash

set -euo pipefail

usage() {
  printf '%s\n' "Usage: $0 <ticket-id> [additional context]" >&2
}

if [ "$#" -lt 1 ]; then
  usage
  exit 64
fi

ticket_id="$1"
shift

if ! [[ "$ticket_id" =~ ^[A-Za-z][A-Za-z0-9]*-[0-9]+$ ]]; then
  printf 'Invalid ticket ID: %s\n' "$ticket_id" >&2
  exit 64
fi

if ! command -v opencode >/dev/null 2>&1; then
  printf '%s\n' "opencode is required but was not found in PATH" >&2
  exit 127
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
run_root="${BBQ_ORCHESTRATE_RUN_ROOT:-$repo_root/.opencode/.bbq-runs}"
mkdir -p "$run_root"
run_dir="$(mktemp -d "$run_root/${ticket_id}-$(date +%Y%m%d%H%M%S)-XXXXXX")"
additional_context="$*"
command_arguments="$ticket_id"

if [ -n "$additional_context" ]; then
  command_arguments="$command_arguments $additional_context"
fi

run_phase() {
  local phase="$1"
  local command_name="$2"
  local log_file="$run_dir/$phase.log"
  local phase_result=""
  local result_count=0
  local result_line

  printf 'Starting %s for %s\n' "$phase" "$ticket_id"

  if ! (
    cd "$repo_root"
    opencode run --command "$command_name" "$command_arguments"
  ) 2>&1 | tee "$log_file"; then
    printf 'BBQ_WORKFLOW_RESULT: FAILED\n'
    printf 'Stopped at: %s\n' "$phase"
    printf 'Log: %s\n' "$log_file"
    return 1
  fi

  while IFS= read -r result_line; do
    case "$result_line" in
      "BBQ_PHASE_RESULT:"*)
        phase_result="$result_line"
        result_count=$((result_count + 1))
        ;;
    esac
  done < "$log_file"

  if [ "$result_count" -ne 1 ]; then
    printf 'BBQ_WORKFLOW_RESULT: FAILED\n'
    printf '%s\n' "Phase must return exactly one BBQ_PHASE_RESULT marker"
  elif [ "$phase_result" = "BBQ_PHASE_RESULT: COMPLETE" ]; then
    printf 'Completed %s\n' "$phase"
    return 0
  elif [ "$phase_result" = "BBQ_PHASE_RESULT: BLOCKED" ]; then
    printf 'BBQ_WORKFLOW_RESULT: BLOCKED\n'
  else
    printf 'BBQ_WORKFLOW_RESULT: FAILED\n'
  fi

  printf 'Stopped at: %s\n' "$phase"
  printf 'Log: %s\n' "$log_file"
  return 1
}

if ! run_phase "pantry" "bbq.pantry"; then
  exit 1
fi

if ! run_phase "prep" "bbq.prep"; then
  exit 1
fi

if ! run_phase "fire" "bbq.fire"; then
  exit 1
fi

printf 'BBQ_WORKFLOW_RESULT: COMPLETE\n'
printf 'Ticket: %s\n' "$ticket_id"
printf 'Log directory: %s\n' "$run_dir"
