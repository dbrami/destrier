#!/usr/bin/env bash
# Tests for the OKF concept scaffold helper (scripts/kb-concept.sh).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$HERE/.." && pwd)"
. "$HERE/lib.sh"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

kb="$tmp/docs/knowledgebase"

# Starter type 'decision' -> 'decisions/' subdir; title -> slug.
out="$( cd "$tmp" && bash "$ROOT/scripts/kb-concept.sh" decision "Adopt OKF for the KB" sales,kb 2>&1 )"
assert_exit_code 0 $? "kb-concept exits 0 for a known type"

cf="$kb/concepts/decisions/adopt-okf-for-the-kb.md"
[ -f "$cf" ]
assert_exit_code 0 $? "concept file created under concepts/decisions/ with a slugified name"

assert_contains "$out" "$cf" "kb-concept prints the created path"

head -1 "$cf" | grep -q '^---$'
assert_exit_code 0 $? "concept file leads with YAML frontmatter"

grep -q '^type: decision$' "$cf"
assert_exit_code 0 $? "concept frontmatter declares the requested type"

grep -q '^title: Adopt OKF for the KB$' "$cf"
assert_exit_code 0 $? "concept frontmatter carries the title"

# Indexes updated (progressive disclosure) with bundle-relative absolute links.
grep -q '(/concepts/decisions/adopt-okf-for-the-kb.md)' "$kb/concepts/decisions/index.md"
assert_exit_code 0 $? "type index links the new concept (bundle-relative absolute)"

grep -q '(/concepts/decisions/index.md)' "$kb/concepts/index.md"
assert_exit_code 0 $? "concepts index links the type subdir (bundle-relative absolute)"

# Reserved index files carry NO frontmatter.
head -1 "$kb/concepts/index.md" | grep -q '^---$'
assert_exit_code 1 $? "concepts index.md has no frontmatter (reserved file)"
head -1 "$kb/concepts/decisions/index.md" | grep -q '^---$'
assert_exit_code 1 $? "type index.md has no frontmatter (reserved file)"

# Root log: date-grouped, records the concept, no frontmatter.
head -1 "$kb/log.md" | grep -q '^---$'
assert_exit_code 1 $? "log.md has no frontmatter (reserved file)"
grep -qE "^## [0-9]{4}-[0-9]{2}-[0-9]{2}$" "$kb/log.md"
assert_exit_code 0 $? "log.md is date-grouped"
grep -q 'adopt-okf-for-the-kb' "$kb/log.md"
assert_exit_code 0 $? "root log records the new concept"

# Starter type 'open-item' -> 'open-items/' subdir.
( cd "$tmp" && bash "$ROOT/scripts/kb-concept.sh" open-item "Wire up visualizer" >/dev/null 2>&1 )
[ -f "$kb/concepts/open-items/wire-up-visualizer.md" ]
assert_exit_code 0 $? "open-item maps to the open-items/ subdir"

# Unknown type -> sanitized kebab of the type as the subdir (no naive plural).
( cd "$tmp" && bash "$ROOT/scripts/kb-concept.sh" runbook "Deploy steps" >/dev/null 2>&1 )
[ -f "$kb/concepts/runbook/deploy-steps.md" ]
assert_exit_code 0 $? "unknown type uses the sanitized type as its subdir"

# Usage error when arguments are missing.
( cd "$tmp" && bash "$ROOT/scripts/kb-concept.sh" decision >/dev/null 2>&1 )
assert_exit_code 1 $? "kb-concept errors when title is missing"

pass "kb-concept"
