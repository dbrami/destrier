#!/usr/bin/env bash
# kb-concept.sh — scaffold an Open Knowledge Format (OKF) v0.1 concept document
# in the knowledgebase bundle, so durable decisions/components/open-items can be
# promoted out of the dated session journal into a cross-linked concept graph.
#
# Usage: kb-concept.sh <type> <title> [tags-csv]
#   e.g. kb-concept.sh decision "Adopt OKF for the KB" sales,kb
#
# OKF v0.1 (okf/SPEC.md): a concept document is markdown led by a YAML
# frontmatter block whose only required field is `type`. `index.md` files are
# RESERVED (directory listings, NO frontmatter); `log.md` is RESERVED
# (date-grouped, NO frontmatter). Cross-links use the recommended bundle-relative
# absolute form (begin with `/`). bash 3.2-safe (no associative arrays/mapfile).
# Prints the absolute path of the created file.
# Spec: https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md
set -uo pipefail

TYPE="${1:-}"
TITLE="${2:-}"
TAGS_CSV="${3:-}"

if [ -z "$TYPE" ] || [ -z "$TITLE" ]; then
  echo "usage: kb-concept.sh <type> <title> [tags-csv]" >&2
  echo "  e.g. kb-concept.sh decision \"Adopt OKF for the KB\" sales,kb" >&2
  exit 1
fi

KB="docs/knowledgebase"
CONCEPTS="$KB/concepts"
DATE="$(date +%Y-%m-%d)"
TIME="$(date +%H:%M)"
NOW="$(date +%Y-%m-%dT%H:%M:%S%z)"

# Map starter types to their conventional plural subdir; unknown types use a
# sanitized kebab of the type name as the subdir (no naive pluralization).
case "$TYPE" in
  decision)  SUBDIR="decisions" ;;
  component) SUBDIR="components" ;;
  open-item) SUBDIR="open-items" ;;
  *)         SUBDIR="$(printf '%s' "$TYPE" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-//; s/-$//')" ;;
esac

# Slugify the title: lowercase, runs of non-alphanumerics -> single hyphen, trim.
SLUG="$(printf '%s' "$TITLE" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-//; s/-$//')"
[ -n "$SLUG" ] || { echo "error: title produced an empty slug" >&2; exit 1; }

DIR="$CONCEPTS/$SUBDIR"
FILE="$DIR/$SLUG.md"
[ -e "$FILE" ] && { echo "error: concept already exists: $FILE" >&2; exit 1; }
mkdir -p "$DIR"

# YAML tags array from CSV, if provided: "sales,kb" -> "[sales, kb]".
TAGS_YAML=""
[ -n "$TAGS_CSV" ] && TAGS_YAML="[$(printf '%s' "$TAGS_CSV" | sed 's/[[:space:]]//g; s/,/, /g')]"

{
  echo "---"
  echo "type: $TYPE"
  echo "title: $TITLE"
  echo "description: TODO — one-line summary."
  [ -n "$TAGS_YAML" ] && echo "tags: $TAGS_YAML"
  echo "timestamp: $NOW"
  echo "---"
  echo ""
  echo "# $TITLE"
  echo ""
  echo "TODO — describe this $TYPE."
  echo ""
  echo "## Related"
  echo "<!-- Cross-link related concepts with bundle-relative absolute links, e.g.: -->"
  echo "<!-- - [Orders](/concepts/components/orders.md) -->"
} > "$FILE"

# concepts/ root index (reserved: directory listing, NO frontmatter).
[ -f "$CONCEPTS/index.md" ] || printf '# Concepts\n\n' > "$CONCEPTS/index.md"
# Link the type subdir from the concepts index (once), bundle-relative absolute.
grep -q "(/concepts/$SUBDIR/index.md)" "$CONCEPTS/index.md" 2>/dev/null || \
  echo "- [$SUBDIR](/concepts/$SUBDIR/index.md)" >> "$CONCEPTS/index.md"

# Per-type index (reserved: directory listing, NO frontmatter).
[ -f "$DIR/index.md" ] || printf '# %s\n\n' "$SUBDIR" > "$DIR/index.md"
echo "- [$TITLE](/concepts/$SUBDIR/$SLUG.md)" >> "$DIR/index.md"

# Root chronological log (reserved: NO frontmatter, date-grouped).
[ -f "$KB/log.md" ] || { mkdir -p "$KB"; printf '# Log\n' > "$KB/log.md"; }
grep -q "^## $DATE\$" "$KB/log.md" || printf '\n## %s\n' "$DATE" >> "$KB/log.md"
echo "- $TIME — $TYPE: [$TITLE](/concepts/$SUBDIR/$SLUG.md)" >> "$KB/log.md"

# Print the absolute filesystem path of the created concept.
case "$FILE" in
  /*) echo "$FILE" ;;
  *)  echo "$PWD/$FILE" ;;
esac
