#!/usr/bin/env bash
# Tests for the KB init script (OKF v0.1 bundle).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$HERE/.." && pwd)"
. "$HERE/lib.sh"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

( cd "$tmp" && bash "$ROOT/scripts/kb-init.sh" TestAgent >/dev/null )
kb="$tmp/docs/knowledgebase"
d="$kb/sessions"
ls "$d"/*-summary.md >/dev/null 2>&1
assert_exit_code 0 $? "kb-init creates a dated session file"

f="$(ls "$d"/*-summary.md)"
grep -q "Initialized by: TestAgent" "$f"
assert_exit_code 0 $? "session file records the agent label"

# OKF v0.1 conformance: YAML frontmatter on the session concept file.
head -1 "$f" | grep -q '^---$'
assert_exit_code 0 $? "session file leads with YAML frontmatter"

grep -q '^type: session-summary$' "$f"
assert_exit_code 0 $? "session file declares type: session-summary"

# OKF bundle scaffolding: progressive-disclosure index + chronological log.
[ -f "$kb/index.md" ]
assert_exit_code 0 $? "kb-init creates the bundle root index.md"

[ -f "$kb/log.md" ]
assert_exit_code 0 $? "kb-init creates the root log.md"

[ -f "$d/index.md" ]
assert_exit_code 0 $? "kb-init creates sessions/index.md"

# OKF reserved files carry NO frontmatter (index.md/log.md are not concepts).
head -1 "$kb/index.md" | grep -q '^---$'
assert_exit_code 1 $? "root index.md has no frontmatter (reserved file)"

head -1 "$kb/log.md" | grep -q '^---$'
assert_exit_code 1 $? "log.md has no frontmatter (reserved file)"

head -1 "$d/index.md" | grep -q '^---$'
assert_exit_code 1 $? "sessions/index.md has no frontmatter (reserved file)"

# log.md is date-grouped (ISO 8601 date headings).
grep -qE "^## [0-9]{4}-[0-9]{2}-[0-9]{2}$" "$kb/log.md"
assert_exit_code 0 $? "log.md is date-grouped"

# Cross-links use the recommended bundle-relative absolute form.
grep -q "(/sessions/.*-summary.md)" "$d/index.md"
assert_exit_code 0 $? "sessions index uses bundle-relative absolute links"

# Idempotent + forward-only: a second run must not error or duplicate the file.
( cd "$tmp" && bash "$ROOT/scripts/kb-init.sh" TestAgent >/dev/null )
assert_exit_code 0 $? "kb-init is idempotent on re-run"
n="$(ls "$d"/*-summary.md | wc -l | tr -d ' ')"
assert_eq 1 "$n" "re-run does not create a duplicate session file"

pass "kb"
