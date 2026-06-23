# Align codeman's session-handover KB to the Open Knowledge Format (OKF) v0.1

**Date:** 2026-06-23
**Status:** Implemented (v0.3.0)

## Context

Google Cloud published the **Open Knowledge Format (OKF) v0.1** — a vendor-neutral,
file-based standard for agent-readable knowledge. The normative spec lives at
[`GoogleCloudPlatform/knowledge-catalog` → `okf/SPEC.md`](https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md);
this design is aligned to that file, not to the announcement blog (the blog's
paraphrase differed from the spec in three material ways — see "Conformance"
below).

codeman's `session-handover` skill already produced a markdown knowledgebase under
`docs/knowledgebase/` (dated session summaries + an uppercase `INDEX.md`), so it was
~80% OKF-shaped but missing YAML frontmatter, the `index.md`/`log.md` conventions,
and cross-linking. Aligning to OKF makes the KB **portable and interoperable** —
readable unmodified by any OKF consumer (e.g. a graph visualizer) — while keeping the
lightweight session-handover workflow intact.

## Decisions

- **Scope:** align the existing session-handover KB to OKF (not new code-doc bundles, not tooling-only).
- **Structure:** *journal + concept layer* — the dated session journal stays; durable
  decisions/components/open-items are promoted into a cross-linked `concepts/` layer.
- **Conformance:** *strict OKF v0.1*, verified against `okf/SPEC.md`. No separate validator command.
- **Authoring:** a scaffold helper script, `scripts/kb-concept.sh` (sibling to `kb-init.sh`); no new slash command.
- **Concept org:** by-type subdirectories, each with its own `index.md` (mirrors the spec's structure).
- **Starter `type` taxonomy:** `session-summary`, `decision`, `component`, `open-item`; the helper accepts an arbitrary `type`.
- **Migration:** *forward-only* — `kb-init.sh` is idempotent and leaves any pre-OKF `INDEX.md` untouched; migrating old content is out of scope.

## Bundle layout

```
docs/knowledgebase/
├── index.md            # RESERVED: directory listing, NO frontmatter
├── log.md              # RESERVED: date-grouped (ISO 8601) history, NO frontmatter
├── sessions/
│   ├── index.md        # RESERVED
│   └── YYYY-MM-DD-summary.md     # concept — type: session-summary
└── concepts/
    ├── index.md
    ├── decisions/   index.md + <slug>.md   # type: decision
    ├── components/  index.md + <slug>.md   # type: component
    └── open-items/  index.md + <slug>.md   # type: open-item
```

## Conformance (per `okf/SPEC.md`)

- **Frontmatter:** concept documents lead with a YAML block. `type` is the only
  **required** field (must be non-empty). Recommended: `title`, `description`,
  `resource`, `tags`, `timestamp` (ISO 8601). Unknown keys are preserved by consumers.
- **Reserved files have NO frontmatter:** `index.md` is a directory listing for
  progressive disclosure; `log.md` is a date-grouped chronological history. (The blog
  implied all files carry frontmatter — the spec says reserved files do not.)
- **Cross-links use the recommended bundle-relative absolute form:** begin with `/`,
  relative to the bundle root (`[orders](/concepts/components/orders.md)`), because that
  is stable when documents move. The relationship a link asserts is conveyed by prose,
  not the link. (The blog text said "relative links"; its own examples used `/…`.)
- **`log.md` is date-grouped** under ISO 8601 `## YYYY-MM-DD` headings (not a flat list).
- A bundle is conformant when every non-reserved `.md` has a parseable frontmatter block
  with a non-empty `type`, and reserved files follow their structures. Consumers must
  tolerate missing optional fields, unknown types/keys, broken links, and missing indexes.

## Components

- **`scripts/kb-init.sh`** — creates today's `sessions/YYYY-MM-DD-summary.md` (with
  frontmatter), scaffolds reserved `index.md`/`log.md`/`sessions/index.md` on first run,
  records the session in the date-grouped log, prints the last 3 summaries. Idempotent /
  forward-only.
- **`scripts/kb-concept.sh <type> <title> [tags-csv]`** — scaffolds a conformant concept
  document at `concepts/<subdir>/<slug>.md`, links it from the per-type and `concepts/`
  indexes (bundle-relative absolute links), and appends a date-grouped `log.md` entry.
  Starter types map to plural subdirs; unknown types use a sanitized kebab of the type.
  bash 3.2-safe. Prints the created path.
- **`skills/session-handover/SKILL.md`** — rewritten to document the OKF bundle, the
  start/during/end workflow, the frontmatter/reserved-file/cross-link rules, and
  `kb-concept.sh` usage. Ships workflow only, no content.
- **Templates** — `templates/index.md` (reserved listing, no frontmatter),
  `templates/session-summary.md` (with frontmatter), `templates/concept.md` (new).
- **Command** — `/codeman-kb-init` prose updated; mentions `kb-concept.sh`. No new command.

## Testing

- `test/test-kb.sh` — session file has frontmatter + `type: session-summary`; reserved
  `index.md`/`log.md`/`sessions/index.md` exist and have **no** frontmatter; `log.md` is
  date-grouped; sessions index uses `/…` links; init is idempotent (no duplicate file).
- `test/test-kb-concept.sh` — concept file under `concepts/<subdir>/` with correct `type`
  and title; slug derives from title; indexes link the concept with bundle-relative
  absolute links and carry no frontmatter; `log.md` date-grouped and records the concept;
  starter and unknown type→subdir mapping; usage error when args are missing.

## Release & semantic versioning

- `.claude-plugin/plugin.json` `version` `0.2.0` → **`0.3.0`** (MINOR — new feature;
  `test-manifests.sh` enforces semver). `marketplace.json` has no version field; README
  has no hardcoded version — neither changes.
- `CHANGELOG.md` gains a `## [0.3.0] - 2026-06-23` section (Keep-a-Changelog) with an
  Added/Changed breakdown that links the OKF spec, and calls out the pre-1.0 KB-convention
  change (`INDEX.md` → `index.md`, bundle-relative absolute links).
- `hooks/commit-hygiene.sh` recognizes `plugin.json` as a version file (no false
  "no version bump" warning).
- Shipped as a single conventional-commit `feat:` covering code + tests + docs + version;
  tagged `v0.3.0` on the user's go.
