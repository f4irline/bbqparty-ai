#!/usr/bin/env bash

# Strict fixture for the OpenCode 2.1 API (no provider calls).
set -euo pipefail

state="$OPENCODE_V2_STATE"
mkdir -p "$state"
fail() { printf '%s\n' "$*" >&2; exit 2; }

case "$1" in
  --version) printf '%s\n' 'opencode v2.1.4'; exit 0 ;;
  serve)
    [ "$2 $3 $4" = '--hostname 127.0.0.1 --port' ] || fail 'Invalid V2 serve arguments'
    if [ "${OPENCODE_V2_STATION:-}" = 1 ]; then
      [ "${OPENCODE_CONFIG:-}" = "$OPENCODE_V2_DIRECTORY/opencode.json" ] || fail 'Station config leaked'
      [ "${OPENCODE_CONFIG_DIR:-}" = "$OPENCODE_V2_DIRECTORY/.opencode" ] || fail 'Station config directory leaked'
      [ -z "${OPENCODE_CONFIG_CONTENT:-}" ] || fail 'Station inline config leaked'
    fi
    printf '%s' "${OPENCODE_PASSWORD:-fixture-generated-password}" > "$state/password"
    printf 'server listening on http://127.0.0.1:%s\n' "$5"
    printf 'server password %s\n' "$(cat "$state/password")"
    trap 'touch "$state/stopped"; exit 0' TERM
    while :; do sleep 0.1; done
    ;;
  api)
    shift
    [ "$1" = '--server' ] || fail 'V2 requests must use the selected server'
    [[ "$2" == http://127.0.0.1:* ]] || fail 'Non-loopback server'
    shift 2
    [ "${OPENCODE_PASSWORD:-}" = "$(cat "$state/password")" ] || fail 'Missing V2 authentication'
    method="$1" path="$2"; shift 2
    printf '%s %s\n' "$method" "$path" >> "$state/calls"
    case "$method $path" in
      'post /api/session')
        [ "${OPENCODE_V2_FAILURE:-}" != create ] || fail 'Session create failed'
        [ "$1" = '--data' ] || fail 'Missing session body'
        jq -e --arg directory "$OPENCODE_V2_DIRECTORY" '.location.directory == $directory' <<< "$2" > /dev/null || fail 'Wrong session location'
        count=0
        if [ -f "$state/count" ]; then count="$(cat "$state/count")"; fi
        count=$((count + 1)); printf '%s' "$count" > "$state/count"
        printf '{"data":{"id":"ses_%s"}}\n' "$count"
        ;;
      'post /api/session/'*/command)
        [ "${OPENCODE_V2_FAILURE:-}" != command ] || fail 'Command failed'
        [ "$1" = '--data' ] || fail 'Missing command body'
        jq -e 'keys == ["name", "text"] and (.name | startswith("bbq.")) and (.text | startswith("STU-15"))' <<< "$2" > /dev/null || fail 'Invalid V2 command body'
        printf '%s\n' "$2" >> "$state/commands"
        jq -r .name <<< "$2" > "$state/command"
        rm -f "$state/waited"
        # V2 responds with 204, not assistant parts.
        ;;
      'post /api/experimental/session/'*/wait)
        [ "${OPENCODE_V2_FAILURE:-}" != wait ] || fail 'Wait failed'
        touch "$state/waited"
        ;;
      'get /api/session/'*/message*)
        [ -f "$state/waited" ] || fail 'Read before wait'
        [ "${OPENCODE_V2_FAILURE:-}" != messages ] || fail 'Message read failed'
        [[ "$path" == *'type=assistant'* && "$path" == *'order=desc'* && "$path" == *'limit=1'* ]] || fail 'Must read latest assistant response'
        text="${OPENCODE_V2_TEXT:-BBQ_PHASE_RESULT: COMPLETE}"
        if [ "$(cat "$state/command")" = bbq.station ]; then
          text=$'BBQ_STATION_BRANCH: chore/STU-15-herdr-session-placement\nBBQ_STATION_RESULT: COMPLETE'
        fi
        if [ "${OPENCODE_V2_FAILURE:-}" = malformed ]; then
          printf '%s\n' '{"data":{}}'
        else
          jq -n --arg text "$text" '{data:[{type:"assistant",content:[{type:"reasoning",text:"BBQ_PHASE_RESULT: FAILED"},{type:"tool",state:{content:[{type:"text",text:"BBQ_PHASE_RESULT: FAILED"}]}},{type:"text",text:$text}]}],cursor:{}}'
        fi
        ;;
      'get /api/session/'*)
        [ -f "$state/waited" ] || fail 'Read session before wait'
        outcome=succeeded
        if [ "${OPENCODE_V2_FAILURE:-}" = outcome ]; then outcome=failed; fi
        printf '{"data":{"outcome":"%s"}}\n' "$outcome"
        ;;
      *) fail "Unsupported V2 API request: $method $path" ;;
    esac
    ;;
  *) fail "Unsupported V2 invocation: $*" ;;
esac
