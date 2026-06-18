#!/usr/bin/env bash
# Reusable de-identification + secret scan. Shared by the test suite, the
# /codeman-security-review command, and the pre-commit gate.
#
# Usage:
#   security-scan.sh --tree <dir>   scan all (non-ignored) files under <dir>
#   security-scan.sh --staged       scan the staged git diff
#   add --quiet to suppress output (exit code only)
#
# Exit: 0 = clean, 2 = findings, 64 = usage/prereq error.
#
# Patterns come from a GENERIC shipped denylist plus an optional PRIVATE
# (gitignored) denylist of the author's real codenames. The literal public
# repo slug "dbrami/codeman" is allowlisted.
set -uo pipefail

MODE="tree"; TARGET="."; QUIET=0
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
DENYLIST="${CODEMAN_DENYLIST:-$ROOT/templates/identifying-tokens.denylist}"
PRIVATE="${CODEMAN_PRIVATE_DENYLIST:-$ROOT/dev/private-denylist.txt}"
ALLOW='dbrami/codeman'

while [ $# -gt 0 ]; do
  case "$1" in
    --tree)   MODE="tree"; TARGET="$2"; shift 2;;
    --staged) MODE="staged"; shift;;
    --quiet)  QUIET=1; shift;;
    *) echo "security-scan: unknown arg: $1" >&2; exit 64;;
  esac
done

command -v rg >/dev/null 2>&1 || { echo "security-scan: ripgrep (rg) required" >&2; exit 64; }

patfile="$(mktemp)"; content="$(mktemp)"
trap 'rm -f "$patfile" "$content"' EXIT
{ [ -f "$DENYLIST" ] && grep -vE '^[[:space:]]*(#|$)' "$DENYLIST"
  [ -f "$PRIVATE" ]  && grep -vE '^[[:space:]]*(#|$)' "$PRIVATE"; } > "$patfile" 2>/dev/null

if [ ! -s "$patfile" ]; then
  [ "$QUIET" = 0 ] && echo "security-scan: empty denylist; nothing to check" >&2
  exit 0
fi

excl_deny="$(basename "$DENYLIST")"
excl_priv="$(basename "$PRIVATE")"

if [ "$MODE" = "staged" ]; then
  git diff --cached -U0 > "$content" 2>/dev/null || true
  hits="$(rg -n -i -f "$patfile" "$content" 2>/dev/null | grep -vF "$ALLOW" || true)"
else
  hits="$(rg -n -i --hidden -f "$patfile" "$TARGET" \
      --glob '!.git' \
      --glob "!$excl_deny" \
      --glob "!$excl_priv" \
      2>/dev/null | grep -vF "$ALLOW" || true)"
fi

if [ -n "$hits" ]; then
  if [ "$QUIET" = 0 ]; then
    echo "SECURITY-SCAN: FINDINGS"
    printf '%s\n' "$hits" | sed 's/^/FINDING: /'
  fi
  exit 2
fi
[ "$QUIET" = 0 ] && echo "SECURITY-SCAN: clean"
exit 0
