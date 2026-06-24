# Tasks: Spec-Driven Development for destrier

**Spec**: [spec.md](spec.md) | **Branch**: `feat/spec-kit-sdd`

Tasks are grouped by user story. `[P]` marks tasks that can run in parallel
(different files, no ordering dependency). All tasks below are complete.

## Phase 1: Prerequisites & bootstrap (US1)

- [x] T001 Add `uv` to the prerequisite report in `scripts/bootstrap.sh`, with an
  official-installer hint outside Homebrew (`install_cmd`/`do_install`).
- [x] T002 [P] Extend `test/test-bootstrap.sh` to assert `uv` is reported.
- [x] T003 Create `scripts/spec-init.sh`: verify `uv`/`python3>=3.11`/`git`;
  install the pinned `specify` CLI (`v0.11.6`); run `specify init` idempotently;
  register the bridge extension; record the destrier root. bash-3.2-safe,
  non-interactive, `--check` mode.

## Phase 2: Bridge extension (US2)

- [x] T004 Create `spec-kit-ext/extension.yml` (`destrier-sdd`, schema 1.0, range
  `requires`, two provided commands, `after_plan` + `after_taskstoissues` hooks).
- [x] T005 [P] Create `spec-kit-ext/commands/speckit.destrier-sdd.kb-stub.md`
  (link-only OKF concept; reuses `scripts/kb-concept.sh`).
- [x] T006 [P] Create `spec-kit-ext/commands/speckit.destrier-sdd.metrics.md`
  (flow-metrics over the issues; reuses `scripts/flow-metrics.py`).
- [x] T007 [P] Create `spec-kit-ext/README.md`.

## Phase 3: Command surface & constitution (US1)

- [x] T008 Create `commands/destrier-spec-init.md` (thin wrapper + next steps +
  privacy warning).
- [x] T009 [P] Create `templates/destrier-constitution-values.md` (house rules as
  input to `/speckit-constitution`).
- [x] T010 [P] Update `commands/destrier-setup.md` to document the SDD opt-in.

## Phase 4: Tests & docs

- [x] T011 Create `test/test-spec-init.sh`: manifest invariants, pin↔range version
  guard, prereq-detection seams, hermetic idempotency, security-gate fixture.
- [x] T012 [P] Update `README.md` (capability, two-layer model, pin/upgrade
  policy, privacy, dogfood subset).
- [x] T013 [P] Update `CHANGELOG.md` and bump `.claude-plugin/plugin.json` to 0.5.0.

## Phase 5: Dogfood (US3)

- [x] T014 Run `scripts/spec-init.sh` in this repo (installs CLI, inits, registers
  the extension); verify both hooks appear in `.specify/extensions.yml`.
- [x] T015 Author `.specify/memory/constitution.md` (destrier's constitution v1.0.0).
- [x] T016 Author `specs/001-spec-kit-integration/` (this spec + tasks).
- [x] T017 Gitignore regenerable spec-kit scaffolding; commit only authored
  artifacts; confirm the security scan is clean.

## Checkpoint

- Full test suite green (11 suites, including `test-spec-init.sh`).
- `security-scan.sh --tree .` clean.
- Bridges registered via `.specify/extensions.yml` with no spec-kit command forks.
