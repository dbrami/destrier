# destrier

> The warhorse that carries your code into battle — armored review, debugging, and a durable knowledgebase that does the heavy lifting.

A generic **code-improvement toolkit for Claude Code**, packaged as a plugin.
It bundles a few battle-tested skills, hooks, a knowledgebase session workflow,
and code-graph/metrics helpers — and wires in two external tools,
[gitnexus](https://github.com/abhigyanpatwari/GitNexus) (code knowledge graph +
MCP) and [roborev](https://roborev.io) (multi-agent AI code review) — without
vendoring them.

## Install

destrier is its own Claude Code marketplace, so install is one command each:

```text
/plugin marketplace add dbrami/destrier
/plugin install destrier
/destrier-setup
```

- `/plugin install destrier` loads the skills, hooks, slash commands, and the
  gitnexus MCP server registration.
- `/destrier-setup` bootstraps the external tools (see below). Restart Claude
  Code afterward so the gitnexus MCP server loads.

## What it bundles

| Component | Type | Purpose |
|-----------|------|---------|
| `evidence-driven-debugging` | skill | Evidence-over-deduction habits for any debugging task. |
| `session-handover` | skill | Maintain a durable, model-labeled knowledgebase across sessions as a strict [Open Knowledge Format](https://cloud.google.com/blog/products/data-analytics/how-the-open-knowledge-format-can-improve-data-sharing) (OKF) v0.1 bundle — a dated session journal plus a cross-linked concept layer. |
| `daily-recap` | SessionStart hook | Recap of last-24h commits, uncommitted changes, and unpushed counts. |
| `commit-hygiene` | Stop hook | Warns about un-updated CLAUDE.md/README, missing version bump, and unpushed commits. |
| `critical-path-precommit` | script | Reminds you to run gitnexus impact analysis when staged files match configured critical paths. |
| `flow-metrics` | script | Weekly throughput + cycle-time (p50/p85) and WIP-aging via `gh`. |
| `security-scan` | script | De-identification + secret scan, reused by the security-review gate. |
| `spec-kit-ext` | spec-kit extension | Bridges spec-kit's Spec-Driven Development loop into the OKF knowledgebase + flow-metrics (opt-in via `/destrier-spec-init`). |

## Commands

| Command | What it does |
|---------|--------------|
| `/destrier-setup` | Build gitnexus from git and install roborev via its official installer. |
| `/destrier-spec-init` | Opt-in: set up Spec-Driven Development (spec-kit) in the current repo — installs the pinned `specify` CLI, runs `specify init`, and registers destrier's bridge extension. |
| `/destrier-kb-init` | Initialize today's KB session summary (OKF v0.1 bundle) and show recent ones. Promote durable knowledge into cross-linked concept files with `scripts/kb-concept.sh <type> "<title>"`. |
| `/destrier-precommit-install` | Install the critical-path guard as this repo's pre-commit hook. |
| `/destrier-security-review` | De-identification + secret scan of pending changes, plus roborev security review when available. |
| `/destrier-flow-metrics` | Throughput and cycle-time report for one or more repos. |

## External tools (not vendored)

`/destrier-setup` installs both from upstream into `~/.destrier/vendor/`:

- **gitnexus** — cloned from
  [`abhigyanpatwari/GitNexus`](https://github.com/abhigyanpatwari/GitNexus) and
  built with `npm install && npm run build` (needs Node + git). Registered as an
  MCP server via a launcher script. Fallback: `npm install -g gitnexus`.
- **roborev** — installed via its official installer
  (`curl -fsSL https://roborev.io/install.sh | bash`), which downloads a
  prebuilt binary (no Go toolchain). The bootstrap then runs `roborev init` and
  `roborev skills install` so roborev installs its own skills.

> Note: `/destrier-setup` runs the official roborev `curl | bash` installer. It is
> user-invoked and pinned to the official URL; review it first if you prefer.

After setup, run `gitnexus analyze` once per repository you want indexed.

## Spec-Driven Development (opt-in)

destrier can bring GitHub [spec-kit](https://github.com/github/spec-kit)'s
Spec-Driven Development (SDD) loop — `constitution → specify → plan → tasks →
implement` — into a repo. It is **opt-in and per-repo**: run `/destrier-spec-init`
in the repository you want to use it in.

destrier **bootstraps** the upstream `specify` CLI (no vendoring, same as
gitnexus/roborev) and integrates through spec-kit's **own extension-hook API** —
it never forks a spec-kit command, so `specify self upgrade` keeps working. The
integration is two layers: the plugin ships the bridge extension
(`spec-kit-ext/`), and per repo `specify extension add … --dev` installs it into
`.specify/`.

Two optional (prompted, never auto-run) bridges:

- after `/speckit.plan` — record the plan's durable decisions as a **link-only**
  OKF knowledgebase concept (a pointer to `plan.md`, never a copy);
- after `/speckit.taskstoissues` — run `flow-metrics` over the GitHub issues the
  tasks became (`tasks → issues → metrics`).

Establish principles with `/speckit.constitution`, fed destrier's house rules from
`templates/destrier-constitution-values.md` (it is *input* to the command, not a
replacement for `.specify/memory/constitution.md`).

- **Requirements:** `uv` and `python3 >= 3.11` (verified by `/destrier-spec-init`).
- **Versioning:** `/destrier-spec-init` installs `specify` `v0.11.6` on a fresh
  setup. Compatibility is governed by the bridge extension's `requires` range
  (`>=0.11,<0.12`), so a pre-existing `0.11.x` is accepted and anything outside
  the range is rejected with upgrade instructions. Upgrade within the range via
  `specify self upgrade --tag <tag>`, and bump the range in lockstep when moving
  to a new spec-kit minor.
- **Privacy:** **set `DESTRIER_PRIVATE_DENYLIST` before authoring specs.** Spec
  free-text is committed and scanned by the security gate; private codenames must
  not leak — especially into a public repo.
- **Right-sized for plugins:** for a shell/markdown project with no app build,
  `data-model.md`/`contracts/`/`quickstart.md` are N/A; the spec → tasks →
  implement spine is the working subset.

## Privacy

destrier ships **no** personal content. A generic de-identification denylist
(`templates/identifying-tokens.denylist`) flags structural leaks (absolute home
paths, secrets). To guard your own project codenames, add them to a local,
gitignored file and point `DESTRIER_PRIVATE_DENYLIST` at it.

## Requirements

`git`, `rg` (ripgrep), and `jq`. Node + npm for gitnexus; `python3` and `gh` for
flow-metrics; `curl` for the roborev installer; `uv` + `python3 >= 3.11` for the
opt-in Spec-Driven Development workflow (`/destrier-spec-init`).

`/destrier-setup` **verifies all of these** and prints the exact install command
for anything missing. Run `bash scripts/bootstrap.sh --install-deps` to have
destrier install the missing ones via your package manager (brew/apt/dnf/yum), or
`bash scripts/bootstrap.sh --check` to just report status without changes.

## Development

```bash
bash test/run.sh                          # run the test suite
bash scripts/security-scan.sh --tree .    # de-identification + secret scan
```

Every commit passes the security scan before it lands; see
`docs/design/` for the design spec.

## License

MIT — see [LICENSE](LICENSE).
