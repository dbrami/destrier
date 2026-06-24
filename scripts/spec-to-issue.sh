#!/usr/bin/env bash
# spec-to-issue.sh — turn a spec-kit spec.md into ONE structured GitHub issue.
#
# Optional, opt-in feature->issue bridge: the "every feature becomes a tracked
# structured issue before implementation" practice, generalized. By default the
# spec.md stays the canonical source of truth and the issue LINKS + summarizes it;
# a per-repo config can opt into a fuller body.
#
# Usage:
#   spec-to-issue.sh [--dry-run|--check] [SPEC_PATH]
#     SPEC_PATH   path to a spec.md (default: newest specs/*/spec.md in cwd)
#     --dry-run   print the issue it would create; make NO gh calls
#
# Config (optional, per-repo, gitignored): .destrier/issue.config — KEY=VALUE:
#   ISSUE_LABELS=a,b   ISSUE_PROJECT=...   ISSUE_BODY=summary|full
#   ISSUE_ASSIGNEE=... ISSUE_MILESTONE=... ISSUE_TITLE_PREFIX=...
# Generic defaults (no labels/project, summary body) when absent. Project-specific
# values stay in the project's own .destrier/issue.config, never in destrier.
#
# Privacy: the spec is published to GitHub, so the de-identification/secret scan
# runs on the generated body first and ABORTS on any finding. bash 3.2-safe.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCAN="$HERE/security-scan.sh"

DRY_RUN=0
SPEC=""
for a in "$@"; do
  case "$a" in
    --dry-run|--check) DRY_RUN=1 ;;
    -*) echo "spec-to-issue: unknown arg: $a" >&2; exit 64 ;;
    *)  SPEC="$a" ;;
  esac
done

command -v rg >/dev/null 2>&1 || { echo "spec-to-issue: ripgrep (rg) required" >&2; exit 64; }

# Locate the spec.
if [ -z "$SPEC" ]; then
  # Newest specs/*/spec.md by mtime (portable; no GNU-only flags).
  SPEC="$(ls -t specs/*/spec.md 2>/dev/null | head -1 || true)"
fi
if [ -z "$SPEC" ] || [ ! -f "$SPEC" ]; then
  echo "spec-to-issue: no spec.md found (pass a path or run from a repo with specs/*/spec.md)." >&2
  exit 1
fi

# --- config (parsed, NOT sourced, so the file can't execute code) ---
CFG=".destrier/issue.config"
cfg_get() { # KEY -> last value, surrounding quotes stripped
  [ -f "$CFG" ] || return 0
  sed -n "s/^$1=//p" "$CFG" | tail -1 | sed "s/^[\"']//; s/[\"']$//"
}
LABELS="$(cfg_get ISSUE_LABELS)"
PROJECT="$(cfg_get ISSUE_PROJECT)"
BODY_MODE="$(cfg_get ISSUE_BODY)"; [ -n "$BODY_MODE" ] || BODY_MODE="summary"
ASSIGNEE="$(cfg_get ISSUE_ASSIGNEE)"
MILESTONE="$(cfg_get ISSUE_MILESTONE)"
TITLE_PREFIX="$(cfg_get ISSUE_TITLE_PREFIX)"

# --- derive title + body from the spec ---
FEATURE="$(sed -n 's/^# Feature Specification: //p' "$SPEC" | head -1)"
[ -n "$FEATURE" ] || FEATURE="$(basename "$(dirname "$SPEC")")"
TITLE="${TITLE_PREFIX}${FEATURE}"

SUMMARY="$(sed -n 's/^\*\*Input\*\*:[[:space:]]*//p' "$SPEC" | head -1 | sed 's/^User description:[[:space:]]*//; s/^"//; s/"$//')"
[ -n "$SUMMARY" ] || SUMMARY="See the linked spec for the full description."

