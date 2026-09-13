#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
runner_source="$repo_root/packages/opencode/bbq-orchestrate.sh"
temp_dir="$(mktemp -d)"

cleanup() {
  rm -rf "$temp_dir"
}

trap cleanup EXIT

mkdir -p "$temp_dir/bin" "$temp_dir/target/.opencode" "$temp_dir/runs"
cp "$runner_source" "$temp_dir/target/bbq-orchestrate.sh"
chmod +x "$temp_dir/target/bbq-orchestrate.sh"
printf '%s\n' '{"runtime":"herdr"}' > "$temp_dir/target/.opencode/bbq-config.json"

cat > "$temp_dir/bin/herdr" <<'EOF'
#!/usr/bin/env bash

set -euo pipefail

printf '%s\n' "$*" >> "$HERDR_CALL_LOG"
if [ "${HERDR_STDERR_WARNING:-}" = "1" ] && [ "$1 $2" = "tab create" ]; then
  printf '%s\n' 'Herdr warning: harmless diagnostic' >&2
fi
case "$1 $2" in
  "tab create")
    count=0
    if [ -f "$HERDR_TAB_COUNTER" ]; then count="$(<"$HERDR_TAB_COUNTER")"; fi
    count=$((count + 1))
    printf '%s' "$count" > "$HERDR_TAB_COUNTER"
    printf '{"result":{"root_pane":{"pane_id":"w1:p%s"}}}\n' "$count"
    ;;
  "agent start")
    printf '%s\n' '{"result":{"agent":{"agent_status":"idle"}}}'
    ;;
  "agent prompt")
    if [ "${HERDR_PROMPT_FAIL:-}" = "1" ]; then exit 2; fi
    if [ "${HERDR_BLOCKED:-}" = "1" ] && [[ "$*" == *"/bbq."* ]]; then
      printf '%s\n' '{"result":{"agent":{"agent_status":"blocked"}}}'
    else
      printf '%s\n' '{"result":{"agent":{"agent_status":"done"}}}'
    fi
    ;;
  "agent wait")
    if [ "${HERDR_WAIT_FAIL:-}" = "1" ]; then exit 2; fi
    printf '%s\n' '{"result":{"agent":{"agent_status":"done"}}}'
    ;;
  "agent read")
    if [ "${HERDR_READ_FAIL:-}" = "1" ]; then exit 2; fi
    printf '%s\n' "${HERDR_TRANSCRIPT:-BBQ_PHASE_RESULT: COMPLETE}"
    ;;
  *)
    printf 'Unexpected Herdr invocation: %s\n' "$*" >&2
    exit 2
    ;;
esac
EOF

cat > "$temp_dir/bin/sleep" <<'EOF'
#!/usr/bin/env bash

set -euo pipefail

printf 'sleep %s\n' "$*" >> "$HERDR_CALL_LOG"
EOF

chmod +x "$temp_dir/bin/herdr" "$temp_dir/bin/sleep"

run_herdr() {
  local test_run_root="${BBQ_TEST_RUN_ROOT:-$temp_dir/runs}"

  HERDR_CALL_LOG="$temp_dir/calls" \
  HERDR_TAB_COUNTER="$temp_dir/tab-counter" \
  PATH="$temp_dir/bin:$PATH" \
  HERDR_ENV=1 \
  HERDR_WORKSPACE_ID=workspace-1 \
  BBQ_ORCHESTRATE_RUN_ROOT="$test_run_root" \
    "$temp_dir/target/bbq-orchestrate.sh" "$@"
}

run_herdr STU-15 "focus on performance" > "$temp_dir/output"

if [ "$(rg --count '^tab create ' "$temp_dir/calls")" -ne 3 ] || [ "$(rg --count '^agent start ' "$temp_dir/calls")" -ne 3 ]; then
  printf '%s\n' 'Herdr workflow did not create one tab and agent per phase' >&2
  exit 1
fi

for phase in pantry prep fire; do
  if ! rg --fixed-strings --quiet "/bbq.$phase STU-15 focus on performance --wait" "$temp_dir/calls"; then
    printf 'Herdr did not prompt the %s command with context\n' "$phase" >&2
    exit 1
  fi
done

if [ "$(rg --count '^agent prompt ' "$temp_dir/calls")" -ne 3 ] || [ "$(rg --count '^sleep 3$' "$temp_dir/calls")" -ne 3 ]; then
  printf '%s\n' 'Herdr workflow did not wait for OpenCode command discovery before every phase prompt' >&2
  exit 1
fi

if ! rg --fixed-strings --quiet -- '--kind opencode --pane w1:p1 -- ' "$temp_dir/calls"; then
  printf '%s\n' 'Herdr agent start did not receive the required kind, pane, and repository separator' >&2
  exit 1
fi

if ! rg --fixed-strings --quiet -- '--no-focus' "$temp_dir/calls"; then
  printf '%s\n' 'Herdr tabs were not created without focus' >&2
  exit 1
fi

if [ "$(rg --files "$temp_dir/runs" -g '*.log' | wc -l | tr -d ' ')" -lt 3 ] || [ "$(rg --files "$temp_dir/runs" -g '*.text' | wc -l | tr -d ' ')" -lt 3 ]; then
  printf '%s\n' 'Herdr responses and transcripts were not retained in run logs' >&2
  exit 1
fi

rm -f "$temp_dir/calls" "$temp_dir/tab-counter"
run_herdr --start-phase prep STU-15 > /dev/null
if [ "$(rg --count '^agent start ' "$temp_dir/calls")" -ne 2 ] || rg --fixed-strings --quiet '/bbq.pantry ' "$temp_dir/calls"; then
  printf '%s\n' 'Starting at prep did not run only prep and fire' >&2
  exit 1
