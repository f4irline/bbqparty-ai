#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
runner="$repo_root/packages/opencode/bbq-orchestrate.sh"
target_root="$repo_root/packages/opencode"
temp_dir="$(mktemp -d)"
server_url="http://127.0.0.1:48291"

cleanup() {
  rm -rf "$temp_dir"
}

trap cleanup EXIT

mkdir -p "$temp_dir/bin" "$temp_dir/runs"

cat > "$temp_dir/bin/opencode" <<'EOF'
#!/usr/bin/env bash

set -euo pipefail

case "$1" in
  serve)
    if [ "$#" -ne 5 ] || [ "$2" != "--hostname" ] || [ "$3" != "127.0.0.1" ] || [ "$4" != "--port" ] || [ "$5" != "$OPENCODE_PORT_EXPECTED" ]; then
      printf 'Unexpected serve invocation: %s\n' "$*" >&2
      exit 2
    fi
    printf 'serve|%s|%s|%s|%s\n' "$2" "$3" "$4" "$5" >> "$OPENCODE_CALL_LOG"
    if [ "${OPENCODE_SERVE_FAIL:-}" = "1" ]; then
      printf '%s\n' "OpenCode server failed" >&2
      exit 2
    fi
    printf '%s\n' "opencode server listening on ${OPENCODE_SERVER_URL:-http://127.0.0.1:48291}"
    trap 'printf "%s\n" "stopped" >> "$OPENCODE_SERVER_STOP_LOG"; exit 0' TERM
    while :; do
      sleep 1
    done
    ;;
  *)
    printf 'Unexpected OpenCode invocation: %s\n' "$*" >&2
    exit 2
    ;;
esac
EOF

cat > "$temp_dir/bin/curl" <<'EOF'
#!/usr/bin/env bash

set -euo pipefail

body=""
config=""
for ((index = 1; index <= $#; index++)); do
  if [ "${!index}" = "--data" ]; then
    next_index=$((index + 1))
    body="${!next_index}"
  fi
  if [ "${!index}" = "--config" ]; then
    next_index=$((index + 1))
    if [ "${!next_index}" = "-" ]; then
      config="$(cat)"
    fi
  fi
done

if [ "${OPENCODE_REQUIRE_AUTH:-}" = "1" ] && [[ "$config" != *'user = "opencode:barbecue"'* ]]; then
  printf 'Missing expected Basic Auth credentials\n' >&2
  exit 2
fi

url="${!#}"

case "$url" in
  */session)
    if [ "${OPENCODE_SESSION_FAIL:-}" = "1" ]; then
      printf '%s\n' "Session creation failed" >&2
      exit 2
    fi
    count=0
    if [ -f "$OPENCODE_SESSION_COUNTER" ]; then
      count="$(<"$OPENCODE_SESSION_COUNTER")"
    fi
    count=$((count + 1))
    printf '%s' "$count" > "$OPENCODE_SESSION_COUNTER"
    phase=(pantry prep fire)
    session_id="ses_${phase[$((count - 1))]}"
    printf 'create|%s|%s\n' "$url" "$body" >> "$OPENCODE_CURL_CALL_LOG"
    if [ "${OPENCODE_NESTED_ID:-}" = "1" ]; then
      printf '{"metadata":{"id":"invalid"},"id":"%s"}\n' "$session_id"
    else
      printf '{"id":"%s"}\n' "$session_id"
    fi
    ;;
  */command)
    if [ "${OPENCODE_REQUIRE_SESSION_ID:-}" = "1" ] && [[ "$url" != */session/ses_*/command ]]; then
      printf 'Unexpected session command URL: %s\n' "$url" >&2
      exit 2
    fi
    printf 'command|%s|%s\n' "$url" "$body" >> "$OPENCODE_CURL_CALL_LOG"
    if [ "${OPENCODE_COMMAND_FAIL:-}" = "1" ]; then
      printf '%s\n' "Command failed" >&2
      exit 2
    elif [ "${OPENCODE_DUPLICATE_MARKERS:-}" = "1" ]; then
      printf '%s\n' '{"parts":[{"type":"text","text":"BBQ_PHASE_RESULT: COMPLETE"},{"type":"text","text":"BBQ_PHASE_RESULT: BLOCKED"}]}'
    elif [ "${OPENCODE_PREFIXED_MARKER:-}" = "1" ]; then
      printf '%s\n' '{"parts":[{"type":"text","text":"Phase notes\nBBQ_PHASE_RESULT: COMPLETE"}]}'
    elif [ "${OPENCODE_INLINE_MARKER:-}" = "1" ]; then
      printf '%s\n' '{"parts":[{"type":"text","text":"Phase notes BBQ_PHASE_RESULT: COMPLETE"}]}'
    elif [ "${OPENCODE_MULTIPART_INLINE_MARKER:-}" = "1" ]; then
      printf '%s\n' '{"parts":[{"type":"text","text":"Phase notes "},{"type":"text","text":"BBQ_PHASE_RESULT: COMPLETE"}]}'
    else
      printf '%s\n' '{"parts":[{"type":"text","text":"BBQ_PHASE_RESULT: COMPLETE"}]}'
    fi
    ;;
  *)
    printf 'Unexpected curl invocation: %s\n' "$*" >&2
    exit 2
    ;;
