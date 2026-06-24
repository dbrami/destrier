---
description: "Create one structured GitHub feature issue from the just-written spec (links the spec; opt-in)"
---

# Create a structured GitHub issue from this spec

Offer to turn the spec you just wrote into **one structured GitHub feature
issue** — the "write the feature into a tracked issue before implementing"
practice. By default the issue **links and summarizes** the spec rather than
duplicating it: `specs/<feature>/spec.md` stays the canonical source of truth.

## Steps

1. **Locate destrier.** Read the plugin root from `<git-dir>/destrier-root`,
   where `<git-dir>` is `git rev-parse --git-dir`. If missing or it does not
   contain `scripts/spec-to-issue.sh`, report that destrier is unavailable and
   stop without error (the bridge is opt-in).

2. **Find the spec.** Use the current feature's `spec.md` (spec-kit's feature
   state if available, otherwise the most recently modified `specs/*/spec.md`).

3. **Preview first**, then create. Show the user what would be filed:

   ```bash
   ROOT="$(cat "$(git rev-parse --git-dir)/destrier-root")"
   bash "$ROOT/scripts/spec-to-issue.sh" --dry-run "<spec path>"
   ```

   If it looks right, create it (omit `--dry-run`). The script runs the
   de-identification gate on the body first and aborts on any leak; it is
   idempotent (it reuses an existing issue that already references the spec).

   ```bash
   bash "$ROOT/scripts/spec-to-issue.sh" "<spec path>"
   ```

4. **Report** the issue URL and remind the user to link it from the PR with
   `Closes #<n>`.

## Notes

- Per-repo behavior (labels, project, body mode `summary`/`full`, title prefix,
  assignee, milestone) comes from an optional, gitignored `.destrier/issue.config`.
  Project-specific values live there, never in destrier.
- Requires `gh` authenticated for the repo. Creating an issue publishes the
  summary to GitHub — set `DESTRIER_PRIVATE_DENYLIST` before authoring specs.
