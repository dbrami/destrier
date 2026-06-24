# destrier-sdd — a spec-kit extension

This directory is a [GitHub spec-kit](https://github.com/github/spec-kit)
**extension** that destrier ships and installs into a project so spec-kit's
Spec-Driven Development loop plugs into destrier's own machinery — **without
forking any spec-kit command** (so `specify self upgrade` keeps working).

## What it adds

Two optional (prompted, never auto-run) lifecycle hooks:

| Hook | Bridge command | Effect |
|------|----------------|--------|
| `after_plan` | `speckit.destrier-sdd.kb-stub` | Offers to promote the plan's durable decisions into a **link-only** OKF knowledgebase concept under `docs/knowledgebase/` — a pointer to `plan.md`, never a copy. Reuses destrier's `scripts/kb-concept.sh`. |
| `after_taskstoissues` | `speckit.destrier-sdd.metrics` | Offers to run destrier `flow-metrics` once `tasks.md` has become GitHub issues (`tasks -> issues -> metrics`). Reuses `scripts/flow-metrics.py`. |

Both bridge commands resolve the destrier plugin root from
`<git-dir>/destrier-root` (written by `/destrier-spec-init` inside the git dir, so
the absolute path is never committed) and degrade gracefully — if destrier is not
present, they report and stop without error.

## Install

Installed automatically by `/destrier-spec-init`, which runs:

```bash
specify extension add "${CLAUDE_PLUGIN_ROOT}/spec-kit-ext" --dev
```

`--dev` installs from this local directory (no catalog required); spec-kit copies
it into the project's `.specify/extensions/destrier-sdd/` and registers the hooks
in `.specify/extensions.yml`.

## Compatibility

`requires.speckit_version` is a **range** (`>=0.11,<0.12`) matched to the CLI tag
destrier pins. Upgrade spec-kit only via `specify self upgrade --tag <tag>`, and
bump the range here in lockstep when moving to a new spec-kit minor.
