#!/usr/bin/env bash
# Launcher referenced by .mcp.json. Execs the built gitnexus MCP (stdio) server.
# gitnexus is installed from source by /destrier-setup into $DESTRIER_HOME/vendor.
set -uo pipefail
DESTRIER_HOME="${DESTRIER_HOME:-$HOME/.destrier}"
GN_DIR="${DESTRIER_GITNEXUS_DIR:-$DESTRIER_HOME/vendor/gitnexus}"

# Monorepo layout first (upstream moved the CLI package into gitnexus/) so a
# stale root dist/ left over from a pre-monorepo clone never shadows the
# freshly built package; then the legacy flat layout.
ENTRY=""
for d in "$GN_DIR/gitnexus" "$GN_DIR"; do
  if [ -f "$d/dist/cli/index.js" ]; then ENTRY="$d/dist/cli/index.js"; break; fi
done

if [ -z "$ENTRY" ]; then
  echo "gitnexus is not installed at $GN_DIR. Run /destrier-setup first." >&2
  exit 1
fi

# `gitnexus mcp` starts the stdio MCP server (serves all indexed repos).
MCP_SUBCMD="${DESTRIER_GITNEXUS_MCP_SUBCMD:-mcp}"
exec node "$ENTRY" "$MCP_SUBCMD"
