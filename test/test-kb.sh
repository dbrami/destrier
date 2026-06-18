#!/usr/bin/env bash
# Tests for the KB init script.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$HERE/.." && pwd)"
. "$HERE/lib.sh"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

( cd "$tmp" && bash "$ROOT/scripts/kb-init.sh" TestAgent >/dev/null )
d="$tmp/docs/knowledgebase/sessions"
ls "$d"/*-summary.md >/dev/null 2>&1
assert_exit_code 0 $? "kb-init creates a dated session file"

f="$(ls "$d"/*-summary.md)"
grep -q "Initialized by: TestAgent" "$f"
assert_exit_code 0 $? "session file records the agent label"

pass "kb"
