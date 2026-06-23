#!/usr/bin/env bash
# kb-init.sh — initialize today's knowledgebase session summary in the current
# repo as an Open Knowledge Format (OKF) v0.1 bundle, and print the last 3
# session summaries for continuity.
#
# OKF v0.1 (okf/SPEC.md): concept documents are markdown with a YAML frontmatter
# block whose only required field is `type`. `index.md` and `log.md` are
# RESERVED files and carry NO frontmatter — `index.md` is a directory listing for
# progressive disclosure, `log.md` is a date-grouped chronological history.
# Cross-links use the recommended bundle-relative absolute form (begin with `/`,
# relative to the bundle root) so they stay stable when documents move.
# Forward-only and idempotent: re-runs never duplicate or rewrite files, and a
# pre-existing (pre-OKF) uppercase INDEX.md is left untouched.
# Spec: https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md
set -uo pipefail
AGENT="${1:-Claude}"
KB="docs/knowledgebase"
SESS="$KB/sessions"
DATE="$(date +%Y-%m-%d)"
TIME="$(date +%H:%M)"
NOW="$(date +%Y-%m-%dT%H:%M:%S%z)"
FILE="$SESS/$DATE-summary.md"

mkdir -p "$SESS"

# Append a line to the date-grouped reserved log.md, creating today's date
# group if it is not already the latest section.
log_append() { # $1 = entry text (without leading "- ")
  if [ ! -f "$KB/log.md" ]; then
    printf '# Log\n' > "$KB/log.md"
  fi
  if ! grep -q "^## $DATE\$" "$KB/log.md"; then
    printf '\n## %s\n' "$DATE" >> "$KB/log.md"
  fi
  printf -- '- %s\n' "$1" >> "$KB/log.md"
}

# Bundle root index (reserved file: directory listing, NO frontmatter).
if [ ! -f "$KB/index.md" ]; then
  {
    echo "# Knowledgebase"
    echo ""
    echo "An [Open Knowledge Format](https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md) v0.1 bundle. Links below begin with \`/\` and are relative to this bundle root."
    echo ""
    echo "- [Sessions](/sessions/index.md) — dated session-handover journal."
    echo "- [Concepts](/concepts/index.md) — curated decisions, components, and open items."
    echo "- [Log](/log.md) — chronological change history."
  } > "$KB/index.md"
fi

# Root chronological log (reserved file: NO frontmatter, date-grouped).
[ -f "$KB/log.md" ] || printf '# Log\n' > "$KB/log.md"

# Sessions index (reserved file: NO frontmatter).
if [ ! -f "$SESS/index.md" ]; then
  printf '# Sessions\n\n' > "$SESS/index.md"
fi

# Today's session concept file (non-reserved: requires frontmatter with `type`).
if [ ! -f "$FILE" ]; then
  {
    echo "---"
    echo "type: session-summary"
    echo "title: Session $DATE"
    echo "description: Session-handover summary for $DATE."
    echo "tags: [session]"
    echo "timestamp: $NOW"
    echo "---"
    echo ""
    echo "# Session Summary: $DATE"
    echo ""
    echo "Initialized by: $AGENT"
    echo ""
    echo "<!-- Append deltas below with a metadata header: -->"
    echo "<!-- ### [Agent: <name> | Model: <model + effort> | Timestamp: YYYY-MM-DD HH:MM] -->"
  } > "$FILE"
  # Progressive disclosure + chronology (only on first creation, so re-runs
  # never duplicate links). Links are bundle-relative absolute.
  echo "- [$DATE](/sessions/$DATE-summary.md)" >> "$SESS/index.md"
  log_append "$TIME — session started ([$DATE](/sessions/$DATE-summary.md))"
fi

echo "---"
echo "KB initialized for $DATE (OKF v0.1 bundle at $KB/)."
echo "Record your next entry with this metadata header:"
echo "### [Agent: $AGENT | Model: <model + effort tier> | Timestamp: $(date +'%Y-%m-%d %H:%M')]"
echo "Promote durable knowledge into concepts with: scripts/kb-concept.sh <type> <title> [tags]"
echo "---"
ls -1tr "$SESS"/*-summary.md 2>/dev/null | tail -n 3
echo "---"
