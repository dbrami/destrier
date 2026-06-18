#!/usr/bin/env bash
# Tests for the bootstrap and the gitnexus MCP launcher.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$HERE/.." && pwd)"
. "$HERE/lib.sh"

# --check never mutates and exits 0, reporting both tools
out="$(bash "$ROOT/scripts/bootstrap.sh" --check 2>&1)"; rc=$?
assert_exit_code 0 "$rc" "bootstrap --check exits 0"
assert_contains "$out" "gitnexus" "check reports gitnexus"
assert_contains "$out" "roborev" "check reports roborev"

# launcher with no install present -> exit 1 with guidance, no crash
empty="$(mktemp -d)"; trap 'rm -rf "$empty"' EXIT
out2="$(CODEMAN_HOME="$empty" bash "$ROOT/scripts/gitnexus-mcp-launch.sh" 2>&1)"; rc2=$?
assert_exit_code 1 "$rc2" "launcher exits 1 when gitnexus missing"
assert_contains "$out2" "codeman-setup" "launcher tells user to run setup"

# .mcp.json valid and points at the launcher
if command -v jq >/dev/null 2>&1; then
  jq -e '.mcpServers.gitnexus.command' "$ROOT/.mcp.json" >/dev/null 2>&1
  assert_exit_code 0 $? ".mcp.json registers gitnexus"
fi

pass "bootstrap"