esac
EOF

chmod +x "$temp_dir/bin/opencode"
chmod +x "$temp_dir/bin/curl"

OPENCODE_CALL_LOG="$temp_dir/calls" \
OPENCODE_CURL_CALL_LOG="$temp_dir/curl-calls" \
OPENCODE_SERVER_STOP_LOG="$temp_dir/server-stop" \
OPENCODE_SESSION_COUNTER="$temp_dir/session-counter" \
OPENCODE_PORT_EXPECTED=48123 \
PATH="$temp_dir/bin:$PATH" \
BBQ_OPENCODE_PORT=48123 \
BBQ_ORCHESTRATE_RUN_ROOT="$temp_dir/runs" \
  "$runner" STU-15 "focus on performance" > "$temp_dir/output"

output="$(<"$temp_dir/output")"

actual_calls="$(<"$temp_dir/calls")"
expected_calls="serve|--hostname|127.0.0.1|--port|48123"

if [ "$actual_calls" != "$expected_calls" ]; then
  printf 'Unexpected OpenCode calls:\n%s\n' "$actual_calls" >&2
  exit 1
fi

actual_curl_calls="$(<"$temp_dir/curl-calls")"
expected_curl_calls="create|$server_url/session|{}"
for phase in pantry prep fire; do
  expected_curl_calls+=$'\n'
  expected_curl_calls+="command|$server_url/session/ses_$phase/command|{\"command\":\"bbq.$phase\",\"arguments\":\"STU-15 focus on performance\"}"
  if [ "$phase" != "fire" ]; then
    expected_curl_calls+=$'\n'
    expected_curl_calls+="create|$server_url/session|{}"
  fi
done

rm -f "$temp_dir/server-stop" "$temp_dir/session-counter"

OPENCODE_CALL_LOG="$temp_dir/prefixed-calls" \
OPENCODE_CURL_CALL_LOG="$temp_dir/prefixed-curl-calls" \
OPENCODE_PREFIXED_MARKER=1 \
OPENCODE_SERVER_STOP_LOG="$temp_dir/server-stop" \
OPENCODE_SESSION_COUNTER="$temp_dir/session-counter" \
OPENCODE_PORT_EXPECTED=48123 \
PATH="$temp_dir/bin:$PATH" \
BBQ_OPENCODE_PORT=48123 \
BBQ_ORCHESTRATE_RUN_ROOT="$temp_dir/runs" \
  "$runner" STU-15 > /dev/null

rm -f "$temp_dir/server-stop" "$temp_dir/session-counter"

OPENCODE_CALL_LOG="$temp_dir/auth-calls" \
OPENCODE_CURL_CALL_LOG="$temp_dir/auth-curl-calls" \
OPENCODE_REQUIRE_AUTH=1 \
OPENCODE_SERVER_PASSWORD=barbecue \
OPENCODE_SERVER_STOP_LOG="$temp_dir/server-stop" \
OPENCODE_SESSION_COUNTER="$temp_dir/session-counter" \
OPENCODE_PORT_EXPECTED=48123 \
PATH="$temp_dir/bin:$PATH" \
BBQ_OPENCODE_PORT=48123 \
BBQ_ORCHESTRATE_RUN_ROOT="$temp_dir/runs" \
  "$runner" STU-15 > /dev/null

rm -f "$temp_dir/server-stop" "$temp_dir/session-counter"

