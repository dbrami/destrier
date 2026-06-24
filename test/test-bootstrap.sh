#!/usr/bin/env bash
# Tests for the bootstrap and the gitnexus MCP launcher.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$HERE/.." && pwd)"
. "$HERE/lib.sh"
BS="$ROOT/scripts/bootstrap.sh"

# --check never mutates and exits 0
out="$(bash "$BS" --check 2>&1)"; rc=$?
assert_exit_code 0 "$rc" "bootstrap --check exits 0"

# every documented prerequisite is verified
for t in git rg jq node npm python3 gh curl uv gitnexus roborev; do
  assert_contains "$out" "$t" "check reports $t"
done

# a missing prerequisite surfaces a MISSING line, an install command, and the opt-in
out2="$(DESTRIER_FAKE_MISSING=jq bash "$BS" --check 2>&1)"; rc2=$?
assert_exit_code 0 "$rc2" "check still exits 0 with a missing tool"
assert_contains "$out2" "MISSING" "missing tool reported as MISSING"
assert_contains "$out2" "jq ->" "missing tool shows an install command"
assert_contains "$out2" "install-deps" "offers --install-deps for missing prerequisites"

# launcher with no install present -> exit 1 with guidance, no crash
empty="$(mktemp -d)"; trap 'rm -rf "$empty"' EXIT
out3="$(DESTRIER_HOME="$empty" bash "$ROOT/scripts/gitnexus-mcp-launch.sh" 2>&1)"; rc3=$?
assert_exit_code 1 "$rc3" "launcher exits 1 when gitnexus missing"
assert_contains "$out3" "destrier-setup" "launcher tells user to run setup"

# .mcp.json valid and points at the launcher
if command -v jq >/dev/null 2>&1; then
  jq -e '.mcpServers.gitnexus.command' "$ROOT/.mcp.json" >/dev/null 2>&1
  assert_exit_code 0 $? ".mcp.json registers gitnexus"
fi

pass "bootstrap"
