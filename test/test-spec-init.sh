#!/usr/bin/env bash
# Tests for the Spec-Driven Development integration: the destrier-sdd spec-kit
# extension manifest, scripts/spec-init.sh prereq detection + idempotency, and the
# security gate over spec-style artifacts.
#
# The idempotency test stubs `specify`/`uv` on PATH so it runs hermetically (no
# network, no real spec-kit). Fixtures that would trip the security scanner are
# built at runtime with a split prefix so this SOURCE file stays scan-clean.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$HERE/.." && pwd)"
. "$HERE/lib.sh"

EXT="$ROOT/spec-kit-ext/extension.yml"
SPEC_INIT="$ROOT/scripts/spec-init.sh"
SCAN="$ROOT/scripts/security-scan.sh"

# Single cleanup trap (lib.sh leaves the EXIT trap to each test). Only non-empty
# paths are removed, so it is safe whether or not a section ran.
bin=""; work=""; sd=""
_cleanup() { for d in "$bin" "$work" "$sd"; do [ -n "$d" ] && rm -rf "$d"; done; }
trap _cleanup EXIT

# ---------------------------------------------------------------------------
# 1) Extension manifest invariants
# ---------------------------------------------------------------------------
man="$(cat "$EXT")"
assert_contains "$man" 'schema_version: "1.0"' "manifest declares schema_version 1.0"
assert_contains "$man" 'id: destrier-sdd'      "extension id is destrier-sdd"

# id must match ^[a-z0-9-]+$
idval="$(grep -E '^[[:space:]]*id:' "$EXT" | head -1 | sed 's/.*id:[[:space:]]*//')"
if printf '%s' "$idval" | grep -qE '^[a-z0-9-]+$'; then
  echo "  ok: id matches ^[a-z0-9-]+\$"
else
  fail "id '$idval' violates ^[a-z0-9-]+\$"
fi

# speckit_version must be a RANGE, never ==
rangeval="$(grep -E '^[[:space:]]*speckit_version:' "$EXT" | sed 's/.*speckit_version:[[:space:]]*//')"
assert_contains "$rangeval" '>=' "speckit_version has a lower bound"
assert_contains "$rangeval" '<'  "speckit_version has an upper bound"
if printf '%s' "$rangeval" | grep -qF '=='; then fail "speckit_version must not pin with =="; else echo "  ok: speckit_version is a range, not =="; fi

# Both bridge commands are provided AND their referencing hooks exist
for c in speckit.destrier-sdd.kb-stub speckit.destrier-sdd.metrics; do
  assert_contains "$man" "$c" "provides command $c"
done
assert_contains "$man" "after_plan:"          "registers after_plan hook"
assert_contains "$man" "after_taskstoissues:" "registers after_taskstoissues hook"

# Every command file named by provides[].file exists on disk
for f in commands/speckit.destrier-sdd.kb-stub.md commands/speckit.destrier-sdd.metrics.md; do
  if [ -f "$ROOT/spec-kit-ext/$f" ]; then echo "  ok: $f exists"; else fail "missing command file $f"; fi
done

# ---------------------------------------------------------------------------
# 2) Pin <-> range coherence (version guard): the pinned tag's MAJOR.MINOR must
#    sit inside the extension's requires range, so a pin bump that forgets the
#    range fails CI.
# ---------------------------------------------------------------------------
tag="$(grep -E '^SPECKIT_TAG=' "$SPEC_INIT" | sed 's/.*"v\([0-9.]*\)".*/\1/')"
mm="$(printf '%s' "$tag" | cut -d. -f1-2)"
maj="$(printf '%s' "$mm" | cut -d. -f1)"; min="$(printf '%s' "$mm" | cut -d. -f2)"
nextmm="$maj.$((min + 1))"
# Validate BOTH bounds so the install pin (SPECKIT_TAG) and the compat range
# cannot drift: lower bound == the pinned minor, upper bound == the next minor.
assert_contains "$rangeval" ">=$mm"     "range lower bound matches the pinned tag minor ($mm)"
assert_contains "$rangeval" "<$nextmm"  "range upper bound is the next minor ($nextmm)"

# ---------------------------------------------------------------------------
# 3) Prereq detection (test seams; env-independent)
# ---------------------------------------------------------------------------
out="$(bash "$SPEC_INIT" badarg 2>&1)"; rc=$?
assert_exit_code 64 "$rc" "unknown arg exits 64"

out="$(DESTRIER_FAKE_MISSING=uv bash "$SPEC_INIT" --check 2>&1)"; rc=$?
assert_exit_code 0 "$rc" "--check is report-only (exit 0) with uv missing"
assert_contains "$out" "MISSING" "missing uv reported as MISSING"
assert_contains "$out" "astral.sh/uv/install.sh" "uv MISSING shows the official installer"

out="$(DESTRIER_FAKE_PY_OLD=1 bash "$SPEC_INIT" --check 2>&1)"; rc=$?
assert_exit_code 0 "$rc" "--check exit 0 with python too old"
assert_contains "$out" "3.11" "python floor (3.11) surfaced when too old"

