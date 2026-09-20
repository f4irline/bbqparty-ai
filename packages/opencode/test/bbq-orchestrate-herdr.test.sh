#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
runner_source="$repo_root/packages/opencode/bbq-orchestrate.sh"
opencode_source="$repo_root/packages/opencode/.opencode"
temp_dir="$(mktemp -d)"

cleanup() {
  rm -rf "$temp_dir"
}

trap cleanup EXIT

mkdir -p "$temp_dir/bin" "$temp_dir/target" "$temp_dir/runs"
git -C "$temp_dir/target" init --initial-branch=main --quiet
git -C "$temp_dir/target" config user.name "BBQ Test"
git -C "$temp_dir/target" config user.email "bbq-test@example.com"
printf '%s\n' '# Test repository' > "$temp_dir/target/README.md"
git -C "$temp_dir/target" add README.md
git -C "$temp_dir/target" commit --quiet -m "test fixture"
mkdir -p "$temp_dir/target/.opencode"
cp "$runner_source" "$temp_dir/target/bbq-orchestrate.sh"
cp -R "$opencode_source/." "$temp_dir/target/.opencode/"
printf '%s\n' '{"$schema":"https://opencode.ai/config.json"}' > "$temp_dir/target/opencode.json"
printf '%s\n' 'Test house rules' > "$temp_dir/target/.opencode/HOUSE_RULES.md"
chmod +x "$temp_dir/target/bbq-orchestrate.sh"
printf '%s\n' '{"runtime":"herdr"}' > "$temp_dir/target/.opencode/bbq-config.json"

cat > "$temp_dir/bin/opencode" <<'EOF'
#!/usr/bin/env bash

set -euo pipefail

printf '%s\n' "$*" >> "$OPENCODE_CALL_LOG"
printf 'station-env|%s|%s|%s\n' "${OPENCODE_CONFIG:-}" "${OPENCODE_CONFIG_DIR:-}" "${OPENCODE_CONFIG_CONTENT:-}" >> "$OPENCODE_CALL_LOG"
if [ "${OPENCODE_STATION_FAIL:-}" = "1" ]; then
  printf '%s\n' 'BBQ_STATION_RESULT: FAILED'
  exit 0
fi
if [ "${OPENCODE_STATION_INVALID_BRANCH:-}" = "1" ]; then
  printf '%s\n' 'BBQ_STATION_BRANCH: invalid branch'
else
  printf '%s\n' 'BBQ_STATION_BRANCH: chore/STU-15-herdr-session-placement'
fi
printf '%s\n' 'BBQ_STATION_RESULT: COMPLETE'
EOF

cat > "$temp_dir/bin/herdr" <<'EOF'
#!/usr/bin/env bash

set -euo pipefail

printf '%s\n' "$*" >> "$HERDR_CALL_LOG"
if [ "${HERDR_STDERR_WARNING:-}" = "1" ] && [ "$1 $2" = "tab create" ]; then
  printf '%s\n' 'Herdr warning: harmless diagnostic' >&2
fi
case "$1 $2" in
  "worktree list")
    if [ "${HERDR_WORKTREE_LIST_MODE:-}" = "closed" ]; then
      printf '{"result":{"worktrees":[{"branch":"chore/STU-15-herdr-session-placement","path":"%s"}]}}\n' "$HERDR_WORKTREE_PATH"
    elif [ "${HERDR_WORKTREE_LIST_MODE:-}" = "wrong-path" ]; then
      printf '{"result":{"worktrees":[{"branch":"chore/STU-15-herdr-session-placement","path":"%s","open_workspace_id":"ticket-workspace"}]}}\n' "$HERDR_SOURCE_PATH"
    elif [ -f "$HERDR_WORKTREE_STATE" ]; then
      worktree_path="$(<"$HERDR_WORKTREE_STATE")"
      printf '{"result":{"worktrees":[{"branch":"chore/STU-15-herdr-session-placement","path":"%s","open_workspace_id":"ticket-workspace"}]}}\n' "$worktree_path"
    else
      printf '%s\n' '{"result":{"worktrees":[]}}'
    fi
    ;;
  "worktree create")
    worktree_path=""
    source_path=""
    branch_name=""
    base_ref=""
    while [ "$#" -gt 0 ]; do
      case "$1" in
        --cwd) source_path="$2"; shift 2 ;;
        --branch) branch_name="$2"; shift 2 ;;
        --base) base_ref="$2"; shift 2 ;;
        --path) worktree_path="$2"; shift 2 ;;
        *) shift ;;
      esac
    done
    if [ -z "$source_path" ] || [ -z "$branch_name" ] || [ -z "$base_ref" ] || [ -z "$worktree_path" ]; then
      printf '%s\n' 'Missing worktree creation argument' >&2
      exit 2
    fi
    git -C "$source_path" worktree add --quiet -b "$branch_name" "$worktree_path" "$base_ref"
    printf '%s' "$worktree_path" > "$HERDR_WORKTREE_STATE"
    printf '{"result":{"worktree":{"path":"%s"},"workspace":{"workspace_id":"ticket-workspace"}}}\n' "$worktree_path"
    ;;
  "worktree open")
    printf '%s' "$HERDR_WORKTREE_PATH" > "$HERDR_WORKTREE_STATE"
    printf '{"result":{"worktree":{"path":"%s"},"workspace":{"workspace_id":"ticket-workspace"}}}\n' "$HERDR_WORKTREE_PATH"
    ;;
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

