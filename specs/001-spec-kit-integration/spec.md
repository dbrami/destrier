# Feature Specification: Spec-Driven Development for destrier

**Feature Branch**: `feat/spec-kit-sdd`

**Created**: 2026-06-24

**Status**: Implemented

**Input**: User description: "Read the spec-kit repo and incorporate it into destrier — ship Spec-Driven Development as a destrier capability and dogfood it on destrier itself, by bootstrapping spec-kit's upstream CLI rather than forking it."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Enable Spec-Driven Development in a repo (Priority: P1)

A destrier user wants the structured `constitution → specify → plan → tasks →
implement` loop in their project without adopting a parallel toolchain. They run
one destrier command; destrier installs spec-kit's upstream `specify` CLI and
initializes it in the current repo. The user then drives the loop with spec-kit's
own `/speckit-*` commands.

**Why this priority**: This is the core capability — without it there is no SDD.
It is independently valuable even with no bridges.

**Independent Test**: Run the enable command in a throwaway repo; confirm the
`specify` CLI is installed, `.specify/` is scaffolded, and the `/speckit-*`
skills are available.

**Acceptance Scenarios**:

1. **Given** a repo with `uv` and `python3 >= 3.11`, **When** the user enables
   SDD, **Then** the pinned `specify` CLI is installed and `specify init` has run.
2. **Given** SDD is already enabled, **When** the user re-runs enable, **Then**
   nothing is clobbered (existing constitution and `specs/` are preserved).
3. **Given** a missing prerequisite, **When** the user runs the enable command,
   **Then** the exact install command is printed and no partial state is created.

### User Story 2 - Bridge SDD into destrier's machinery (Priority: P2)

As the user runs the SDD loop, durable plan decisions are offered for capture in
destrier's OKF knowledgebase (as link-only pointers, never copies), and once
tasks become GitHub issues, destrier's flow-metrics can run over them.

**Why this priority**: Integration is the reason to use SDD *through destrier*
rather than spec-kit alone, but the loop is usable without it.

**Independent Test**: With the extension installed, inspect
`.specify/extensions.yml` and confirm `after_plan` and `after_taskstoissues`
hooks point at the destrier bridge commands; trigger a plan and confirm a
prompt (not an auto-run) appears.

**Acceptance Scenarios**:

1. **Given** SDD is enabled, **When** `/speckit-plan` finishes, **Then** the user
   is prompted to record the plan's decisions in the knowledgebase.
2. **Given** tasks have become issues, **When** `/speckit-taskstoissues` finishes,
   **Then** the user is prompted to run flow-metrics.

### User Story 3 - destrier dogfoods SDD on itself (Priority: P3)

destrier uses the same capability to develop destrier: it ships a real
constitution and authors feature specs, while keeping spec-kit's regenerable
scaffolding out of the tracked repo and honoring the privacy gate.

**Why this priority**: Validates the capability end-to-end and proves the
right-sized-artifacts principle, but is not required for users to benefit.

**Independent Test**: Confirm `.specify/memory/constitution.md` and
`specs/001-spec-kit-integration/` are tracked while spec-kit scaffolding is
gitignored, and that the security scan passes over the tracked artifacts.

**Acceptance Scenarios**:

1. **Given** the dogfood is committed, **When** the security scan runs, **Then**
   it is clean and only authored artifacts are tracked.

### Edge Cases

- What happens when `specify self upgrade` jumps the CLI to a newer minor? The
  extension's `requires` range fails the install loudly rather than running
  against an unverified version.
- What happens when destrier is not installed in the session where a bridge fires?
  The bridge command reports unavailability and stops without error.
- What happens when a spec contains a private codename? The de-identification gate
  blocks the commit.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: destrier MUST install spec-kit's upstream `specify` CLI pinned to a
  tested tag, without vendoring or forking it.
- **FR-002**: destrier MUST initialize SDD in the current repo idempotently,
  never clobbering an existing constitution or `specs/`.
- **FR-003**: destrier MUST verify prerequisites (`uv`, `python3 >= 3.11`, `git`)
  and print exact install commands for anything missing.
- **FR-004**: destrier MUST integrate via spec-kit's extension-hook API only;
  it MUST NOT modify any spec-kit command file, so `specify self upgrade` keeps
  working.
- **FR-005**: destrier MUST register two optional (prompted) bridges: an
  `after_plan` knowledgebase capture and an `after_taskstoissues` flow-metrics run.
- **FR-006**: The knowledgebase bridge MUST create a link-only concept that points
  at the plan/spec; it MUST NOT copy plan content.
- **FR-007**: destrier MUST gate compatibility with a version RANGE (never `==`)
  and provide a documented upgrade path (`specify self upgrade --tag`).
- **FR-008**: The de-identification/security gate MUST scan SDD artifacts; users
  MUST be directed to set `DESTRIER_PRIVATE_DENYLIST` before authoring specs.

### Key Entities *(include if feature involves data)*

- **Bridge extension (`destrier-sdd`)**: a spec-kit extension providing two
  bridge commands and registering two lifecycle hooks.
- **Constitution**: the project's governing principles, owned by
  `/speckit-constitution`, seeded from destrier's starter values.
- **Concept stub**: an OKF knowledgebase node that links to a plan/spec.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user enables SDD in a repo with a single command and reaches the
  `/speckit-*` loop with no manual file editing.
- **SC-002**: Re-running enable any number of times never changes an existing
  constitution or `specs/` (idempotent).
- **SC-003**: 100% of the bridge hooks are registered through `.specify/extensions.yml`
  with zero modifications to spec-kit command files.
- **SC-004**: The destrier test suite and security scan pass, including a
  pin↔range version guard that fails if the pin and compat range drift apart.

## Assumptions

- Users adopt SDD per-repo and opt in; it is not installed by the base bootstrap.
- `uv` and `python3 >= 3.11` are acceptable opt-in dependencies for this workflow.
- For destrier itself (a shell/markdown plugin with no app build), the greenfield
  artifacts `data-model.md`/`contracts/`/`quickstart.md` are N/A; the
  `spec → tasks → implement` spine is the working subset.
- spec-kit's extension-hook API (`after_plan`, `after_taskstoissues`) remains the
  supported integration seam for the pinned version range.