# ---------------------------------------------------------------------------
# 4) Idempotency (hermetic: stub specify + uv on PATH)
# ---------------------------------------------------------------------------
if python3 -c 'import sys; sys.exit(0 if sys.version_info>=(3,11) else 1)' 2>/dev/null && command -v git >/dev/null 2>&1; then
  bin="$(mktemp -d)"; work="$(mktemp -d)"
  ( cd "$work" && git init -q )
  # Stub reports an in-range version so the pre-init compat gate passes.
  cat > "$bin/specify" <<'STUB'
#!/usr/bin/env bash
case "$1" in
  --version) echo "specify 0.11.6" ;;
  init)      mkdir -p .specify/memory ;;
  extension) mkdir -p .specify/extensions/destrier-sdd ;;
esac
exit 0
STUB
  printf '#!/usr/bin/env bash\nexit 0\n' > "$bin/uv"
  chmod +x "$bin/specify" "$bin/uv"

  run_init() { ( cd "$work" && PATH="$bin:$PATH" CLAUDE_PLUGIN_ROOT="$ROOT" bash "$SPEC_INIT" ); }

  o1="$(run_init 2>&1)"; r1=$?
  assert_exit_code 0 "$r1" "first run succeeds"
  assert_contains "$o1" "ready in this repo" "first run reports SDD ready (extension installed)"
  if [ -f "$work/.git/destrier-root" ]; then echo "  ok: destrier-root recorded in the git dir"; else fail "destrier-root not written to .git"; fi
  assert_eq "$ROOT" "$(cat "$work/.git/destrier-root" 2>/dev/null)" "destrier-root points at plugin root"
  # Privacy: the absolute-path pointer must NOT live in the working tree.
  if [ -e "$work/.specify/extensions/destrier-sdd/.destrier-root" ]; then fail "root pointer must not live under the working tree"; else echo "  ok: no absolute-path pointer in the working tree"; fi

  # Seed a constitution, then re-run: init is idempotent and the file is preserved.
  printf 'SENTINEL-CONSTITUTION\n' > "$work/.specify/memory/constitution.md"
  o2="$(run_init 2>&1)"; r2=$?
  assert_exit_code 0 "$r2" "second run succeeds (idempotent)"
  assert_eq "SENTINEL-CONSTITUTION" "$(cat "$work/.specify/memory/constitution.md")" "existing constitution preserved on re-run"

  # Migration: a legacy working-tree pointer left by an older spec-init must be
  # removed once the leak-safe git-dir pointer is written.
  workm="$(mktemp -d)"
  ( cd "$workm" && git init -q && mkdir -p .specify/extensions/destrier-sdd && printf '/old/leaked/home/path\n' > .specify/extensions/destrier-sdd/.destrier-root )
  o7="$( ( cd "$workm" && PATH="$bin:$PATH" CLAUDE_PLUGIN_ROOT="$ROOT" bash "$SPEC_INIT" ) 2>&1 )"; r7=$?
  assert_exit_code 0 "$r7" "migration run succeeds"
  if [ -e "$workm/.specify/extensions/destrier-sdd/.destrier-root" ]; then fail "legacy working-tree pointer not removed on migration"; else echo "  ok: legacy working-tree pointer removed on migration"; fi
  assert_eq "$ROOT" "$(cat "$workm/.git/destrier-root" 2>/dev/null)" "git-dir pointer written on migration"
  rm -rf "$workm"

  # If the legacy pointer cannot be removed (here: it's a non-empty dir, so `rm -f`
  # without -r fails), the script must report it and exit non-zero, not claim ready.
  workr="$(mktemp -d)"
  ( cd "$workr" && git init -q && mkdir -p .specify/extensions/destrier-sdd/.destrier-root/keep )
  o9="$( ( cd "$workr" && PATH="$bin:$PATH" CLAUDE_PLUGIN_ROOT="$ROOT" bash "$SPEC_INIT" ) 2>&1 )"; r9=$?
  rm -rf "$workr"
  assert_exit_code 1 "$r9" "unremovable legacy pointer exits non-zero"
  assert_contains "$o9" "could not remove the legacy pointer" "legacy-pointer removal failure is reported"

  # An incompatible specify version must fail BEFORE any repo mutation.
  cat > "$bin/specify" <<'STUB'
#!/usr/bin/env bash
case "$1" in
  --version) echo "specify 0.10.9" ;;
  init)      mkdir -p .specify/memory ;;
  extension) mkdir -p .specify/extensions/destrier-sdd ;;
