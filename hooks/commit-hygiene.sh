#!/usr/bin/env bash
# Stop hook — fires at the end of every turn.
# Checks unpushed commits for:
#   1. CLAUDE.md updated
#   2. README.md updated (when source changed)
#   3. Semantic version bumped (when source changed)
#   4. Push reminder when 4+ commits ahead of remote

set -uo pipefail

# Must be inside a git repo
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

# Upstream tracking branch for the current branch
upstream=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null) || upstream=""

# Count commits ahead of upstream
if [ -n "$upstream" ]; then
  ahead=$(git rev-list "${upstream}..HEAD" --count 2>/dev/null || echo 0)
else
  ahead=0
fi

# No unpushed commits — nothing to check
[ "$ahead" -eq 0 ] && exit 0

# Files changed across unpushed commits
if [ -n "$upstream" ]; then
  changed=$(git diff --name-only "${upstream}..HEAD" 2>/dev/null || echo "")
else
  changed=$(git show --name-only --format="" HEAD 2>/dev/null || echo "")
fi

warnings=()

# Any non-docs source/config files changed?
has_source=$(echo "$changed" | grep -qE "\.(ts|tsx|js|jsx|prisma|json|toml|py|sh|gradle|yaml|yml)$" && echo 1 || echo 0)

# 1. CLAUDE.md updated? (always check)
if ! echo "$changed" | grep -q "CLAUDE\.md"; then
  warnings+=("- CLAUDE.md has not been updated in your unpushed commits")
fi

# 2. README.md updated? (only when source/config files changed)
if [ "$has_source" = "1" ] && ! echo "$changed" | grep -q "README\.md"; then
  warnings+=("- README.md has not been updated in your unpushed commits")
fi

# 3. Semantic version bumped? (only when source/config files changed)
if [ "$has_source" = "1" ] && ! echo "$changed" | grep -qE "(package\.json|pyproject\.toml|VERSION|version\.txt|Cargo\.toml|setup\.py|build\.gradle|plugin\.json)"; then
  warnings+=("- No version file updated — remember to bump semantic version (MAJOR.MINOR.PATCH) before tagging")
fi

# 4. Push reminder at 4+ commits ahead
if [ "$ahead" -ge 4 ]; then
  warnings+=("- You have ${ahead} unpushed commits — consider pushing: git push")
fi

# All clear
[ ${#warnings[@]} -eq 0 ] && exit 0

# Build the message
msg="Commit hygiene (${ahead} unpushed commit(s)):"$'\n'
for w in "${warnings[@]}"; do
  msg+="  ${w}"$'\n'
done

# Emit as a systemMessage (shown to Claude, appears in context)
if command -v jq >/dev/null 2>&1; then
  jq -n --arg m "$msg" '{"systemMessage": $m}'
else
  printf '%s\n' "$msg"
fi

exit 0