if OPENCODE_CALL_LOG="$temp_dir/duplicate-calls" \
OPENCODE_CURL_CALL_LOG="$temp_dir/duplicate-curl-calls" \
OPENCODE_DUPLICATE_MARKERS=1 \
OPENCODE_SERVER_STOP_LOG="$temp_dir/server-stop" \
OPENCODE_SESSION_COUNTER="$temp_dir/session-counter" \
OPENCODE_PORT_EXPECTED=48123 \
PATH="$temp_dir/bin:$PATH" \
BBQ_OPENCODE_PORT=48123 \
BBQ_ORCHESTRATE_RUN_ROOT="$temp_dir/runs" \
  "$runner" STU-15 > /dev/null 2>&1; then
  printf '%s\n' "Runner accepted conflicting phase result markers" >&2
  exit 1
fi

rm -f "$temp_dir/server-stop" "$temp_dir/session-counter"

if OPENCODE_CALL_LOG="$temp_dir/inline-calls" \
OPENCODE_CURL_CALL_LOG="$temp_dir/inline-curl-calls" \
OPENCODE_INLINE_MARKER=1 \
OPENCODE_SERVER_STOP_LOG="$temp_dir/server-stop" \
OPENCODE_SESSION_COUNTER="$temp_dir/session-counter" \
OPENCODE_PORT_EXPECTED=48123 \
PATH="$temp_dir/bin:$PATH" \
BBQ_OPENCODE_PORT=48123 \
BBQ_ORCHESTRATE_RUN_ROOT="$temp_dir/runs" \
  "$runner" STU-15 > /dev/null 2>&1; then
  printf '%s\n' "Runner accepted an inline phase result marker" >&2
  exit 1
fi

rm -f "$temp_dir/server-stop" "$temp_dir/session-counter"

if OPENCODE_CALL_LOG="$temp_dir/multipart-calls" \
OPENCODE_CURL_CALL_LOG="$temp_dir/multipart-curl-calls" \
OPENCODE_MULTIPART_INLINE_MARKER=1 \
OPENCODE_SERVER_STOP_LOG="$temp_dir/server-stop" \
OPENCODE_SESSION_COUNTER="$temp_dir/session-counter" \
OPENCODE_PORT_EXPECTED=48123 \
PATH="$temp_dir/bin:$PATH" \
BBQ_OPENCODE_PORT=48123 \
BBQ_ORCHESTRATE_RUN_ROOT="$temp_dir/runs" \
  "$runner" STU-15 > /dev/null 2>&1; then
  printf '%s\n' "Runner accepted a multipart inline phase result marker" >&2
  exit 1
fi

rm -f "$temp_dir/server-stop" "$temp_dir/session-counter"

OPENCODE_CALL_LOG="$temp_dir/session-id-calls" \
OPENCODE_CURL_CALL_LOG="$temp_dir/session-id-curl-calls" \
OPENCODE_NESTED_ID=1 \
OPENCODE_REQUIRE_SESSION_ID=1 \
OPENCODE_SERVER_STOP_LOG="$temp_dir/server-stop" \
OPENCODE_SESSION_COUNTER="$temp_dir/session-counter" \
OPENCODE_PORT_EXPECTED=48123 \
PATH="$temp_dir/bin:$PATH" \
BBQ_OPENCODE_PORT=48123 \
BBQ_ORCHESTRATE_RUN_ROOT="$temp_dir/runs" \
  "$runner" STU-15 > /dev/null

if OPENCODE_CALL_LOG="$temp_dir/external-calls" \
OPENCODE_CURL_CALL_LOG="$temp_dir/external-curl-calls" \
OPENCODE_SERVER_STOP_LOG="$temp_dir/server-stop" \
OPENCODE_SESSION_COUNTER="$temp_dir/session-counter" \
OPENCODE_PORT_EXPECTED=48123 \
PATH="$temp_dir/bin:$PATH" \
BBQ_OPENCODE_URL=http://example.com \
BBQ_ORCHESTRATE_RUN_ROOT="$temp_dir/runs" \
  "$runner" STU-15 > /dev/null 2>&1; then
  printf '%s\n' "Runner accepted a non-loopback OpenCode server URL" >&2
  exit 1
fi

rm -f "$temp_dir/server-stop" "$temp_dir/session-counter"

if OPENCODE_CALL_LOG="$temp_dir/server-url-calls" \
OPENCODE_CURL_CALL_LOG="$temp_dir/server-url-curl-calls" \
OPENCODE_SERVER_URL=http://example.com \
OPENCODE_SERVER_STOP_LOG="$temp_dir/server-stop" \
OPENCODE_SESSION_COUNTER="$temp_dir/session-counter" \
OPENCODE_PORT_EXPECTED=48123 \
PATH="$temp_dir/bin:$PATH" \
BBQ_OPENCODE_PORT=48123 \
BBQ_ORCHESTRATE_RUN_ROOT="$temp_dir/runs" \
  "$runner" STU-15 > /dev/null 2>&1; then
  printf '%s\n' "Runner accepted a non-loopback server listener URL" >&2
  exit 1
