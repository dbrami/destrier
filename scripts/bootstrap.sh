#!/usr/bin/env bash
# codeman bootstrap — installs external tools WITHOUT vendoring them.
#   gitnexus: git clone + npm build into $CODEMAN_HOME/vendor/gitnexus
#   roborev : official installer (prebuilt binary; no Go toolchain required)
#
# Run `bootstrap.sh --check` to report prerequisite status without changing
# anything. A missing prerequisite degrades gracefully with instructions.
set -uo pipefail

CODEMAN_HOME="${CODEMAN_HOME:-$HOME/.codeman}"
GN_DIR="$CODEMAN_HOME/vendor/gitnexus"
GN_REPO="https://github.com/abhigyanpatwari/GitNexus.git"
ROBOREV_INSTALL="https://roborev.io/install.sh"
CHECK=0
[ "${1:-}" = "--check" ] && CHECK=1

have()   { command -v "$1" >/dev/null 2>&1; }
report() { printf '  %-10s %s\n' "$1:" "$2"; }

echo "codeman setup — prerequisite check"
have git  && report git  "ok"                       || report git  "MISSING (required for gitnexus)"
have node && report node "ok ($(node -v 2>/dev/null))" || report node "MISSING (required to build gitnexus)"
have npm  && report npm  "ok"                        || report npm  "MISSING (required to build gitnexus)"
have curl && report curl "ok"                        || report curl "MISSING (required for roborev installer)"
have gitnexus && report gitnexus "already on PATH"   || report gitnexus "will build from source"
have roborev  && report roborev  "already on PATH"   || report roborev  "will install via official installer"

if [ "$CHECK" = 1 ]; then
  echo "(--check) no changes made."
  exit 0
fi

# --- gitnexus: clone + build from git (Node only; never vendored) ---
if have git && have node && have npm; then
  mkdir -p "$CODEMAN_HOME/vendor"
  if [ -d "$GN_DIR/.git" ]; then
    echo "Updating gitnexus..."
    git -C "$GN_DIR" pull --ff-only || true
  else
    echo "Cloning gitnexus..."
    git clone --depth 1 "$GN_REPO" "$GN_DIR"
  fi
  ( cd "$GN_DIR" && npm install && npm run build )
  echo "gitnexus built at $GN_DIR"
else
  echo "Skipping gitnexus: install git + Node/npm, then re-run /codeman-setup." >&2
fi

# --- roborev: official installer (prebuilt binary; no Go) ---
if have roborev; then
  echo "roborev already installed; skipping installer."
elif have curl; then
  echo "Installing roborev via official installer..."
  curl -fsSL "$ROBOREV_INSTALL" | bash
else
  echo "Skipping roborev: install curl, then re-run /codeman-setup." >&2
fi
if have roborev; then
  roborev init || true
  roborev skills install || true
fi

echo "codeman setup complete. Restart Claude Code so the gitnexus MCP server loads."
