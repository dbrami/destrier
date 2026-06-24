#!/usr/bin/env bash
# Tests for bundled skills.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$HERE/.." && pwd)"
. "$HERE/lib.sh"

# --- evidence-driven-debugging ---
S="$ROOT/skills/evidence-driven-debugging/SKILL.md"
[ -f "$S" ]; assert_exit_code 0 $? "evidence-driven-debugging SKILL.md exists"
head -1 "$S" | grep -q '^---$'; assert_exit_code 0 $? "EDD has YAML frontmatter"
grep -q '^name: evidence-driven-debugging' "$S"; assert_exit_code 0 $? "EDD name set"
if grep -qiE 'invoke .*alongside .*systematic-debugging|complements `systematic-debugging`|see systematic-debugging' "$S"; then
  fail "EDD still hard-depends on systematic-debugging"
else
  echo "  ok: EDD has no hard systematic-debugging dependency"
fi

# --- session-handover (created in a later task; assert only if present) ---
H="$ROOT/skills/session-handover/SKILL.md"
if [ -f "$H" ]; then
  grep -q '^name: session-handover' "$H"; assert_exit_code 0 $? "session-handover name set"
fi

# --- spec-driven-brainstorming ---
B="$ROOT/skills/spec-driven-brainstorming/SKILL.md"
[ -f "$B" ]; assert_exit_code 0 $? "spec-driven-brainstorming SKILL.md exists"
head -1 "$B" | grep -q '^---$'; assert_exit_code 0 $? "SDB has YAML frontmatter"
grep -q '^name: spec-driven-brainstorming' "$B"; assert_exit_code 0 $? "SDB name set"
grep -q 'speckit-constitution' "$B" && grep -q 'speckit-specify' "$B"
assert_exit_code 0 $? "SDB references the speckit authoring commands"

pass "skills"
