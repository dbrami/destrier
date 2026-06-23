# codeman

A generic **code-improvement toolkit for Claude Code**, packaged as a plugin.
It bundles a few battle-tested skills, hooks, a knowledgebase session workflow,
and code-graph/metrics helpers — and wires in two external tools,
[gitnexus](https://github.com/abhigyanpatwari/GitNexus) (code knowledge graph +
MCP) and [roborev](https://roborev.io) (multi-agent AI code review) — without
vendoring them.

## Install

codeman is its own Claude Code marketplace, so install is one command each:

```text
/plugin marketplace add dbrami/codeman
/plugin install codeman
/codeman-setup
```

- `/plugin install codeman` loads the skills, hooks, slash commands, and the
  gitnexus MCP server registration.
- `/codeman-setup` bootstraps the external tools (see below). Restart Claude
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

## Commands

| Command | What it does |
|---------|--------------|
| `/codeman-setup` | Build gitnexus from git and install roborev via its official installer. |
| `/codeman-kb-init` | Initialize today's KB session summary (OKF v0.1 bundle) and show recent ones. Promote durable knowledge into cross-linked concept files with `scripts/kb-concept.sh <type> "<title>"`. |
| `/codeman-precommit-install` | Install the critical-path guard as this repo's pre-commit hook. |
| `/codeman-security-review` | De-identification + secret scan of pending changes, plus roborev security review when available. |
| `/codeman-flow-metrics` | Throughput and cycle-time report for one or more repos. |

## External tools (not vendored)

`/codeman-setup` installs both from upstream into `~/.codeman/vendor/`:

- **gitnexus** — cloned from
  [`abhigyanpatwari/GitNexus`](https://github.com/abhigyanpatwari/GitNexus) and
  built with `npm install && npm run build` (needs Node + git). Registered as an
  MCP server via a launcher script. Fallback: `npm install -g gitnexus`.
- **roborev** — installed via its official installer
  (`curl -fsSL https://roborev.io/install.sh | bash`), which downloads a
  prebuilt binary (no Go toolchain). The bootstrap then runs `roborev init` and
  `roborev skills install` so roborev installs its own skills.

> Note: `/codeman-setup` runs the official roborev `curl | bash` installer. It is
> user-invoked and pinned to the official URL; review it first if you prefer.

After setup, run `gitnexus analyze` once per repository you want indexed.

## Privacy

codeman ships **no** personal content. A generic de-identification denylist
(`templates/identifying-tokens.denylist`) flags structural leaks (absolute home
paths, secrets). To guard your own project codenames, add them to a local,
gitignored file and point `CODEMAN_PRIVATE_DENYLIST` at it.

## Requirements

`git`, `rg` (ripgrep), and `jq`. Node + npm for gitnexus; `python3` and `gh` for
flow-metrics; `curl` for the roborev installer.

`/codeman-setup` **verifies all of these** and prints the exact install command
for anything missing. Run `bash scripts/bootstrap.sh --install-deps` to have
codeman install the missing ones via your package manager (brew/apt/dnf/yum), or
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
