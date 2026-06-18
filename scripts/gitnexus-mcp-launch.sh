#!/usr/bin/env bash
# Launcher referenced by .mcp.json. Execs the built gitnexus MCP (stdio) server.
# gitnexus is installed from source by /codeman-setup into $CODEMAN_HOME/vendor.
set -uo pipefail
CODEMAN_HOME="${CODEMAN_HOME:-$HOME/.codeman}"
GN_DIR="${CODEMAN_GITNEXUS_DIR:-$CODEMAN_HOME/vendor/gitnexus}"
ENTRY="$GN_DIR/dist/cli/index.js"

if [ ! -f "$ENTRY" ]; then
  echo "gitnexus is not installed at $GN_DIR. Run /codeman-setup first." >&2
  exit 1
fi

# `gitnexus mcp` starts the stdio MCP server (serves all indexed repos).
MCP_SUBCMD="${CODEMAN_GITNEXUS_MCP_SUBCMD:-mcp}"
exec node "$ENTRY" "$MCP_SUBCMD"
