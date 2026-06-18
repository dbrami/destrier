#!/usr/bin/env bash
# kb-init.sh — initialize today's knowledgebase session summary in the current
# repo and print the last 3 session summaries for continuity.
set -uo pipefail
AGENT="${1:-Claude}"
KB_DIR="docs/knowledgebase/sessions"
DATE="$(date +%Y-%m-%d)"
FILE="$KB_DIR/$DATE-summary.md"

mkdir -p "$KB_DIR"
if [ ! -f "$FILE" ]; then
  {
    echo "# Session Summary: $DATE"
    echo "## Initialized by: $AGENT"
    echo ""
  } > "$FILE"
fi

echo "---"
echo "KB initialized for $DATE."
echo "Record your next entry with this metadata header:"
echo "### [Agent: $AGENT | Model: <model + effort tier> | Timestamp: $(date +'%Y-%m-%d %H:%M')]"
echo "---"
ls -1tr "$KB_DIR" 2>/dev/null | tail -n 3
echo "---"
