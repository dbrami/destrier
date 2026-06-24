# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/), and this
project adheres to [Semantic Versioning](https://semver.org/).

## [0.6.0] - 2026-06-24

### Added
- **`spec-driven-brainstorming` skill** — makes the superpowers `brainstorming`
  skill the front-end for authoring under Spec-Driven Development: brainstorm the
  intent, distill to a short input brief, hand it to `/speckit-constitution` or
  `/speckit-specify`, and continue the speckit loop — deliberately *replacing*
  brainstorming's "design doc → writing-plans" tail when working under spec-kit
  (spec-kit owns the canonical artifacts).
- **Optional feature → GitHub issue bridge** — a 3rd `after_specify` hook in the
  `destrier-sdd` spec-kit extension (now v0.2.0) plus `scripts/spec-to-issue.sh`:
  turn a `spec.md` into one structured GitHub feature issue (the "issue-first"
  practice). Default **links and summarizes** the spec (`spec.md` stays
  canonical); per-repo, gitignored `.destrier/issue.config` tunes labels, project,
  body mode (`summary`/`full`), title prefix, assignee, milestone. The
  de-identification gate runs on the body before publishing (aborts on any leak),
  it is idempotent (reuses an issue already referencing the spec), `--dry-run`
  previews with no `gh` calls, and it emits no emojis.
  - Project-specific issue conventions stay in the project's own config, never in
    destrier; no board automation or domain governance is shipped (generic by design).
- `test/test-spec-to-issue.sh` — hermetic (`gh` stubbed): summary extraction,
  config parsing, privacy-gate abort, idempotency, create-path, and no-emoji.

## [0.5.0] - 2026-06-24

### Added
- **Spec-Driven Development (spec-kit) integration** — opt-in, per-repo via the
  new `/destrier-spec-init` command. destrier bootstraps GitHub spec-kit's
  upstream `specify` CLI (no vendoring, same MO as gitnexus/roborev) and
  integrates through spec-kit's **own extension-hook API** — it never forks a
  spec-kit command, so `specify self upgrade` keeps working.
  - `scripts/spec-init.sh` — verifies prerequisites (`uv`, `python3 >= 3.11`,
    `git`), installs the pinned `specify` CLI (`v0.11.6`), runs `specify init`
    idempotently, and registers destrier's bridge extension. A re-run never
    clobbers an existing constitution or `specs/`.
  - `spec-kit-ext/` — a spec-kit extension (`destrier-sdd`) providing two
    optional (prompted) bridges: `after_plan` records the plan's durable
    decisions as a **link-only** OKF knowledgebase concept (a pointer to
    `plan.md`, never a copy); `after_taskstoissues` runs `flow-metrics` over the
    GitHub issues the tasks became (`tasks → issues → metrics`).
  - `templates/destrier-constitution-values.md` — destrier's house rules as
    *input* to `/speckit-constitution` (not a replacement constitution file).
  - `bootstrap.sh` now reports `uv` status (with the official-installer hint
    outside Homebrew); `/destrier-setup` documents the SDD opt-in.
  - `test/test-spec-init.sh` — manifest invariants, pin↔range version guard,
    prereq-detection seams, hermetic idempotency, and a security-gate fixture.
- **Privacy note:** set `DESTRIER_PRIVATE_DENYLIST` before authoring specs — spec
  free-text is committed and scanned; private codenames must not leak.

## [0.4.0] - 2026-06-23

### Changed
- **Project renamed: `codeman` → `destrier`** (a medieval warhorse). This is a
  **breaking** rebrand with no compatibility aliases (hard-cut):
  - All slash commands `/codeman-*` → `/destrier-*` (`/destrier-setup`,
    `/destrier-kb-init`, `/destrier-precommit-install`, `/destrier-security-review`,
    `/destrier-flow-metrics`).
  - All environment variables `CODEMAN_*` → `DESTRIER_*`.
  - Per-repo config dir `.codeman/` → `.destrier/`; vendor install dir
    `~/.codeman/` → `~/.destrier/`.
  - Plugin/marketplace name is now `destrier`; repo moved to
    `github.com/dbrami/destrier` (the old URL redirects); the security-scan
    repo-slug allowlist was updated accordingly.
  - Action required: re-run `/destrier-setup`, and update any of your own
    scripts/env that referenced the old `codeman` names or paths.

### Added
- README wordmark + tagline ("the warhorse that carries your code into battle").

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