fi

rm -f "$temp_dir/server-stop" "$temp_dir/session-counter"

if OPENCODE_CALL_LOG="$temp_dir/server-fail-calls" \
OPENCODE_CURL_CALL_LOG="$temp_dir/server-fail-curl-calls" \
OPENCODE_SERVE_FAIL=1 \
OPENCODE_SERVER_STOP_LOG="$temp_dir/server-stop" \
OPENCODE_SESSION_COUNTER="$temp_dir/session-counter" \
OPENCODE_PORT_EXPECTED=48123 \
PATH="$temp_dir/bin:$PATH" \
BBQ_OPENCODE_PORT=48123 \
BBQ_ORCHESTRATE_RUN_ROOT="$temp_dir/runs" \
  "$runner" STU-15 > /dev/null 2>&1; then
  printf '%s\n' "Runner continued after server startup failure" >&2
  exit 1
fi

rm -f "$temp_dir/server-stop" "$temp_dir/session-counter"

if OPENCODE_CALL_LOG="$temp_dir/session-fail-calls" \
OPENCODE_CURL_CALL_LOG="$temp_dir/session-fail-curl-calls" \
OPENCODE_SESSION_FAIL=1 \
OPENCODE_SERVER_STOP_LOG="$temp_dir/server-stop" \
OPENCODE_SESSION_COUNTER="$temp_dir/session-counter" \
OPENCODE_PORT_EXPECTED=48123 \
PATH="$temp_dir/bin:$PATH" \
BBQ_OPENCODE_PORT=48123 \
BBQ_ORCHESTRATE_RUN_ROOT="$temp_dir/runs" \
  "$runner" STU-15 > /dev/null 2>&1; then
  printf '%s\n' "Runner continued after session creation failure" >&2
  exit 1
fi

if [ -f "$temp_dir/session-fail-curl-calls" ] && rg --quiet '^command\|' "$temp_dir/session-fail-curl-calls"; then
  printf '%s\n' "Runner invoked a command after session creation failure" >&2
  exit 1
fi

rm -f "$temp_dir/server-stop" "$temp_dir/session-counter"

if OPENCODE_CALL_LOG="$temp_dir/command-fail-calls" \
OPENCODE_CURL_CALL_LOG="$temp_dir/command-fail-curl-calls" \
OPENCODE_COMMAND_FAIL=1 \
OPENCODE_SERVER_STOP_LOG="$temp_dir/server-stop" \
OPENCODE_SESSION_COUNTER="$temp_dir/session-counter" \
OPENCODE_PORT_EXPECTED=48123 \
PATH="$temp_dir/bin:$PATH" \
BBQ_OPENCODE_PORT=48123 \
BBQ_ORCHESTRATE_RUN_ROOT="$temp_dir/runs" \
  "$runner" STU-15 > /dev/null 2>&1; then
  printf '%s\n' "Runner continued after command failure" >&2
  exit 1
fi

if rg --quiet 'bbq.prep' "$temp_dir/command-fail-curl-calls"; then
  printf '%s\n' "Runner started a later phase after command failure" >&2
  exit 1
fi

if [ "$actual_curl_calls" != "$expected_curl_calls" ]; then
  printf 'Unexpected curl calls:\n%s\n' "$actual_curl_calls" >&2
  exit 1
fi

if [ "$(<"$temp_dir/server-stop")" != "stopped" ]; then
  printf '%s\n' "Runner did not stop its local OpenCode server" >&2
  exit 1
fi

for phase in pantry prep fire; do
  expected_attach="opencode attach $server_url --session ses_$phase --dir $target_root"
  if [[ "$output" != *"$expected_attach"* ]]; then
    printf 'Missing attach command: %s\n' "$expected_attach" >&2
    exit 1
  fi

  command_file="$target_root/.opencode/commands/bbq.$phase.md"
  if ! rg --fixed-strings --quiet 'Do not emit `BBQ_PHASE_RESULT: BLOCKED` before calling the `question` tool.' "$command_file"; then
    printf 'Missing in-session question guidance: %s\n' "$command_file" >&2
    exit 1
  fi
done
