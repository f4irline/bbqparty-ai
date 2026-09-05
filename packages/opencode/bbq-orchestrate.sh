#!/usr/bin/env bash

set -euo pipefail

usage() {
  printf '%s\n' "Usage: $0 [--start-phase pantry|prep|fire] <ticket-id> [additional context]" >&2
}

start_phase="pantry"

if [ "${1:-}" = "--start-phase" ]; then
  if [ "$#" -lt 2 ]; then
    printf '%s\n' "Missing value for --start-phase" >&2
    usage
    exit 64
  fi

  start_phase="$2"
  shift 2

  case "$start_phase" in
    pantry|prep|fire)
      ;;
    *)
      printf 'Invalid start phase: %s\n' "$start_phase" >&2
      usage
      exit 64
      ;;
  esac
fi

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

if ! command -v curl >/dev/null 2>&1; then
  printf '%s\n' "curl is required but was not found in PATH" >&2
  exit 127
fi

if ! command -v jq >/dev/null 2>&1; then
  printf '%s\n' "jq is required but was not found in PATH" >&2
  exit 127
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
run_root="${BBQ_ORCHESTRATE_RUN_ROOT:-$repo_root/.opencode/.bbq-runs}"
mkdir -p "$run_root"
run_dir="$(mktemp -d "$run_root/${ticket_id}-$(date +%Y%m%d%H%M%S)-XXXXXX")"
additional_context="$*"
command_arguments="$ticket_id"

if [ -n "$additional_context" ]; then
  command_arguments="$command_arguments $additional_context"
fi

server_url="${BBQ_OPENCODE_URL:-}"
server_pid=""
server_log="$run_dir/opencode-server.log"

cleanup_server() {
  if [ -n "$server_pid" ] && kill -0 "$server_pid" >/dev/null 2>&1; then
    kill "$server_pid" >/dev/null 2>&1 || true
    wait "$server_pid" >/dev/null 2>&1 || true
  fi
}