# Acceptance-criteria checklist: Success Criteria (SC-*) if present, else FRs.
checklist() { # item-prefix (SC|FR)
  awk -v p="$1" '
    $0 ~ "^## " {
      if (insec && buf!="") { print "- [ ] " buf; buf="" }
      insec = ($0 ~ "## Success Criteria" || $0 ~ "## Requirements") ? 1 : 0
      next
    }
    insec==0 { next }
    /^### / || /^<!--/ { next }
    $0 ~ ("^- \\*\\*" p "-[0-9]+\\*\\*:") {
      if (buf!="") print "- [ ] " buf
      line=$0; sub("^- \\*\\*" p "-[0-9]+\\*\\*:[ ]*","",line); buf=line; next
    }
    /^[ \t]+[^ \t]/ { c=$0; gsub(/^[ \t]+/,"",c); if (buf!="") buf=buf " " c; next }
    /^$/ { if (buf!="") { print "- [ ] " buf; buf="" } next }
    END { if (buf!="") print "- [ ] " buf }
  ' "$SPEC"
}
CHECK="$(checklist SC)"
[ -n "$CHECK" ] || CHECK="$(checklist FR)"

# Build the body.
bodyfile="$(mktemp)"; trap 'rm -f "$bodyfile"' EXIT
if [ "$BODY_MODE" = full ]; then
  { printf 'Source spec (canonical): `%s`\n\n' "$SPEC"; cat "$SPEC"; } > "$bodyfile"
else
  {
    printf '%s\n\n' "$SUMMARY"
    if [ -n "$CHECK" ]; then printf '## Acceptance criteria\n\n%s\n\n' "$CHECK"; fi
    printf '## Source\n\nSpec (canonical source of truth): `%s`\n' "$SPEC"
  } > "$bodyfile"
fi

# --- privacy gate: scan the exact body that would be published ---
if [ -f "$SCAN" ]; then
  scan_out="$(bash "$SCAN" --tree "$bodyfile" 2>/dev/null)"; scan_rc=$?
  if [ "$scan_rc" = 2 ]; then
    echo "spec-to-issue: de-identification gate found a leak in the issue body; NOT creating the issue." >&2
    printf '%s\n' "$scan_out" | sed 's/^/  /' >&2
    echo "  Fix the spec (and set DESTRIER_PRIVATE_DENYLIST for private codenames), then retry." >&2
    exit 2
  fi
fi

# --- dry run: show, make no gh calls ---
if [ "$DRY_RUN" = 1 ]; then
  echo "DRY RUN — would create this issue (no gh calls):"
  echo "  title: $TITLE"
  [ -n "$LABELS" ]    && echo "  labels: $LABELS"
  [ -n "$PROJECT" ]   && echo "  project: $PROJECT"
  [ -n "$ASSIGNEE" ]  && echo "  assignee: $ASSIGNEE"
  [ -n "$MILESTONE" ] && echo "  milestone: $MILESTONE"
  echo "  body:"
  sed 's/^/    /' "$bodyfile"
  exit 0
fi

command -v gh >/dev/null 2>&1 || { echo "spec-to-issue: gh (GitHub CLI) required to create issues; use --dry-run to preview." >&2; exit 64; }

# --- idempotency: reuse an existing issue that already references this spec ---
existing="$(gh issue list --state all --search "$SPEC in:body" --json url --jq '.[0].url' 2>/dev/null || true)"
if [ -n "$existing" ]; then
  echo "spec-to-issue: an issue already references $SPEC — $existing (skipping)."
  exit 0
fi

# --- create ---
set -- --title "$TITLE" --body-file "$bodyfile"
[ -n "$PROJECT" ]   && set -- "$@" --project "$PROJECT"
[ -n "$ASSIGNEE" ]  && set -- "$@" --assignee "$ASSIGNEE"
[ -n "$MILESTONE" ] && set -- "$@" --milestone "$MILESTONE"
# Split comma-separated labels into repeated --label flags (bash 3.2-safe).
if [ -n "$LABELS" ]; then
  oldIFS="$IFS"; IFS=','
  for l in $LABELS; do
    l="$(printf '%s' "$l" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
    [ -n "$l" ] && set -- "$@" --label "$l"
  done
  IFS="$oldIFS"
fi

url="$(gh issue create "$@")" || { echo "spec-to-issue: gh issue create failed" >&2; exit 1; }
echo "spec-to-issue: created $url"
echo "  Link it from your PR with: Closes ${url##*/}"