esac
exit 0
STUB
  chmod +x "$bin/specify"
  workv="$(mktemp -d)"; ( cd "$workv" && git init -q )
  o4="$( ( cd "$workv" && PATH="$bin:$PATH" CLAUDE_PLUGIN_ROOT="$ROOT" bash "$SPEC_INIT" ) 2>&1 )"; r4=$?
  assert_exit_code 1 "$r4" "too-old specify version exits non-zero"
  assert_contains "$o4" "outside destrier's supported range" "version gate explains the mismatch (too old)"
  if [ -e "$workv/.specify" ]; then fail "repo was mutated despite an incompatible version"; else echo "  ok: no repo mutation on too-old version"; fi
  rm -rf "$workv"

  # A version at/above the range's upper bound must also be rejected (both bounds).
  cat > "$bin/specify" <<'STUB'
#!/usr/bin/env bash
case "$1" in
  --version) echo "specify 0.12.0" ;;
  init)      mkdir -p .specify/memory ;;
  extension) mkdir -p .specify/extensions/destrier-sdd ;;
esac
exit 0
STUB
  chmod +x "$bin/specify"
  workn="$(mktemp -d)"; ( cd "$workn" && git init -q )
  o8="$( ( cd "$workn" && PATH="$bin:$PATH" CLAUDE_PLUGIN_ROOT="$ROOT" bash "$SPEC_INIT" ) 2>&1 )"; r8=$?
  assert_exit_code 1 "$r8" "too-new specify version (>= upper bound) exits non-zero"
  if [ -e "$workn/.specify" ]; then fail "repo was mutated despite a too-new version"; else echo "  ok: no repo mutation on too-new version"; fi
  rm -rf "$workn"

  # A failing extension install must surface as a non-zero exit (not a false "ready").
  cat > "$bin/specify" <<'STUB'
#!/usr/bin/env bash
case "$1" in
  --version) echo "specify 0.11.6" ;;
  init)      mkdir -p .specify/memory ;;
  extension) exit 3 ;;   # simulate extension registration failure
esac
exit 0
STUB
  chmod +x "$bin/specify"
  work2="$(mktemp -d)"; ( cd "$work2" && git init -q )
  o3="$( ( cd "$work2" && PATH="$bin:$PATH" CLAUDE_PLUGIN_ROOT="$ROOT" bash "$SPEC_INIT" ) 2>&1 )"; r3=$?
  rm -rf "$work2"
  assert_exit_code 1 "$r3" "extension install failure exits non-zero"
  assert_contains "$o3" "bridge extension is NOT" "partial install is reported honestly"

  # An unparseable `specify --version` must fail closed (not silently skip compat).
  cat > "$bin/specify" <<'STUB'
#!/usr/bin/env bash
case "$1" in
  --version) echo "specify (unknown build)" ;;
  init)      mkdir -p .specify/memory ;;
  extension) mkdir -p .specify/extensions/destrier-sdd ;;
esac
exit 0
STUB
  chmod +x "$bin/specify"
  worku="$(mktemp -d)"; ( cd "$worku" && git init -q )
  o5="$( ( cd "$worku" && PATH="$bin:$PATH" CLAUDE_PLUGIN_ROOT="$ROOT" bash "$SPEC_INIT" ) 2>&1 )"; r5=$?
  assert_exit_code 1 "$r5" "unparseable version fails closed"
  assert_contains "$o5" "could not determine the installed specify version" "unparseable version is reported"
  if [ -e "$worku/.specify" ]; then fail "repo was mutated despite an unparseable version"; else echo "  ok: no repo mutation on unparseable version"; fi
  rm -rf "$worku"

  # A failed root-pointer write must be surfaced (not a false "ready"). Make the
  # target a directory so the redirect fails.
  cat > "$bin/specify" <<'STUB'
#!/usr/bin/env bash
case "$1" in
  --version) echo "specify 0.11.6" ;;
  init)      mkdir -p .specify/memory ;;
  extension) mkdir -p .specify/extensions/destrier-sdd ;;
esac
exit 0
STUB
  chmod +x "$bin/specify"
  workw="$(mktemp -d)"; ( cd "$workw" && git init -q && mkdir -p .git/destrier-root )
  o6="$( ( cd "$workw" && PATH="$bin:$PATH" CLAUDE_PLUGIN_ROOT="$ROOT" bash "$SPEC_INIT" ) 2>&1 )"; r6=$?
  rm -rf "$workw"
  assert_exit_code 1 "$r6" "failed root-pointer write exits non-zero"
  assert_contains "$o6" "failed to record the destrier root" "root-write failure is reported"
else
  echo "  skip: idempotency (needs python3>=3.11 + git)"
fi

# ---------------------------------------------------------------------------
# 5) Security gate catches a private codename in a spec-style artifact
# ---------------------------------------------------------------------------
sd="$(mktemp -d)"
mkdir -p "$sd/specs/001-demo"
echo "ACME_CODENAME appears in this spec's free text" > "$sd/specs/001-demo/spec.md"
printf 'ACME_CODENAME\n' > "$sd/priv.txt"
DESTRIER_PRIVATE_DENYLIST="$sd/priv.txt" "$SCAN" --tree "$sd" --quiet
assert_exit_code 2 $? "private codename in a spec is flagged by the gate"

pass "spec-init"
