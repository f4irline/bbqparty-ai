#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
temp_dir="$(mktemp -d)"
trap 'rm -rf "$temp_dir"' EXIT
mkdir -p "$temp_dir/bin" "$temp_dir/target with spaces"
cp "$repo_root/packages/opencode/bbq-orchestrate.sh" "$temp_dir/target with spaces/"
cp "$repo_root/packages/opencode/test/fixtures/opencode-v2.sh" "$temp_dir/bin/opencode"
chmod +x "$temp_dir/bin/opencode"
export PATH="$temp_dir/bin:$PATH"
export OPENCODE_V2_DIRECTORY="$temp_dir/target with spaces"
export BBQ_ORCHESTRATE_RUN_ROOT="$temp_dir/runs"
unset BBQ_OPENCODE_URL BBQ_OPENCODE_PORT OPENCODE_PASSWORD OPENCODE_SERVER_PASSWORD

run_case() {
  export OPENCODE_V2_STATE="$temp_dir/$1"
  shift
  bash "$OPENCODE_V2_DIRECTORY/bbq-orchestrate.sh" "$@"
}

if ! run_case happy STU-15 $'quotes " and backslash \\ and\nnewline' > "$temp_dir/output" 2>&1; then
  cat "$temp_dir/output" >&2
  find "$temp_dir/runs" -name '*.log' -exec cat {} \; >&2
  exit 1
fi
grep -q 'BBQ_WORKFLOW_RESULT: COMPLETE' "$temp_dir/output"
test "$(jq -sr 'map(.name) | join(",")' "$temp_dir/happy/commands")" = 'bbq.pantry,bbq.prep,bbq.fire'
jq -se 'all(.[]; .text == "STU-15 quotes \" and backslash \\ and\nnewline")' "$temp_dir/happy/commands" > /dev/null
test -f "$temp_dir/happy/stopped"
grep -q -- '--server .* --session ses_' "$temp_dir/output"
if grep -q 'fixture-generated-password' "$temp_dir/output"; then
  printf '%s\n' 'V2 runner printed the server password' >&2
  exit 1
fi

run_case prep --start-phase prep STU-15 > /dev/null
test "$(jq -sr 'map(.name) | join(",")' "$temp_dir/prep/commands")" = 'bbq.prep,bbq.fire'
OPENCODE_PASSWORD=existing-secret run_case fire --start-phase fire STU-15 > /dev/null
test "$(jq -sr 'map(.name) | join(",")' "$temp_dir/fire/commands")" = 'bbq.fire'

mkdir -p "$temp_dir/external"
printf '%s' existing-secret > "$temp_dir/external/password"
BBQ_OPENCODE_URL=http://127.0.0.1:4096 OPENCODE_PASSWORD=existing-secret \
  run_case external --start-phase fire STU-15 > /dev/null
test ! -e "$temp_dir/external/stopped"
OPENCODE_SERVER_PASSWORD=legacy-secret run_case legacy-password --start-phase fire STU-15 > /dev/null
test "$(cat "$temp_dir/legacy-password/password")" = legacy-secret

for failure in create command wait messages malformed outcome; do
  if OPENCODE_V2_FAILURE="$failure" run_case "$failure" STU-15 > "$temp_dir/failure-output" 2>&1; then
    printf 'V2 runner accepted %s failure\n' "$failure" >&2
    exit 1
  fi
  grep -q 'BBQ_WORKFLOW_RESULT: FAILED' "$temp_dir/failure-output"
  test -f "$temp_dir/$failure/stopped"
  if [ -f "$temp_dir/$failure/commands" ]; then
    test "$(wc -l < "$temp_dir/$failure/commands" | tr -d ' ')" -eq 1
  fi
done

for text in 'BBQ_PHASE_RESULT: BLOCKED' 'BBQ_PHASE_RESULT: FAILED' 'notes BBQ_PHASE_RESULT: COMPLETE' $'BBQ_PHASE_RESULT: COMPLETE\nBBQ_PHASE_RESULT: FAILED'; do
  if OPENCODE_V2_TEXT="$text" run_case markers --start-phase fire STU-15 > /dev/null 2>&1; then
    printf 'V2 runner accepted invalid result: %s\n' "$text" >&2
    exit 1
  fi
done

printf '%s\n' 'PASS: OpenCode V2 orchestration'