cat > "$temp_dir/bin/mv" <<'EOF'
#!/usr/bin/env bash

set -euo pipefail

if [ "${BBQ_TEST_MV_FAIL:-}" = "1" ]; then exit 1; fi
exec /bin/mv "$@"
EOF

chmod +x "$temp_dir/bin/opencode" "$temp_dir/bin/herdr" "$temp_dir/bin/sleep" "$temp_dir/bin/mv"

run_herdr() {
  local test_run_root="${BBQ_TEST_RUN_ROOT:-$temp_dir/runs}"
  local worktree_path="$temp_dir/target/.opencode/.bbq-worktrees/chore-STU-15-herdr-session-placement"

  OPENCODE_CALL_LOG="$temp_dir/opencode-calls" \
  HERDR_CALL_LOG="$temp_dir/calls" \
  HERDR_TAB_COUNTER="$temp_dir/tab-counter" \
  HERDR_WORKTREE_STATE="$temp_dir/worktree-state" \
  HERDR_WORKTREE_PATH="$worktree_path" \
  HERDR_SOURCE_PATH="$temp_dir/target" \
  PATH="$temp_dir/bin:$PATH" \
  HERDR_ENV=1 \
  HERDR_WORKSPACE_ID=workspace-1 \
  BBQ_ORCHESTRATE_RUN_ROOT="$test_run_root" \
    "$temp_dir/target/bbq-orchestrate.sh" "$@"
}

run_herdr STU-15 "focus on performance" > "$temp_dir/output"

if ! rg --fixed-strings --quiet "run --command bbq.station --dir $temp_dir/target STU-15 focus on performance" "$temp_dir/opencode-calls"; then
  printf '%s\n' 'Herdr workflow did not run the station preflight through its dedicated command' >&2
  exit 1
fi

if [ "$(rg --count '^worktree create ' "$temp_dir/calls")" -ne 1 ]; then
  printf '%s\n' 'Herdr workflow did not create the ticket worktree before phase agents' >&2
  exit 1
fi

worktree_path="$temp_dir/target/.opencode/.bbq-worktrees/chore-STU-15-herdr-session-placement"
runtime_dir="$worktree_path/.opencode/.bbq-runtime"
runtime_house_rules="$worktree_path/.opencode/.bbq-runtime/HOUSE_RULES.md"
if [ -e "$worktree_path/.opencode/commands/bbq.fire.md" ]; then
  printf '%s\n' 'Herdr test fixture unexpectedly committed installed OpenCode configuration' >&2
  exit 1
fi
if [ "$(<"$runtime_house_rules")" != "Test house rules" ] || ! git -C "$worktree_path" check-ignore --quiet .opencode/.bbq-runtime/HOUSE_RULES.md; then
  printf '%s\n' 'Herdr workflow did not prepare ignored worktree-local House Rules' >&2
  exit 1
fi

if ! rg --fixed-strings --quiet "tab create --workspace ticket-workspace --cwd $worktree_path" "$temp_dir/calls"; then
  printf 'Herdr phase tabs were not created in the ticket worktree workspace:\n%s\n%s\n' "$(<"$temp_dir/calls")" "$(<"$temp_dir/output")" >&2
  exit 1
fi
if ! rg --fixed-strings --quiet -- "-- $worktree_path" "$temp_dir/calls"; then
  printf '%s\n' 'Herdr phase agents were not started from the ticket worktree path' >&2
  exit 1
fi

if [ "$(rg --count '^tab create ' "$temp_dir/calls")" -ne 3 ] || [ "$(rg --count '^agent start ' "$temp_dir/calls")" -ne 3 ]; then
  printf '%s\n' 'Herdr workflow did not create one tab and agent per phase' >&2
  exit 1
fi

for phase in pantry prep fire; do
  if ! rg --fixed-strings --quiet "/bbq.$phase STU-15 focus on performance [BBQ_WORKTREE_PATH=$worktree_path] [BBQ_HOUSE_RULES_PATH=$runtime_house_rules] --wait" "$temp_dir/calls"; then
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