fi

rm -f "$temp_dir/calls" "$temp_dir/tab-counter"
run_herdr --start-phase fire STU-15 > /dev/null
if [ "$(rg --count '^agent start ' "$temp_dir/calls")" -ne 1 ] || ! rg --fixed-strings --quiet '/bbq.fire STU-15' "$temp_dir/calls"; then
  printf '%s\n' 'Starting at fire did not run only fire' >&2
  exit 1
fi

rm -f "$temp_dir/calls" "$temp_dir/tab-counter"
HERDR_BLOCKED=1 run_herdr --start-phase fire STU-15 > "$temp_dir/blocked-output"
if ! rg --fixed-strings --quiet 'agent wait ' "$temp_dir/calls" || ! rg --fixed-strings --quiet -- '--until idle --until done' "$temp_dir/calls"; then
  printf '%s\n' 'Blocked Herdr agent was not waited for correctly' >&2
  exit 1
fi
if ! rg --fixed-strings --quiet 'herdr agent attach ' "$temp_dir/blocked-output"; then
  printf '%s\n' 'Blocked Herdr agent did not expose an attach command' >&2
  exit 1
fi

rm -f "$temp_dir/calls" "$temp_dir/tab-counter"
run_herdr --start-phase fire STU-15 > "$temp_dir/first-run-output"
run_herdr --start-phase fire STU-15 > "$temp_dir/second-run-output"
first_name="$(rg -o 'bbq-[a-z0-9_-]+' "$temp_dir/first-run-output" | sort -u)"
second_name="$(rg -o 'bbq-[a-z0-9_-]+' "$temp_dir/second-run-output" | sort -u)"
if ! [[ "$first_name" =~ ^[a-z][a-z0-9_-]{0,31}$ ]] || [ "$first_name" = "$second_name" ]; then
  printf '%s\n' 'Herdr agent names were invalid or reused across runs' >&2
  exit 1
fi

rm -f "$temp_dir/calls" "$temp_dir/tab-counter"
HERDR_TRANSCRIPT='      BBQ_PHASE_RESULT: COMPLETE    ' run_herdr --start-phase fire STU-15 > /dev/null

rm -f "$temp_dir/calls" "$temp_dir/tab-counter"
if HERDR_TRANSCRIPT=$'BBQ_PHASE_RESULT: COMPLETE\nBBQ_PHASE_RESULT: FAILED' run_herdr --start-phase fire STU-15 > /dev/null 2>&1; then
  printf '%s\n' 'Herdr workflow accepted conflicting result markers' >&2
  exit 1
fi

if HERDR_ENV=1 HERDR_WORKSPACE_ID='' PATH="$temp_dir/bin:$PATH" BBQ_ORCHESTRATE_RUN_ROOT="$temp_dir/runs" \
  "$temp_dir/target/bbq-orchestrate.sh" --start-phase fire STU-15 > /dev/null 2> "$temp_dir/missing-workspace-output"; then
  printf '%s\n' 'Herdr workflow accepted a missing workspace ID' >&2
  exit 1
fi
if ! rg --fixed-strings --quiet 'HERDR_WORKSPACE_ID' "$temp_dir/missing-workspace-output"; then
  printf '%s\n' 'Missing Herdr workspace error was not actionable' >&2
  exit 1
fi

rm -f "$temp_dir/calls" "$temp_dir/tab-counter"
HERDR_STDERR_WARNING=1 run_herdr --start-phase fire STU-15 > /dev/null

for failure_case in prompt wait read; do
  failure_runs="$temp_dir/$failure_case-runs"
  rm -f "$temp_dir/calls" "$temp_dir/tab-counter"
  mkdir -p "$failure_runs"
  case "$failure_case" in
    prompt)
      failure_env=(HERDR_PROMPT_FAIL=1 HERDR_TRANSCRIPT='diagnostic transcript')
      ;;
    wait)
      failure_env=(HERDR_BLOCKED=1 HERDR_WAIT_FAIL=1)
      ;;
    read)
      failure_env=(HERDR_READ_FAIL=1)
      ;;
  esac

  if env "${failure_env[@]}" BBQ_TEST_RUN_ROOT="$failure_runs" \
    HERDR_CALL_LOG="$temp_dir/calls" HERDR_TAB_COUNTER="$temp_dir/tab-counter" \
    PATH="$temp_dir/bin:$PATH" HERDR_ENV=1 HERDR_WORKSPACE_ID=workspace-1 \
    BBQ_ORCHESTRATE_RUN_ROOT="$failure_runs" \
    "$temp_dir/target/bbq-orchestrate.sh" STU-15 > "$temp_dir/$failure_case-output" 2>&1; then
    printf 'Herdr %s failure did not stop the workflow\n' "$failure_case" >&2
    exit 1
  fi
  if rg --fixed-strings --quiet '/bbq.prep ' "$temp_dir/calls"; then
    printf 'Herdr %s failure started a later phase\n' "$failure_case" >&2
    exit 1
  fi
  if ! rg --fixed-strings --quiet 'herdr agent attach ' "$temp_dir/$failure_case-output"; then
    printf 'Herdr %s failure did not provide an attach command\n' "$failure_case" >&2
    exit 1
  fi
done

if ! rg --fixed-strings --quiet 'diagnostic transcript' "$temp_dir/prompt-runs" -g 'pantry.log'; then
  printf '%s\n' 'Prompt-failure transcript was not retained in the phase log' >&2
  exit 1
fi

printf '%s\n' 'PASS: Herdr orchestration'
