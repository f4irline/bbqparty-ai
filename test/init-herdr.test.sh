#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
init_script="$repo_root/init.sh"
temp_dir="$(mktemp -d)"

cleanup() {
  rm -rf "$temp_dir"
}

trap cleanup EXIT

mkdir -p "$temp_dir/bin"

cat > "$temp_dir/bin/herdr" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >> "$HERDR_CALL_LOG"
case "$1 ${2:-}" in
  "--version ") printf '%s\n' "herdr ${HERDR_VERSION:-0.9.0}" ;;
  "worktree help") printf '%s\n' 'list create open' ;;
  "agent help") printf '%s\n' 'start prompt wait read' ;;
  "tab help") printf '%s\n' 'create' ;;
  "integration status") printf '%s\n' "opencode: ${HERDR_INTEGRATION_STATUS:-current (mock)}" ;;
  "integration install") : > "$HERDR_INTEGRATION_INSTALLED" ;;
  *) printf 'Unexpected Herdr invocation: %s\n' "$*" >&2; exit 2 ;;
esac
EOF

cat > "$temp_dir/bin/curl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >> "$CURL_CALL_LOG"
if [ "${CURL_INVALID_SKILL:-}" = "1" ]; then
  printf '%s\n' 'invalid skill'
else
  printf '%s\n' '---'
  printf '%s\n' 'name: herdr'
  printf '%s\n' '---'
  printf '%s\n' 'Requires HERDR_ENV=1'
fi
EOF

cat > "$temp_dir/bin/docker" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF

chmod +x "$temp_dir/bin/herdr" "$temp_dir/bin/curl" "$temp_dir/bin/docker"

run_init() {
  local target="$1"
  shift
  printf 'y\n' | HERDR_CALL_LOG="$temp_dir/herdr-calls" \
  HERDR_INTEGRATION_INSTALLED="$temp_dir/integration-installed" \
  CURL_CALL_LOG="$temp_dir/curl-calls" \
  PATH="$temp_dir/bin:$PATH" \
    "$init_script" "$target" --skip-docker --skip-env --auth-method pat "$@"
}

target="$temp_dir/herdr-target"
mkdir -p "$target"
run_init "$target" --herdr > "$temp_dir/herdr-output"

if ! jq -e '.runtime == "herdr"' "$target/.opencode/bbq-config.json" > /dev/null; then
  printf '%s\n' 'Herdr installation did not write Herdr runtime config' >&2
  exit 1
fi

expected_url='https://raw.githubusercontent.com/herdrdev/herdr/v0.9.0/skills/herdr/SKILL.md'
if ! rg --fixed-strings --quiet "$expected_url" "$temp_dir/curl-calls"; then
  printf '%s\n' 'Herdr skill was not downloaded from the installed version tag' >&2
  exit 1
fi

if ! rg --fixed-strings --quiet 'Requires HERDR_ENV=1' "$target/.opencode/skills/herdr/SKILL.md"; then
  printf '%s\n' 'Validated Herdr skill was not installed' >&2
  exit 1
fi

if rg --fixed-strings --quiet 'integration install opencode' "$temp_dir/herdr-calls"; then
  printf '%s\n' 'Current OpenCode integration was unnecessarily reinstalled' >&2
  exit 1
fi

rm -f "$temp_dir/herdr-calls" "$temp_dir/integration-installed"
HERDR_INTEGRATION_STATUS='needs repair' run_init "$target" --herdr > /dev/null
if [ ! -f "$temp_dir/integration-installed" ]; then
  printf '%s\n' 'Repair-needed OpenCode integration was not installed' >&2
  exit 1
fi

native_target="$temp_dir/native-target"
mkdir -p "$native_target"
printf '\n' | HERDR_CALL_LOG="$temp_dir/native-herdr-calls" \
  HERDR_INTEGRATION_INSTALLED="$temp_dir/native-integration-installed" \
  CURL_CALL_LOG="$temp_dir/native-curl-calls" \
  PATH="$temp_dir/bin:$PATH" \
  "$init_script" "$native_target" --skip-docker --skip-env --auth-method pat > /dev/null
if ! jq -e '.runtime == "native"' "$native_target/.opencode/bbq-config.json" > /dev/null; then
  printf '%s\n' 'Interactive default did not select native runtime' >&2
  exit 1
fi
if [ -e "$temp_dir/native-herdr-calls" ]; then
  printf '%s\n' 'Native installation invoked Herdr' >&2
  exit 1
fi

missing_target="$temp_dir/missing-herdr-target"
mkdir -p "$missing_target"
if PATH="/usr/bin:/bin" "$init_script" "$missing_target" --herdr --skip-docker --skip-env --auth-method pat > /dev/null 2> "$temp_dir/missing-herdr-output"; then
  printf '%s\n' 'Installer accepted Herdr mode without Herdr installed' >&2
  exit 1
fi
if ! rg --ignore-case --quiet 'homebrew|installer' "$temp_dir/missing-herdr-output"; then
	printf 'Missing Herdr error lacked installation guidance:\n%s\n' "$(<"$temp_dir/missing-herdr-output")" >&2
  exit 1
fi

invalid_target="$temp_dir/invalid-skill-target"
mkdir -p "$invalid_target/.opencode/skills/herdr"
printf '%s\n' 'existing skill' > "$invalid_target/.opencode/skills/herdr/SKILL.md"
if CURL_INVALID_SKILL=1 run_init "$invalid_target" --herdr > /dev/null 2>&1; then
  printf '%s\n' 'Installer accepted invalid Herdr skill content' >&2
  exit 1
fi
if [ "$(<"$invalid_target/.opencode/skills/herdr/SKILL.md")" != 'existing skill' ]; then
  printf '%s\n' 'Invalid Herdr download replaced an existing skill' >&2
  exit 1
fi
if ! jq -e '.runtime == "native"' "$invalid_target/.opencode/bbq-config.json" > /dev/null; then
  printf '%s\n' 'Failed Herdr installation left a Herdr runtime configuration behind' >&2
  exit 1
fi

declined_target="$temp_dir/declined-target"
mkdir -p "$declined_target/.opencode"
if printf 'n\n' | HERDR_CALL_LOG="$temp_dir/declined-herdr-calls" \
  HERDR_INTEGRATION_INSTALLED="$temp_dir/declined-integration-installed" \
  CURL_CALL_LOG="$temp_dir/declined-curl-calls" \
  PATH="$temp_dir/bin:$PATH" \
  "$init_script" "$declined_target" --herdr --skip-docker --skip-env --auth-method pat > "$temp_dir/declined-output" 2>&1; then
  printf '%s\n' 'Declining menu replacement still configured Herdr' >&2
  exit 1
fi
if ! rg --ignore-case --quiet 'rerun' "$temp_dir/declined-output"; then
  printf '%s\n' 'Declined Herdr configuration lacked rerun guidance' >&2
  exit 1
fi

printf '%s\n' 'PASS: Herdr installer'
