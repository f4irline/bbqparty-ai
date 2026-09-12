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
    pantry|prep|fire) ;;
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
runtime=""

cleanup_server() {
  if [ -n "$server_pid" ] && kill -0 "$server_pid" >/dev/null 2>&1; then
    kill "$server_pid" >/dev/null 2>&1 || true
    wait "$server_pid" >/dev/null 2>&1 || true
  fi
}

trap cleanup_server EXIT

require_command() {
  local command_name="$1"
  if ! command -v "$command_name" >/dev/null 2>&1; then
    printf '%s is required but was not found in PATH\n' "$command_name" >&2
    exit 127
  fi
}

resolve_runtime() {
  local config_file="$repo_root/.opencode/bbq-config.json"

  if [ ! -f "$config_file" ]; then
    runtime="native"
    return 0
  fi

  if ! runtime="$(jq --raw-output --exit-status '.runtime | strings' "$config_file" 2>/dev/null)"; then
    printf 'Invalid BBQ runtime configuration: %s\n' "$config_file" >&2
    return 1
  fi

  case "$runtime" in
    native)
      ;;
    herdr)
      if [ "${HERDR_ENV:-}" = "1" ]; then
        if [ -z "${HERDR_WORKSPACE_ID:-}" ]; then
          printf '%s\n' "HERDR_ENV=1 requires HERDR_WORKSPACE_ID; start the runner from a Herdr workspace pane" >&2
          return 1
        fi
      else
        printf '%s\n' "Herdr runtime is configured but this is not a Herdr pane; using native OpenCode fallback"
        runtime="native"
      fi
      ;;
    *)
      printf 'Unknown BBQ runtime "%s" in %s\n' "$runtime" "$config_file" >&2
      return 1
      ;;
  esac
}

evaluate_phase_result() {
  local phase="$1"
  local text_file="$2"
  local log_file="$3"
  local result_line
  local phase_result=""
  local result_count=0

  while IFS= read -r result_line; do
    case "$result_line" in
      "BBQ_PHASE_RESULT: COMPLETE"|"BBQ_PHASE_RESULT: BLOCKED"|"BBQ_PHASE_RESULT: FAILED")
        phase_result="$result_line"
        result_count=$((result_count + 1))
        ;;
    esac
  done < "$text_file"

  if [ "$result_count" -ne 1 ]; then
    printf 'BBQ_WORKFLOW_RESULT: FAILED\n'
    printf '%s\n' "Phase must return exactly one BBQ_PHASE_RESULT marker"
  elif [ "$phase_result" = "BBQ_PHASE_RESULT: COMPLETE" ]; then
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

