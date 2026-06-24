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

# SDD requires a git repository: spec-kit's feature/branch workflow needs it, and
# the bridge commands locate destrier via a pointer stored inside the git dir.
GIT_DIR="$(git rev-parse --git-dir 2>/dev/null || true)"
if [ -z "$GIT_DIR" ]; then
  echo "spec-init: this is not a git repository. Run 'git init' first, then /destrier-spec-init." >&2
  exit 1
fi

# --- 1. pinned specify CLI (no vendoring) ---
PIN_MM="$(printf '%s' "$SPECKIT_TAG" | sed 's/^v//' | cut -d. -f1-2)"   # e.g. 0.11
if have specify; then
  echo "specify already installed."
else
  echo "Installing specify CLI ($SPECKIT_TAG) via uv ..."
  uv tool install specify-cli --from "$SPECKIT_REF" || {
    echo "spec-init: failed to install specify-cli" >&2; exit 1; }
  # uv installs tool executables into its tool-bin dir, which may not be on the
  # current shell PATH yet (fresh uv setups). Make `specify` resolvable for the
  # remainder of this run.
  if ! command -v specify >/dev/null 2>&1; then
    UVBIN="$(uv tool dir --bin 2>/dev/null || true)"
    [ -n "$UVBIN" ] && [ -d "$UVBIN" ] && PATH="$UVBIN:$PATH"
    [ -d "$HOME/.local/bin" ] && PATH="$HOME/.local/bin:$PATH"
    export PATH
  fi
fi

# `specify` must be resolvable before we touch the repo; if not, fail with
# actionable PATH guidance rather than erroring mid-init.
if ! command -v specify >/dev/null 2>&1; then
  echo "spec-init: 'specify' was installed but is not on PATH." >&2
  echo "  Add uv's tool-bin to your PATH (run: uv tool update-shell) and re-run /destrier-spec-init." >&2
  exit 1
fi

# Enforce version compatibility BEFORE any repo mutation: an unsupported version
# would otherwise init the repo and only fail later at `extension add`, leaving a
# partial setup. The compatibility CONTRACT is the bridge extension's `requires`
# range (>=0.11,<0.12 == the $PIN_MM minor); $SPECKIT_TAG (v0.11.6) is only the
# version destrier installs fresh. So any $PIN_MM.x is accepted (matching the
# extension), and we fail CLOSED if no version can be parsed.
SP_VER="$(specify --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
SP_MM="$(printf '%s' "$SP_VER" | cut -d. -f1-2)"
if [ -z "$SP_MM" ]; then
  echo "spec-init: could not determine the installed specify version." >&2
  echo "  Reinstall the pinned CLI, then re-run /destrier-spec-init:" >&2
  echo "    uv tool install specify-cli --force --from $SPECKIT_REF" >&2
  exit 1
fi
if [ "$SP_MM" != "$PIN_MM" ]; then
  echo "spec-init: specify ${SP_VER} is outside destrier's supported range (${PIN_MM}.x; pinned $SPECKIT_TAG)." >&2
  echo "  Upgrade to the pinned version, then re-run /destrier-spec-init:" >&2
  echo "    specify self upgrade --tag $SPECKIT_TAG" >&2
  exit 1
fi

# --- 2. project init (idempotent; self-heals a partial/interrupted init) ---
echo "Initializing Spec-Driven Development in $(pwd) ..."
# --force skips the non-empty-dir confirmation (which would hang a non-interactive
# run) and re-scaffolds any missing pieces. spec-kit preserves an existing
# constitution and never touches specs/, so this is safe to run on every invocation.
specify init . --integration claude --force || {
  echo "spec-init: 'specify init' failed" >&2; exit 1; }

# --- 3. register destrier's bridge extension (idempotent) ---
DEST_EXT=".specify/extensions/$EXT_ID"
EXT_OK=1
if [ -d "$DEST_EXT" ]; then
  echo "Re-registering destrier-sdd extension (--force) ..."
  specify extension add "$EXT_DIR" --dev --force || EXT_OK=0
else
  echo "Installing destrier-sdd extension ..."
  specify extension add "$EXT_DIR" --dev || EXT_OK=0
fi

# --- 4. record the destrier plugin root for the bridge commands ---
# Store it inside the git dir, which is never part of the working tree, so this
# absolute (home) path can never be committed or leak — see the de-identification
# gate. The bridge commands read it back via `git rev-parse --git-dir`.
if [ "$EXT_OK" = 1 ] && [ -d "$DEST_EXT" ]; then
  if ! printf '%s\n' "$PLUGIN_ROOT" > "$GIT_DIR/destrier-root" 2>/dev/null; then
    echo "spec-init: failed to record the destrier root at $GIT_DIR/destrier-root" >&2
    EXT_OK=0
  fi
else
  EXT_OK=0
fi

# --- 5. report (honest about partial installs) + next steps ---
echo ""
if [ "$EXT_OK" = 1 ]; then
  echo "Spec-Driven Development is ready in this repo."
else
  echo "WARNING: spec-kit is initialized, but the destrier bridge extension is NOT" >&2
  echo "installed — the kb-stub/metrics bridges will be inert. Re-run /destrier-spec-init" >&2
  echo "after resolving the error above." >&2
fi
echo "Next:"
echo "  1. Establish principles — run /speckit.constitution and feed it destrier's"
echo "     house rules from:"
echo "       $VALUES"
echo "  2. /speckit.specify -> /speckit.clarify -> /speckit.plan -> /speckit.tasks -> /speckit.implement"
echo ""
echo "Privacy: set DESTRIER_PRIVATE_DENYLIST before authoring specs — spec free-text"
echo "is committed and scanned; private codenames must not leak into a public repo."

# Surface a partial install to the caller (/destrier-spec-init) as a failure.
[ "$EXT_OK" = 1 ] || exit 1