start_server() {
  local server_line
  local reported_server_url
  local configured_port="${BBQ_OPENCODE_PORT:-}"
  local server_port
  local attempt

  if [ -n "$server_url" ]; then
    if ! [[ "$server_url" =~ ^http://127\.0\.0\.1:[0-9]+$ ]]; then
      printf '%s\n' "BBQ_OPENCODE_URL must be a loopback URL such as http://127.0.0.1:4096" >&2
      return 1
    fi
    printf 'Using OpenCode server: %s\n' "$server_url"
    return 0
  fi

  for attempt in {1..5}; do
    if [ -n "$configured_port" ]; then
      server_port="$configured_port"
    else
      server_port=$((20000 + RANDOM % 20000))
    fi

    : > "$server_log"
    opencode serve --hostname 127.0.0.1 --port "$server_port" > "$server_log" 2>&1 &
    server_pid=$!

    for _ in {1..50}; do
      while IFS= read -r server_line; do
        case "$server_line" in
          "opencode server listening on "*)
            reported_server_url="${server_line#opencode server listening on }"
            if ! [[ "$reported_server_url" =~ ^http://127\.0\.0\.1:[0-9]+$ ]]; then
              kill "$server_pid" >/dev/null 2>&1 || true
              wait "$server_pid" >/dev/null 2>&1 || true
              server_pid=""
              printf '%s\n' "OpenCode server reported a non-loopback URL" >&2
              printf 'Log: %s\n' "$server_log" >&2
              return 1
            fi
            server_url="$reported_server_url"
            printf 'Started OpenCode server: %s\n' "$server_url"
            return 0
            ;;
        esac
      done < "$server_log"

      if ! kill -0 "$server_pid" >/dev/null 2>&1; then
        wait "$server_pid" >/dev/null 2>&1 || true
        server_pid=""
        break
      fi

      sleep 0.1
    done

    if [ -n "$server_pid" ]; then
      kill "$server_pid" >/dev/null 2>&1 || true
      wait "$server_pid" >/dev/null 2>&1 || true
      server_pid=""
      printf '%s\n' "Timed out waiting for the OpenCode server" >&2
      printf 'Log: %s\n' "$server_log" >&2
      return 1
    fi

    if [ -n "$configured_port" ]; then
      printf 'OpenCode server stopped before it became ready on port %s\n' "$configured_port" >&2
      printf 'Log: %s\n' "$server_log" >&2
      return 1
    fi
  done

  printf '%s\n' "Could not start OpenCode server after 5 port attempts" >&2
  printf 'Log: %s\n' "$server_log" >&2
  return 1
}

trap cleanup_server EXIT

json_escape() {
  local value="$1"

  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//$'\n'/\\n}"
  value="${value//$'\r'/\\r}"
  value="${value//$'\t'/\\t}"
  printf '%s' "$value"
}

curl_auth_config() {
  local username="${OPENCODE_SERVER_USERNAME:-opencode}"
  local password="$OPENCODE_SERVER_PASSWORD"

  username="${username//\\/\\\\}"
  username="${username//\"/\\\"}"
  password="${password//\\/\\\\}"
  password="${password//\"/\\\"}"
  password="${password//$'\n'/\\n}"
  password="${password//$'\r'/\\r}"
  printf 'user = "%s:%s"\n' "$username" "$password"
}

curl_request() {
  if [ -n "${OPENCODE_SERVER_PASSWORD:-}" ]; then
    curl_auth_config | curl --config - "$@"
  else
    curl "$@"
  fi
}

run_phase() {
  local phase="$1"
  local command_name="$2"
  local log_file="$run_dir/$phase.log"
  local session_id=""
  local session_response
  local command_response
  local command_payload
  local text_file="$run_dir/$phase.text"
  local result_line
  local -a curl_args=(
    --fail
    --silent
    --show-error
    --request POST
    --header "x-opencode-directory: $repo_root"
    --header "Content-Type: application/json"
  )
  local phase_result=""
  local result_count=0

  printf 'Starting %s for %s\n' "$phase" "$ticket_id"

  if ! session_response="$(curl_request "${curl_args[@]}" --data '{}' "$server_url/session")"; then
    printf 'BBQ_WORKFLOW_RESULT: FAILED\n'
    printf '%s\n' "Failed to create an OpenCode session"
    printf 'Stopped at: %s\n' "$phase"
    return 1
  fi

  printf '%s\n' "$session_response" > "$log_file"

  if ! session_id="$(jq --raw-output --exit-status '.id | strings | select(startswith("ses"))' <<< "$session_response")"; then
    printf 'BBQ_WORKFLOW_RESULT: FAILED\n'
    printf '%s\n' "OpenCode did not return a valid session ID"
    printf 'Stopped at: %s\n' "$phase"
    printf 'Log: %s\n' "$log_file"
    return 1
  fi

  printf 'Phase session: %s\n' "$session_id"
  printf 'Connect in another terminal: opencode attach %q --session %q --dir %q\n' "$server_url" "$session_id" "$repo_root"
  if [ -n "${OPENCODE_SERVER_PASSWORD:-}" ]; then
    printf '%s\n' "Set OPENCODE_SERVER_PASSWORD in the attaching terminal before connecting."
  fi

  command_payload="{\"command\":\"$(json_escape "$command_name")\",\"arguments\":\"$(json_escape "$command_arguments")\"}"

  if ! command_response="$(curl_request "${curl_args[@]}" --data "$command_payload" "$server_url/session/$session_id/command")"; then
    printf 'BBQ_WORKFLOW_RESULT: FAILED\n'
    printf '%s\n' "OpenCode command failed"
    printf 'Stopped at: %s\n' "$phase"
    printf 'Log: %s\n' "$log_file"
    return 1
  fi

  printf '%s\n' "$command_response" >> "$log_file"

  if ! jq --raw-output '[.parts[]? | select(.type == "text") | .text] | join("")' <<< "$command_response" > "$text_file"; then
    printf 'BBQ_WORKFLOW_RESULT: FAILED\n'
    printf '%s\n' "OpenCode returned an invalid command response"
    printf 'Stopped at: %s\n' "$phase"
    printf 'Log: %s\n' "$log_file"
    return 1
  fi

  while IFS= read -r result_line; do
    case "$result_line" in
      "BBQ_PHASE_RESULT: COMPLETE"|"BBQ_PHASE_RESULT: BLOCKED"|"BBQ_PHASE_RESULT: FAILED")
        phase_result="$result_line"
        result_count=$((result_count + 1))
        ;;
    esac
  done < "$text_file"

  rm -f "$text_file"

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

if ! start_server; then
  exit 1
fi

if [ "$start_phase" = "pantry" ]; then
  if ! run_phase "pantry" "bbq.pantry"; then
    exit 1
  fi
fi

if [ "$start_phase" = "pantry" ] || [ "$start_phase" = "prep" ]; then
  if ! run_phase "prep" "bbq.prep"; then
    exit 1
  fi
fi

if ! run_phase "fire" "bbq.fire"; then
  exit 1
fi

printf 'BBQ_WORKFLOW_RESULT: COMPLETE\n'
printf 'Ticket: %s\n' "$ticket_id"
printf 'Log directory: %s\n' "$run_dir"