if ! rg --fixed-strings --quiet -- "--env BBQ_WORKFLOW_ROOT=$temp_dir/target" "$temp_dir/calls" || \
  ! rg --fixed-strings --quiet -- "--env BBQ_WORKTREE_PATH=$worktree_path" "$temp_dir/calls" || \
  ! rg --fixed-strings --quiet -- '--env BBQ_BRANCH_NAME=chore/STU-15-herdr-session-placement' "$temp_dir/calls" || \
  ! rg --fixed-strings --quiet -- "--env OPENCODE_CONFIG=$temp_dir/target/opencode.json" "$temp_dir/calls" || \
  ! rg --fixed-strings --quiet -- "--env OPENCODE_CONFIG_DIR=$temp_dir/target/.opencode" "$temp_dir/calls" || \
  ! rg --fixed-strings --quiet -- '--env OPENCODE_CONFIG_CONTENT=' "$temp_dir/calls"; then
  printf '%s\n' 'Herdr phase tabs did not receive the pre-resolved worktree context' >&2
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

printf '%s\n' 'previous runtime rules' > "$runtime_house_rules"
rm -f "$temp_dir/calls" "$temp_dir/tab-counter"
if BBQ_TEST_MV_FAIL=1 run_herdr --start-phase fire STU-15 > "$temp_dir/runtime-atomic-output" 2>&1; then
  printf '%s\n' 'Herdr workflow accepted a failed atomic runtime install' >&2
  exit 1
fi
if [ "$(<"$runtime_house_rules")" != "previous runtime rules" ] || rg --quiet '^tab create ' "$temp_dir/calls"; then
  printf '%s\n' 'Failed atomic runtime install replaced prior rules or reached phase startup' >&2
  exit 1
fi

runtime_victim="$temp_dir/runtime-victim"
printf '%s\n' 'do not overwrite' > "$runtime_victim"
rm -f "$runtime_house_rules"
ln -s "$runtime_victim" "$runtime_house_rules"
rm -f "$temp_dir/calls" "$temp_dir/tab-counter"
if run_herdr --start-phase fire STU-15 > "$temp_dir/runtime-symlink-output" 2>&1; then
  printf '%s\n' 'Herdr workflow accepted a symlinked runtime House Rules target' >&2
  exit 1
fi
if [ "$(<"$runtime_victim")" != "do not overwrite" ] || rg --quiet '^tab create ' "$temp_dir/calls"; then
  printf '%s\n' 'Symlinked runtime target was modified or reached phase startup' >&2
  exit 1
fi
rm -f "$runtime_house_rules"

runtime_dir_victim="$temp_dir/runtime-dir-victim"
mkdir "$runtime_dir_victim"
rmdir "$runtime_dir"
ln -s "$runtime_dir_victim" "$runtime_dir"
rm -f "$temp_dir/calls" "$temp_dir/tab-counter"
if run_herdr --start-phase fire STU-15 > "$temp_dir/runtime-dir-symlink-output" 2>&1; then
  printf '%s\n' 'Herdr workflow accepted a symlinked runtime directory' >&2
  exit 1
fi
if [ -e "$runtime_dir_victim/HOUSE_RULES.md" ] || rg --quiet '^tab create ' "$temp_dir/calls"; then
  printf '%s\n' 'Symlinked runtime directory was modified or reached phase startup' >&2
  exit 1
fi
rm "$runtime_dir"

opencode_dir_victim="$temp_dir/opencode-dir-victim"
mkdir "$opencode_dir_victim"
mv "$worktree_path/.opencode" "$worktree_path/.opencode-real"
ln -s "$opencode_dir_victim" "$worktree_path/.opencode"
rm -f "$temp_dir/calls" "$temp_dir/tab-counter"
if run_herdr --start-phase fire STU-15 > "$temp_dir/opencode-dir-symlink-output" 2>&1; then
  printf '%s\n' 'Herdr workflow accepted a symlinked .opencode directory' >&2
  exit 1
fi
if [ -e "$opencode_dir_victim/.bbq-runtime/HOUSE_RULES.md" ] || rg --quiet '^tab create ' "$temp_dir/calls"; then
  printf '%s\n' 'Symlinked .opencode directory was modified or reached phase startup' >&2
  exit 1
fi
rm "$worktree_path/.opencode"
mv "$worktree_path/.opencode-real" "$worktree_path/.opencode"

