---
name: session-handover
description: Use at the start and end of any work session to maintain a durable, model-labeled knowledgebase in the Open Knowledge Format (OKF). At start, read the last few session summaries for continuity; during work, append dated deltas and promote durable knowledge into cross-linked concept files; at end, update the indexes. Use when resuming work, handing off between sessions or agents, or when the user mentions a knowledgebase, session summary, handover, or OKF.
---

# Session Handover

Maintain continuity across sessions with a lightweight, append-only knowledgebase
that is a strict [Open Knowledge Format](https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md)
(OKF) v0.1 bundle. Because it conforms to OKF, the knowledgebase is portable and
can be read unmodified by any OKF consumer (e.g. a graph visualizer).

## Bundle layout

```
docs/knowledgebase/
├── index.md            # RESERVED: directory listing (no frontmatter)
├── log.md              # RESERVED: date-grouped chronological history (no frontmatter)
├── sessions/           # the journal: one file per day
│   ├── index.md        # RESERVED: directory listing (no frontmatter)
│   └── YYYY-MM-DD-summary.md     # concept — type: session-summary
└── concepts/           # curated, cross-linked durable knowledge
    ├── index.md
    ├── decisions/      index.md + <slug>.md   # concepts — type: decision
    ├── components/     index.md + <slug>.md   # concepts — type: component
    └── open-items/     index.md + <slug>.md   # concepts — type: open-item
```

**Concept documents** (everything that is not a reserved file) lead with a YAML
frontmatter block. `type` is the only required field; also set `title`,
`description`, `resource`, `timestamp`, and `tags` where they apply. The `type`
vocabulary is open — the starter set is `session-summary`, `decision`,
`component`, `open-item`, but you may introduce others.

**Reserved files** — `index.md` (a directory listing for progressive disclosure)
and `log.md` (a date-grouped, ISO-8601 chronological history) — carry **no**
frontmatter. The scaffolding scripts maintain them for you.

**Cross-links** use the recommended bundle-relative absolute form: begin with `/`
relative to the bundle root (e.g. `[orders](/concepts/components/orders.md)`), so
links stay stable when documents move. The relationship a link asserts is
conveyed by the surrounding prose, not the link itself.

## Start of session
1. Run `scripts/kb-init.sh <your-agent-label>` (or `/codeman-kb-init`). It creates
   today's `docs/knowledgebase/sessions/YYYY-MM-DD-summary.md` (with OKF
   frontmatter) if needed, scaffolds the bundle (`index.md`, `log.md`,
   `sessions/index.md`) on first run, and prints the last 3 summaries. It is
   forward-only and idempotent — safe to re-run, and it leaves any pre-OKF
   `INDEX.md` untouched.
2. Read those summaries before acting. If work is in flight, also check `git status`
   and any linked issue/PR before assuming what remains.

## During the session
Append deltas to today's session file under a metadata header that records the
model and effort tier:

```
### [Agent: <name> | Model: <model + effort> | Timestamp: YYYY-MM-DD HH:MM]
- What changed / decisions / open items
```

When a delta is durable knowledge worth carrying across sessions (a decision, a
component description, an open item), **promote it into a concept file** so it
joins the cross-linked graph rather than being buried in a dated journal entry:

```
scripts/kb-concept.sh <type> "<title>" [tags-csv]
# e.g. scripts/kb-concept.sh decision "Adopt OKF for the KB" sales,kb
```

This scaffolds `concepts/<type>/<slug>.md` with conformant frontmatter, links it
from the relevant `index.md`, and records it in `log.md`. Fill in the body and
add relative markdown cross-links (e.g. `[orders](../components/orders.md)`) to
related concepts.

## End of session
The indexes and `log.md` are maintained as you create files, so end-of-session
work is light: confirm today's session summary captures what changed, and record
whether work was committed/pushed or left local, naming any linked issue/PR so
the next session can reconcile the knowledgebase with the repo state.

Templates live in this plugin's `templates/` (`session-summary.md`, `concept.md`,
`index.md`). This skill ships no content — only the workflow.
