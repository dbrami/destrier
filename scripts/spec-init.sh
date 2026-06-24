#!/usr/bin/env bash
# spec-init.sh — opt-in Spec-Driven Development (SDD) for the CURRENT repo.
#
# Bootstraps GitHub spec-kit's pinned `specify` CLI (no vendoring, same MO as
# gitnexus/roborev), runs `specify init` idempotently, and registers destrier's
# spec-kit bridge extension (spec-kit-ext/). Never forks a spec-kit command, so
# `specify self upgrade` keeps working.
#
# Usage:
#   spec-init.sh           verify prereqs, install/init, register the extension
#   spec-init.sh --check   verify prereqs only (no install, no writes)
#
# Conventions mirror destrier's other scripts: bash 3.2-safe (no mapfile / no
# associative arrays), DESTRIER_FAKE_* test seams, runs in the user repo cwd and
# locates shipped assets via ${CLAUDE_PLUGIN_ROOT}.
#
# Pinned spec-kit tag below. Upgrade ONLY via `specify self upgrade --tag <tag>`
# and bump spec-kit-ext/extension.yml's requires range in lockstep.
set -uo pipefail

SPECKIT_TAG="v0.11.6"
SPECKIT_REF="git+https://github.com/github/spec-kit.git@${SPECKIT_TAG}"

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$ROOT}"
EXT_DIR="$PLUGIN_ROOT/spec-kit-ext"
EXT_ID="destrier-sdd"
VALUES="$PLUGIN_ROOT/templates/destrier-constitution-values.md"

MODE=run
for a in "$@"; do
  case "$a" in
    --check) MODE=check;;
    *) echo "spec-init: unknown arg: $a" >&2; exit 64;;
  esac
done

# have(): true if a command exists. DESTRIER_FAKE_MISSING (space-separated tool
# names) forces specific tools to read as missing — a test seam only.
have() {
  case " ${DESTRIER_FAKE_MISSING:-} " in *" $1 "*) return 1;; esac
  command -v "$1" >/dev/null 2>&1
}

# python3 >= 3.11 (spec-kit's floor). DESTRIER_FAKE_PY_OLD=1 forces the too-old
# path for tests.
py_ok() {
  [ "${DESTRIER_FAKE_PY_OLD:-0}" = 1 ] && return 1
  have python3 || return 1
  python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3, 11) else 1)' 2>/dev/null
}

# --- prerequisite verification (uv, python3>=3.11, git) ---
MISSING=0
echo "destrier SDD prerequisite check"

if have uv; then
  printf '  %-9s ok\n' uv
else
  printf '  %-9s MISSING — install: %s\n' uv "curl -LsSf https://astral.sh/uv/install.sh | sh   (or: brew install uv)"
  MISSING=1
fi

if py_ok; then
  printf '  %-9s ok\n' python3
elif have python3; then
  ver="$(python3 -c 'import sys; print("%d.%d" % sys.version_info[:2])' 2>/dev/null || echo '?')"
  printf '  %-9s TOO OLD (%s; need >= 3.11) — install a newer Python 3\n' python3 "$ver"
  MISSING=1
else
  printf '  %-9s MISSING — install Python >= 3.11\n' python3
  MISSING=1
fi

if have git; then
  printf '  %-9s ok\n' git
else
  printf '  %-9s MISSING — required by specify init\n' git
  MISSING=1
fi

if [ "$MISSING" -ne 0 ]; then
  echo ""
  echo "Install the missing prerequisites above, then re-run /destrier-spec-init."
  # --check is report-only (exit 0, like bootstrap --check); a real run cannot proceed.
  [ "$MODE" = check ] && exit 0
  exit 1
fi

if [ "$MODE" = check ]; then
  echo "(--check) prerequisites satisfied; no changes made."
  exit 0
fi

# Extension assets must be present in the plugin before we touch the project.
[ -f "$EXT_DIR/extension.yml" ] || {
  echo "spec-init: bridge extension not found at $EXT_DIR" >&2; exit 1; }

# --- 1. pinned specify CLI (no vendoring) ---
if have specify; then
  echo "specify already installed; leaving it as-is (upgrade with: specify self upgrade --tag $SPECKIT_TAG)."
else
  echo "Installing specify CLI ($SPECKIT_TAG) via uv ..."
  uv tool install specify-cli --from "$SPECKIT_REF" || {
    echo "spec-init: failed to install specify-cli" >&2; exit 1; }
fi

# --- 2. idempotent project init ---
if [ -d ".specify" ]; then
  echo ".specify/ already present; skipping 'specify init' (constitution & specs preserved)."
else
  echo "Initializing Spec-Driven Development in $(pwd) ..."
  # --force skips the non-empty-dir confirmation (which would hang a
  # non-interactive run). init writes only spec-kit's own files and preserves an
  # existing constitution; it never touches specs/.
  specify init . --integration claude --force || {
    echo "spec-init: 'specify init' failed" >&2; exit 1; }
fi

# --- 3. register destrier's bridge extension (idempotent) ---
DEST_EXT=".specify/extensions/$EXT_ID"
if [ -d "$DEST_EXT" ]; then
  echo "Re-registering destrier-sdd extension (--force) ..."
  specify extension add "$EXT_DIR" --dev --force || echo "  (extension update failed; continuing)"
else
  echo "Installing destrier-sdd extension ..."
  specify extension add "$EXT_DIR" --dev || echo "  (extension install failed; continuing)"
fi

# --- 4. record the destrier plugin root for the bridge commands ---
if [ -d "$DEST_EXT" ]; then
  printf '%s\n' "$PLUGIN_ROOT" > "$DEST_EXT/.destrier-root"
else
  echo "spec-init: extension not installed; bridges (kb-stub/metrics) will be inert." >&2
fi

# --- 5. next steps ---
echo ""
echo "Spec-Driven Development is ready in this repo."
echo "Next:"
echo "  1. Establish principles — run /speckit.constitution and feed it destrier's"
echo "     house rules from:"
echo "       $VALUES"
echo "  2. /speckit.specify -> /speckit.clarify -> /speckit.plan -> /speckit.tasks -> /speckit.implement"
echo ""
echo "Privacy: set DESTRIER_PRIVATE_DENYLIST before authoring specs — spec free-text"
echo "is committed and scanned; private codenames must not leak into a public repo."
