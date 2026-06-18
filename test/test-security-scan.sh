#!/usr/bin/env bash
# Tests for scripts/security-scan.sh.
# Fixtures that would otherwise trip the scanner are built at runtime with a
# split prefix, so this test SOURCE file stays scan-clean while the generated
# file content still matches the denylist.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
. "$HERE/lib.sh"

SCAN="$ROOT/scripts/security-scan.sh"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
home='/Users/'   # split so the literal pattern is not present in this source

# 1) Clean tree passes
echo "just generic code" > "$tmp/clean.txt"
"$SCAN" --tree "$tmp" --quiet
assert_exit_code 0 $? "clean tree passes"

# 2) Absolute home path is caught (generic structural rule)
printf '%ssomeone/Projects/secretthing\n' "$home" > "$tmp/leak.txt"
"$SCAN" --tree "$tmp" --quiet
assert_exit_code 2 $? "absolute home path flagged"
rm -f "$tmp/leak.txt"

# 3) A private-denylist codename is caught (custom denylist via env)
echo "ACME_CODENAME secret project" > "$tmp/leak2.txt"
printf 'ACME_CODENAME\n' > "$tmp/priv.txt"
CODEMAN_PRIVATE_DENYLIST="$tmp/priv.txt" "$SCAN" --tree "$tmp" --quiet
assert_exit_code 2 $? "private-denylist codename flagged"
rm -f "$tmp/leak2.txt" "$tmp/priv.txt"

# 4) Secret pattern (private key header) is caught
hdr='-----BEGIN RSA'
printf '%s PRIVATE KEY-----\n' "$hdr" > "$tmp/key.txt"
"$SCAN" --tree "$tmp" --quiet
assert_exit_code 2 $? "private key header flagged"
rm -f "$tmp/key.txt"

# 5) The allowlisted public repo slug does NOT trip the scan
echo "install via dbrami/codeman" > "$tmp/ok.txt"
"$SCAN" --tree "$tmp" --quiet
assert_exit_code 0 $? "dbrami/codeman allowlisted"

pass "security-scan"