start_server() {
  local server_line reported_server_url configured_port="${BBQ_OPENCODE_PORT:-}" server_port attempt

  if [ -n "$server_url" ]; then
    if ! [[ "$server_url" =~ ^http://127\.0\.0\.1:[0-9]+$ ]]; then
      printf '%s\n' "BBQ_OPENCODE_URL must be a loopback URL such as http://127.0.0.1:4096" >&2
      return 1
    fi
    printf 'Using OpenCode server: %s\n' "$server_url"
    return 0
  fi

  for attempt in {1..5}; do
    if [ -n "$configured_port" ]; then server_port="$configured_port"; else server_port=$((20000 + RANDOM % 20000)); fi
    : > "$server_log"
    opencode serve --hostname 127.0.0.1 --port "$server_port" > "$server_log" 2>&1 &
    server_pid=$!
    for _ in {1..50}; do
      while IFS= read -r server_line; do
        case "$server_line" in
          "opencode server listening on "*)
            reported_server_url="${server_line#opencode server listening on }"
            if ! [[ "$reported_server_url" =~ ^http://127\.0\.0\.1:[0-9]+$ ]]; then
              kill "$server_pid" >/dev/null 2>&1 || true; wait "$server_pid" >/dev/null 2>&1 || true; server_pid=""
              printf '%s\n' "OpenCode server reported a non-loopback URL" >&2; printf 'Log: %s\n' "$server_log" >&2
              return 1
            fi
            server_url="$reported_server_url"
            printf 'Started OpenCode server: %s\n' "$server_url"
            return 0
            ;;
        esac
      done < "$server_log"
      if ! kill -0 "$server_pid" >/dev/null 2>&1; then wait "$server_pid" >/dev/null 2>&1 || true; server_pid=""; break; fi
      sleep 0.1
    done
    if [ -n "$server_pid" ]; then
      kill "$server_pid" >/dev/null 2>&1 || true; wait "$server_pid" >/dev/null 2>&1 || true; server_pid=""
      printf '%s\n' "Timed out waiting for the OpenCode server" >&2; printf 'Log: %s\n' "$server_log" >&2
      return 1
    fi
    if [ -n "$configured_port" ]; then
      printf 'OpenCode server stopped before it became ready on port %s\n' "$configured_port" >&2; printf 'Log: %s\n' "$server_log" >&2
      return 1
    fi
  done
  printf '%s\n' "Could not start OpenCode server after 5 port attempts" >&2; printf 'Log: %s\n' "$server_log" >&2
  return 1
}

run_http_phase() {
  local phase="$1" command_name="$2"
  local log_file="$run_dir/$phase.log" text_file="$run_dir/$phase.text"
  local session_id="" session_response command_response command_payload
  local -a curl_args=(--fail --silent --show-error --request POST --header "x-opencode-directory: $repo_root" --header "Content-Type: application/json")

  printf 'Starting %s for %s\n' "$phase" "$ticket_id"
  if ! session_response="$(curl_request "${curl_args[@]}" --data '{}' "$server_url/session")"; then
    printf 'BBQ_WORKFLOW_RESULT: FAILED\n'; printf '%s\n' "Failed to create an OpenCode session"; printf 'Stopped at: %s\n' "$phase"; return 1
  fi
  printf '%s\n' "$session_response" > "$log_file"
  if ! session_id="$(jq --raw-output --exit-status '.id | strings | select(startswith("ses"))' <<< "$session_response")"; then
    printf 'BBQ_WORKFLOW_RESULT: FAILED\n'; printf '%s\n' "OpenCode did not return a valid session ID"; printf 'Stopped at: %s\n' "$phase"; printf 'Log: %s\n' "$log_file"; return 1
  fi
  printf 'Phase session: %s\n' "$session_id"
  printf 'Connect in another terminal: opencode attach %q --session %q --dir %q\n' "$server_url" "$session_id" "$repo_root"
  if [ -n "${OPENCODE_SERVER_PASSWORD:-}" ]; then printf '%s\n' "Set OPENCODE_SERVER_PASSWORD in the attaching terminal before connecting."; fi
  command_payload="{\"command\":\"$(json_escape "$command_name")\",\"arguments\":\"$(json_escape "$command_arguments")\"}"
  if ! command_response="$(curl_request "${curl_args[@]}" --data "$command_payload" "$server_url/session/$session_id/command")"; then
    printf 'BBQ_WORKFLOW_RESULT: FAILED\n'; printf '%s\n' "OpenCode command failed"; printf 'Stopped at: %s\n' "$phase"; printf 'Log: %s\n' "$log_file"; return 1
  fi
  printf '%s\n' "$command_response" >> "$log_file"
  if ! jq --raw-output '[.parts[]? | select(.type == "text") | .text] | join("")' <<< "$command_response" > "$text_file"; then
    printf 'BBQ_WORKFLOW_RESULT: FAILED\n'; printf '%s\n' "OpenCode returned an invalid command response"; printf 'Stopped at: %s\n' "$phase"; printf 'Log: %s\n' "$log_file"; return 1
  fi
  if ! evaluate_phase_result "$phase" "$text_file" "$log_file"; then return 1; fi
  rm -f "$text_file"
  printf 'Completed %s\n' "$phase"
}

run_herdr_phase() {
  local phase="$1" command_name="$2"
  local log_file="$run_dir/$phase.log" text_file="$run_dir/$phase.text"
  local tab_response pane_id agent_name start_response prompt_response agent_status wait_response read_response
  local ticket_slug run_token
  local command_ready_delay_seconds="${BBQ_HERDR_COMMAND_READY_DELAY_SECONDS:-3}"

  if ! [[ "$command_ready_delay_seconds" =~ ^[0-9]+$ ]]; then
    printf 'BBQ_WORKFLOW_RESULT: FAILED\n'; printf 'BBQ_HERDR_COMMAND_READY_DELAY_SECONDS must be a non-negative integer\n'; printf 'Stopped at: %s\n' "$phase"; return 1
  fi

  ticket_slug="$(printf '%s' "$ticket_id" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9-')"
  run_token="$(printf '%s' "$run_dir" | cksum | cut -d ' ' -f 1)"
  agent_name="bbq-${ticket_slug:0:10}-${phase}-${run_token:0:9}"
  agent_name="${agent_name:0:32}"
  : > "$log_file"
  printf 'Starting %s for %s in Herdr agent %s\n' "$phase" "$ticket_id" "$agent_name"

  if ! tab_response="$(herdr tab create --workspace "$HERDR_WORKSPACE_ID" --cwd "$repo_root" --label "BBQ $ticket_id $phase" --no-focus 2>> "$log_file")"; then
    printf '%s\n' "$tab_response" >> "$log_file"; printf 'BBQ_WORKFLOW_RESULT: FAILED\n'; printf '%s\n' "Failed to create Herdr tab for $phase"; printf 'Stopped at: %s\n' "$phase"; printf 'Log: %s\n' "$log_file"; return 1
  fi
  printf '%s\n' "$tab_response" >> "$log_file"
  if ! pane_id="$(jq --raw-output --exit-status '.result.root_pane.pane_id | strings' <<< "$tab_response")"; then
    printf 'BBQ_WORKFLOW_RESULT: FAILED\n'; printf '%s\n' "Herdr did not return a root pane ID"; printf 'Stopped at: %s\n' "$phase"; printf 'Log: %s\n' "$log_file"; return 1
  fi
  if ! start_response="$(herdr agent start "$agent_name" --kind opencode --pane "$pane_id" -- "$repo_root" 2>> "$log_file")"; then
    printf '%s\n' "$start_response" >> "$log_file"; printf 'BBQ_WORKFLOW_RESULT: FAILED\n'; printf 'Failed to start Herdr agent: %s\n' "$agent_name"; printf 'Stopped at: %s\n' "$phase"; printf 'Log: %s\n' "$log_file"; return 1
  fi
  printf '%s\n' "$start_response" >> "$log_file"
  printf 'Waiting %ss for OpenCode command discovery\n' "$command_ready_delay_seconds"
  sleep "$command_ready_delay_seconds"
  if ! prompt_response="$(herdr agent prompt "$agent_name" "/$command_name $command_arguments" --wait 2>> "$log_file")"; then
    printf '%s\n' "$prompt_response" >> "$log_file"
    if read_response="$(herdr agent read "$agent_name" --source recent-unwrapped --lines 200 2>> "$log_file")"; then
      printf '%s\n' "$read_response" > "$text_file"
      printf '%s\n' "$read_response" >> "$log_file"
    fi
    printf 'BBQ_WORKFLOW_RESULT: FAILED\n'; printf 'Herdr agent command failed; inspect with: herdr agent attach %s\n' "$agent_name"; printf 'Stopped at: %s\n' "$phase"; printf 'Log: %s\n' "$log_file"; return 1
  fi
  printf '%s\n' "$prompt_response" >> "$log_file"
  if ! agent_status="$(jq --raw-output --exit-status '.result.agent.agent_status | strings' <<< "$prompt_response")"; then
    printf 'BBQ_WORKFLOW_RESULT: FAILED\n'; printf 'Herdr returned no agent status; inspect with: herdr agent attach %s\n' "$agent_name"; printf 'Stopped at: %s\n' "$phase"; printf 'Log: %s\n' "$log_file"; return 1
  fi
  if [ "$agent_status" = "blocked" ]; then
    printf 'Herdr agent is blocked. Attach with: herdr agent attach %s\n' "$agent_name"
    if ! wait_response="$(herdr agent wait "$agent_name" --until idle --until done 2>> "$log_file")"; then
      printf '%s\n' "$wait_response" >> "$log_file"; printf 'BBQ_WORKFLOW_RESULT: FAILED\n'; printf 'Herdr agent wait failed; inspect with: herdr agent attach %s\n' "$agent_name"; printf 'Stopped at: %s\n' "$phase"; printf 'Log: %s\n' "$log_file"; return 1
    fi
    printf '%s\n' "$wait_response" >> "$log_file"
    if ! agent_status="$(jq --raw-output --exit-status '.result.agent.agent_status | strings' <<< "$wait_response")" || { [ "$agent_status" != "idle" ] && [ "$agent_status" != "done" ]; }; then
      printf 'BBQ_WORKFLOW_RESULT: FAILED\n'; printf 'Herdr agent did not settle; inspect with: herdr agent attach %s\n' "$agent_name"; printf 'Stopped at: %s\n' "$phase"; printf 'Log: %s\n' "$log_file"; return 1
    fi
  elif [ "$agent_status" != "idle" ] && [ "$agent_status" != "done" ]; then
    printf 'BBQ_WORKFLOW_RESULT: FAILED\n'; printf 'Herdr agent is not settled; inspect with: herdr agent attach %s\n' "$agent_name"; printf 'Stopped at: %s\n' "$phase"; printf 'Log: %s\n' "$log_file"; return 1
  fi
  if ! read_response="$(herdr agent read "$agent_name" --source recent-unwrapped --lines 200 2>> "$log_file")"; then
    printf '%s\n' "$read_response" >> "$log_file"; printf 'BBQ_WORKFLOW_RESULT: FAILED\n'; printf 'Failed to read Herdr agent; inspect with: herdr agent attach %s\n' "$agent_name"; printf 'Stopped at: %s\n' "$phase"; printf 'Log: %s\n' "$log_file"; return 1
  fi
  printf '%s\n' "$read_response" > "$text_file"
  printf '%s\n' "$read_response" >> "$log_file"
  if ! evaluate_phase_result "$phase" "$text_file" "$log_file"; then
    printf 'Inspect retained Herdr agent: herdr agent attach %s\n' "$agent_name"
    return 1
  fi
  printf 'Completed %s\n' "$phase"
  printf 'Inspect retained Herdr agent: herdr agent attach %s\n' "$agent_name"
}

run_http_workflow() {
  require_command opencode
  require_command curl
  if ! start_server; then return 1; fi
  if [ "$start_phase" = "pantry" ] && ! run_http_phase pantry bbq.pantry; then return 1; fi
  if { [ "$start_phase" = "pantry" ] || [ "$start_phase" = "prep" ]; } && ! run_http_phase prep bbq.prep; then return 1; fi
  run_http_phase fire bbq.fire
}

run_herdr_workflow() {
  require_command herdr
  if [ "$start_phase" = "pantry" ] && ! run_herdr_phase pantry bbq.pantry; then return 1; fi
  if { [ "$start_phase" = "pantry" ] || [ "$start_phase" = "prep" ]; } && ! run_herdr_phase prep bbq.prep; then return 1; fi
  run_herdr_phase fire bbq.fire
}

require_command jq
if ! resolve_runtime; then exit 1; fi
if [ "$runtime" = "herdr" ]; then
  if ! run_herdr_workflow; then exit 1; fi
else
  if ! run_http_workflow; then exit 1; fi
fi

printf 'BBQ_WORKFLOW_RESULT: COMPLETE\n'
printf 'Ticket: %s\n' "$ticket_id"
printf 'Log directory: %s\n' "$run_dir"
