#!/usr/bin/env bash
# destrier bootstrap — verifies prerequisites and installs the external tools
# WITHOUT vendoring them.
#   gitnexus: git clone + npm build into $DESTRIER_HOME/vendor/gitnexus
#   roborev : official installer (prebuilt binary; no Go toolchain required)
#
# Flags:
#   --check          report prerequisite status and exit (no changes)
#   --install-deps   install any MISSING prerequisites via the detected
#                    package manager (brew/apt/dnf/yum) before continuing
#
# With no --install-deps, missing prerequisites are reported with the exact
# install command for your platform; destrier never installs system packages
# without being asked.
set -uo pipefail

DESTRIER_HOME="${DESTRIER_HOME:-$HOME/.destrier}"
GN_DIR="$DESTRIER_HOME/vendor/gitnexus"
GN_REPO="https://github.com/abhigyanpatwari/GitNexus.git"
ROBOREV_INSTALL="https://roborev.io/install.sh"

MODE=run
INSTALL_DEPS=0
for a in "$@"; do
  case "$a" in
    --check)        MODE=check;;
    --install-deps) INSTALL_DEPS=1;;
    *) echo "unknown arg: $a" >&2; exit 64;;
  esac
done

# have(): true if a command exists. DESTRIER_FAKE_MISSING (space-separated tool
# names) forces specific tools to read as missing — a test seam only.
have() {
  case " ${DESTRIER_FAKE_MISSING:-} " in *" $1 "*) return 1;; esac
  command -v "$1" >/dev/null 2>&1
}

# Detect a package manager.
PKG=""
if   have brew;    then PKG=brew
elif have apt-get; then PKG=apt
elif have dnf;     then PKG=dnf
elif have yum;     then PKG=yum
fi

# Map a tool to its package name for the detected manager.
pkg_name() {
  case "$1:$PKG" in
    rg:*)            echo ripgrep;;
    node:apt|node:dnf|node:yum) echo nodejs;;
    node:brew)       echo node;;
    npm:apt)         echo npm;;
    npm:brew)        echo node;;
    npm:dnf|npm:yum) echo nodejs;;
    python3:brew)    echo python;;
    python3:*)       echo python3;;
    *)               echo "$1";;
  esac
}

# Human-readable install command (for display).
install_cmd() {
  # uv has no apt/dnf/yum package; outside Homebrew, point at the official
  # installer (the canonical, cross-distro path) instead of a bogus pkg command.
  if [ "$1" = uv ] && [ "$PKG" != brew ]; then
    echo "curl -LsSf https://astral.sh/uv/install.sh | sh"; return
  fi
  case "$PKG" in
    brew) echo "brew install $1";;
    apt)  echo "sudo apt-get install -y $1";;
    dnf)  echo "sudo dnf install -y $1";;
    yum)  echo "sudo yum install -y $1";;
    *)    echo "";;
  esac
}

# Run an install (no eval; args passed directly).
do_install() {
  case "$PKG" in
    brew) brew install "$1";;
    apt)  sudo apt-get install -y "$1";;
    dnf)  sudo dnf install -y "$1";;
    yum)  sudo yum install -y "$1";;
    *)    return 1;;
  esac
}

MISSING=()
check_tool() { # tool purpose
  if have "$1"; then
    printf '  %-9s ok\n' "$1"
  else
    printf '  %-9s MISSING — %s\n' "$1" "$2"
    MISSING+=("$1")
  fi
}

# Optional prerequisite: reported but deliberately NOT added to MISSING, so
# `--install-deps` never installs it. Used for opt-in features (e.g. SDD), which
# install their own deps from their own command (/destrier-spec-init).
check_optional() { # tool purpose
  if have "$1"; then
    printf '  %-9s ok\n' "$1"
  else
    cmd="$(install_cmd "$(pkg_name "$1")")"
    if [ -n "$cmd" ]; then
      printf '  %-9s optional, MISSING — %s (install: %s)\n' "$1" "$2" "$cmd"
    else
      printf '  %-9s optional, MISSING — %s\n' "$1" "$2"
    fi
  fi
}

echo "destrier prerequisite check"
check_tool git     "core: clone + git hooks"
check_tool rg      "core: security-scan / de-identification gate"
check_tool jq      "core: hook output + manifest tests"
check_tool node    "gitnexus build"
check_tool npm     "gitnexus build"
check_tool python3 "flow-metrics"
check_tool gh      "flow-metrics"
check_tool curl    "roborev installer"
check_optional uv  "spec-driven development — specify CLI (opt-in: /destrier-spec-init)"
have gitnexus && printf '  %-9s already on PATH\n' gitnexus || printf '  %-9s will build from source\n' gitnexus
have roborev  && printf '  %-9s already on PATH\n' roborev  || printf '  %-9s will install via official installer\n' roborev

# Report / optionally install missing prerequisites.
if [ "${#MISSING[@]}" -gt 0 ]; then
  echo ""
  echo "Missing prerequisites:"
  for t in "${MISSING[@]}"; do
    cmd="$(install_cmd "$(pkg_name "$t")")"
    if [ -n "$cmd" ]; then echo "  $t -> $cmd"; else echo "  $t -> install via your package manager"; fi
  done
  if [ "$INSTALL_DEPS" = 1 ]; then
    if [ -n "$PKG" ]; then
      echo ""
      echo "Installing missing prerequisites via $PKG ..."
      for t in "${MISSING[@]}"; do
        pkg="$(pkg_name "$t")"
        echo "+ $(install_cmd "$pkg")"
        do_install "$pkg" || echo "  (failed to install $t; install it manually)"
      done
      echo "Re-run with --check to confirm."
    else
      echo ""
      echo "No supported package manager detected (brew/apt/dnf/yum); install the above manually."
    fi
  else
    echo ""
    echo "Re-run with --install-deps to install these automatically, or install them manually."
  fi
fi

if [ "$MODE" = check ]; then
  echo "(--check) no changes made."
  exit 0
fi

# --- gitnexus: clone + build from git (Node only; never vendored) ---
if have git && have node && have npm; then
  mkdir -p "$DESTRIER_HOME/vendor"
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
  echo "Skipping gitnexus: needs git + Node/npm (see above), then re-run /destrier-setup." >&2
fi

# --- roborev: official installer (prebuilt binary; no Go) ---
if have roborev; then
  echo "roborev already installed; skipping installer."
elif have curl; then
  echo "Installing roborev via official installer..."
  curl -fsSL "$ROBOREV_INSTALL" | bash
else
  echo "Skipping roborev: needs curl (see above), then re-run /destrier-setup." >&2
fi
if have roborev; then
  roborev init || true
  roborev skills install || true
fi

echo "destrier setup complete. Restart Claude Code so the gitnexus MCP server loads."
