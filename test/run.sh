#!/usr/bin/env bash
# Run every test/test-*.sh and report an aggregate result.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
rc=0
for t in "$HERE"/test-*.sh; do
  [ -e "$t" ] || continue
  echo "=== $(basename "$t") ==="
  bash "$t" || rc=1
done
if [ "$rc" = 0 ]; then echo "ALL TESTS PASSED"; else echo "SOME TESTS FAILED"; fi
exit "$rc"
