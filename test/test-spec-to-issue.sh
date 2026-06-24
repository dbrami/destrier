#!/usr/bin/env bash
# Tests for scripts/spec-to-issue.sh (spec.md -> GitHub issue bridge).
# Hermetic: `gh` is stubbed on PATH; the leak fixture is built at runtime with a
# split prefix so this SOURCE file stays scan-clean.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$HERE/.." && pwd)"
. "$HERE/lib.sh"
S2I="$ROOT/scripts/spec-to-issue.sh"

bin=""; w=""
_cleanup() { for d in "$bin" "$w"; do [ -n "$d" ] && rm -rf "$d"; done; }
trap _cleanup EXIT

# A reusable clean fixture spec.
make_spec() { # dir
  mkdir -p "$1/specs/001-demo"
  cat > "$1/specs/001-demo/spec.md" <<'SPEC'
# Feature Specification: Demo Feature

**Input**: User description: "Build a demo widget that does the thing."

## User Scenarios & Testing

### User Story 1 - Do the thing (Priority: P1)

A user does the thing and value happens.

## Requirements

- **FR-001**: System MUST do the thing.

## Success Criteria

- **SC-001**: A user completes the primary task in under one minute with no
  manual configuration.
- **SC-002**: The thing never corrupts existing data.
SPEC
}

# ---------------------------------------------------------------------------
# 1) --dry-run renders a summary body and makes no gh calls
# ---------------------------------------------------------------------------
w="$(mktemp -d)"; make_spec "$w"
out="$( ( cd "$w" && bash "$S2I" --dry-run specs/001-demo/spec.md ) 2>&1 )"; rc=$?
assert_exit_code 0 "$rc" "--dry-run exits 0"
assert_contains "$out" "title: Demo Feature" "title derived from the spec heading"
assert_contains "$out" "Build a demo widget" "summary derived from Input"
assert_contains "$out" "- [ ] A user completes the primary task" "SC rendered as a checkbox (continuation joined)"
assert_contains "$out" "specs/001-demo/spec.md" "body links the canonical spec"
# No decorative emoji checkmarks — ASCII checkboxes only.
if printf '%s' "$out" | grep -qF '✅'; then fail "body must not contain emoji checkmarks"; else echo "  ok: ASCII checkboxes, no emoji"; fi
rm -rf "$w"; w=""

# ---------------------------------------------------------------------------
# 2) .destrier/issue.config — title prefix, labels, full body mode
# ---------------------------------------------------------------------------
w="$(mktemp -d)"; make_spec "$w"
mkdir -p "$w/.destrier"
printf 'ISSUE_TITLE_PREFIX=[Feature] \nISSUE_LABELS=type/feature,status/backlog\nISSUE_BODY=full\n' > "$w/.destrier/issue.config"
out="$( ( cd "$w" && bash "$S2I" --dry-run specs/001-demo/spec.md ) 2>&1 )"; rc=$?
assert_exit_code 0 "$rc" "config dry-run exits 0"
assert_contains "$out" "title: [Feature] Demo Feature" "ISSUE_TITLE_PREFIX applied"
assert_contains "$out" "labels: type/feature,status/backlog" "ISSUE_LABELS surfaced"
assert_contains "$out" "Source spec (canonical)" "ISSUE_BODY=full emits the full-body header"
rm -rf "$w"; w=""

# ---------------------------------------------------------------------------
# 3) Privacy gate aborts before publishing when the body would leak a codename
# ---------------------------------------------------------------------------
w="$(mktemp -d)"; mkdir -p "$w/specs/001-demo" "$w/priv"
code='ACME_CODENAME'   # built here so this test file stays scan-clean
{ echo "# Feature Specification: Leaky Feature"; echo ""; echo "**Input**: User description: \"$code is the secret project.\""; } > "$w/specs/001-demo/spec.md"
printf '%s\n' "$code" > "$w/priv/deny.txt"
out="$( ( cd "$w" && DESTRIER_PRIVATE_DENYLIST="$w/priv/deny.txt" bash "$S2I" --dry-run specs/001-demo/spec.md ) 2>&1 )"; rc=$?
assert_exit_code 2 "$rc" "private codename in the body aborts (exit 2)"
assert_contains "$out" "de-identification gate found a leak" "gate explains the abort"
rm -rf "$w"; w=""

# ---------------------------------------------------------------------------
# 4) gh-backed paths: idempotency (existing issue -> skip, no create) + create
# ---------------------------------------------------------------------------
bin="$(mktemp -d)"
cat > "$bin/gh" <<'STUB'
#!/usr/bin/env bash
if [ "$1" = issue ] && [ "$2" = list ]; then printf '%s\n' "${GH_FAKE_EXISTING:-}"; exit 0; fi
if [ "$1" = issue ] && [ "$2" = create ]; then
  shift 2; printf '%s\n' "$@" > "${GH_ARGS_FILE:?}"; echo "https://github.com/dbrami/destrier/issues/123"; exit 0
fi
exit 0
STUB
chmod +x "$bin/gh"

# 4a) existing issue -> skip, never create
w="$(mktemp -d)"; make_spec "$w"; argf="$w/created.args"; rm -f "$argf"
out="$( ( cd "$w" && PATH="$bin:$PATH" GH_FAKE_EXISTING="https://github.com/x/y/issues/99" GH_ARGS_FILE="$argf" bash "$S2I" specs/001-demo/spec.md ) 2>&1 )"; rc=$?
assert_exit_code 0 "$rc" "existing-issue run exits 0"
assert_contains "$out" "already references" "reports the existing issue"
if [ -f "$argf" ]; then fail "must NOT create when an issue already exists"; else echo "  ok: no create when an issue already exists"; fi
rm -rf "$w"; w=""

# 4b) no existing issue -> create with title + labels from config
w="$(mktemp -d)"; make_spec "$w"; argf="$w/created.args"; rm -f "$argf"
mkdir -p "$w/.destrier"; printf 'ISSUE_LABELS=type/feature\n' > "$w/.destrier/issue.config"
out="$( ( cd "$w" && PATH="$bin:$PATH" GH_FAKE_EXISTING="" GH_ARGS_FILE="$argf" bash "$S2I" specs/001-demo/spec.md ) 2>&1 )"; rc=$?
assert_exit_code 0 "$rc" "create run exits 0"
assert_contains "$out" "created https://github.com/dbrami/destrier/issues/123" "reports the created issue URL"
assert_contains "$out" "Closes 123" "suggests the PR Closes line"
args="$(cat "$argf" 2>/dev/null)"
assert_contains "$args" "--title" "create passes a title"
assert_contains "$args" "--body-file" "create passes a body file"
assert_contains "$args" "type/feature" "create passes the configured label"
rm -rf "$w"; w=""

pass "spec-to-issue"
