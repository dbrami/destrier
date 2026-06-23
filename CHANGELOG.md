# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/), and this
project adheres to [Semantic Versioning](https://semver.org/).

## [0.3.0] - 2026-06-23

### Added
- The `session-handover` knowledgebase is now a strict [Open Knowledge Format
  (OKF) v0.1](https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md)
  bundle, so it is portable and can be read unmodified by any OKF consumer (e.g.
  a graph visualizer). Bundle gains a root `index.md`, a date-grouped `log.md`,
  and a cross-linked `concepts/` layer (decisions / components / open-items).
- `scripts/kb-concept.sh` — scaffold helper that promotes durable knowledge out
  of the dated session journal into a conformant, cross-linked concept document
  (`concepts/<type>/<slug>.md`) and updates the indexes and `log.md`.

### Changed
- `kb-init.sh` now emits OKF-conformant output: session summaries lead with YAML
  frontmatter (`type: session-summary`), and the bundle's reserved `index.md`/
  `log.md` files are scaffolded on first run. Forward-only and idempotent; a
  pre-existing pre-OKF `INDEX.md` is left untouched (no automatic migration).
- KB convention change (pre-1.0): the index is now lowercase `index.md` (OKF
  reserved name) and cross-links use the recommended bundle-relative absolute
  form (begin with `/`). `templates/INDEX.md` renamed to `templates/index.md`;
  added `templates/concept.md`; `session-handover` skill rewritten for OKF.
- `hooks/commit-hygiene.sh` now recognizes `.claude-plugin/plugin.json` as a
  version file, so bumping the plugin version no longer triggers a false
  "no version bump" warning.

## [0.2.0] - 2026-06-18

### Added
- `/codeman-setup` now verifies **all** prerequisites (git, rg, jq, node, npm,
  python3, gh, curl), grouped by the feature that needs them.
- `bootstrap.sh --install-deps` installs missing prerequisites via the detected
  package manager (brew/apt/dnf/yum); without it, the exact install command is
  shown per missing tool (codeman never installs system packages unasked).

## [0.1.0] - 2026-06-18

### Added
- Initial release: Claude Code plugin + self-marketplace (`dbrami/codeman`).
- Skills: `evidence-driven-debugging`, `session-handover`.
- Hooks: `daily-recap` (SessionStart), `commit-hygiene` (Stop).
- Commands: `codeman-setup`, `codeman-kb-init`, `codeman-precommit-install`,
  `codeman-security-review`, `codeman-flow-metrics`.
- Scripts: `security-scan` gate, `bootstrap` (gitnexus from git + roborev via
  official installer), gitnexus MCP launcher, `kb-init`, critical-path
  pre-commit guard, pre-commit security gate, `flow-metrics`.
- Knowledgebase templates and a generic de-identification denylist.