tracked_runtime_dir="$worktree_path/.OpenCode/.bbq-runtime"
mkdir -p "$tracked_runtime_dir"
printf '%s\n' 'tracked runtime file' > "$tracked_runtime_dir/HOUSE_RULES.md"
git -C "$worktree_path" add -f .OpenCode/.bbq-runtime/HOUSE_RULES.md
rm -f "$temp_dir/calls" "$temp_dir/tab-counter"
if run_herdr --start-phase fire STU-15 > "$temp_dir/tracked-runtime-output" 2>&1; then
  printf '%s\n' 'Herdr workflow accepted a tracked runtime path' >&2
  exit 1
fi
if rg --quiet '^tab create ' "$temp_dir/calls"; then
  printf '%s\n' 'Tracked runtime path reached phase startup' >&2
  exit 1
fi
git -C "$worktree_path" rm --cached --quiet -f .OpenCode/.bbq-runtime/HOUSE_RULES.md
rm -rf "$tracked_runtime_dir"

rm -f "$temp_dir/calls" "$temp_dir/tab-counter"
HERDR_WORKTREE_LIST_MODE=closed run_herdr --start-phase fire STU-15 > /dev/null
if [ "$(rg --count '^worktree open ' "$temp_dir/calls")" -ne 1 ] || rg --quiet '^worktree create ' "$temp_dir/calls"; then
  printf '%s\n' 'Herdr workflow did not open an existing closed worktree workspace' >&2
  exit 1
fi

rm -f "$temp_dir/calls" "$temp_dir/tab-counter"
if OPENCODE_STATION_INVALID_BRANCH=1 run_herdr --start-phase fire STU-15 > "$temp_dir/invalid-station-output" 2>&1; then
  printf '%s\n' 'Herdr workflow accepted an invalid station branch' >&2
  exit 1
fi
if [ -e "$temp_dir/calls" ] || ! rg --fixed-strings --quiet 'Station returned an invalid branch' "$temp_dir/invalid-station-output"; then
  printf '%s\n' 'Invalid station output did not fail before Herdr worktree operations' >&2
  exit 1
fi

rm -f "$temp_dir/calls" "$temp_dir/tab-counter"
if HERDR_WORKTREE_LIST_MODE=wrong-path run_herdr --start-phase fire STU-15 > "$temp_dir/wrong-worktree-output" 2>&1; then
  printf '%s\n' 'Herdr workflow accepted a ticket branch outside its deterministic worktree path' >&2
  exit 1
fi
if rg --quiet '^tab create ' "$temp_dir/calls" || ! rg --fixed-strings --quiet 'expected path' "$temp_dir/wrong-worktree-output"; then
  printf '%s\n' 'Wrong Herdr worktree path did not fail before phase creation' >&2
  exit 1
fi

rm -f "$temp_dir/calls" "$temp_dir/tab-counter"
run_herdr --start-phase fire stu-15 > /dev/null

rm -f "$temp_dir/calls" "$temp_dir/tab-counter"
OPENCODE_CONFIG="$temp_dir/override.json" OPENCODE_CONFIG_DIR="$temp_dir/override-config" OPENCODE_CONFIG_CONTENT='{"agent":{"station":{"disable":true}}}' run_herdr --start-phase fire STU-15 > /dev/null
if ! rg --fixed-strings --quiet -- "--env OPENCODE_CONFIG=$temp_dir/target/opencode.json" "$temp_dir/calls" || \
  ! rg --fixed-strings --quiet -- "--env OPENCODE_CONFIG_DIR=$temp_dir/target/.opencode" "$temp_dir/calls" || \
  ! rg --fixed-strings --quiet -- '--env OPENCODE_CONFIG_CONTENT=' "$temp_dir/calls" || \
  ! rg --fixed-strings --quiet -- "station-env|$temp_dir/target/opencode.json|$temp_dir/target/.opencode|" "$temp_dir/opencode-calls" || \
  rg --fixed-strings --quiet -- "$temp_dir/override" "$temp_dir/calls" || \
  rg --fixed-strings --quiet -- "$temp_dir/override" "$temp_dir/opencode-calls" || \
  rg --fixed-strings --quiet -- '"disable":true' "$temp_dir/opencode-calls"; then
  printf '%s\n' 'Inherited OpenCode overrides hid the source project configuration' >&2
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
first_name="$(rg '^Starting fire ' "$temp_dir/first-run-output" | rg -o 'bbq-[a-z0-9_-]+' | sort -u)"
second_name="$(rg '^Starting fire ' "$temp_dir/second-run-output" | rg -o 'bbq-[a-z0-9_-]+' | sort -u)"
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
    OPENCODE_CALL_LOG="$temp_dir/opencode-calls" \
    HERDR_CALL_LOG="$temp_dir/calls" HERDR_TAB_COUNTER="$temp_dir/tab-counter" \
    HERDR_WORKTREE_STATE="$temp_dir/worktree-state" HERDR_WORKTREE_PATH="$worktree_path" \
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
