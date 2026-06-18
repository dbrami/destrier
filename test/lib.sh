#!/usr/bin/env bash
# Minimal assert helpers for codeman's plain-bash test suite.
# Each assert prints an ok/FAIL line; any failure flips _FAILED and the
# EXIT trap exits non-zero so the runner can detect it.
_FAILED=0
pass()  { echo "PASS: $1"; }
fail()  { echo "FAIL: $1" >&2; _FAILED=1; }
assert_exit_code() { # expected actual msg
  if [ "$1" = "$2" ]; then echo "  ok: $3 (exit $2)"; else fail "$3 (expected exit $1, got $2)"; fi
}
assert_eq() { # expected actual msg
  if [ "$1" = "$2" ]; then echo "  ok: $3"; else fail "$3 (expected '$1', got '$2')"; fi
}
assert_contains() { # haystack needle msg
  if printf '%s' "$1" | grep -qF -- "$2"; then echo "  ok: $3"; else fail "$3 (missing '$2')"; fi
}
trap '[ "$_FAILED" = 0 ] || exit 1' EXIT
