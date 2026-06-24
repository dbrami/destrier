# Feature Specification: Spec-driven brainstorming + optional feature-to-issue bridge

**Feature Branch**: `feat/spec-driven-brainstorming`

**Created**: 2026-06-24

**Status**: Implemented

**Input**: User description: "Wire brainstorming in as the front-end for /speckit-constitution and /speckit-specify, and optionally turn each feature spec into a structured GitHub issue before implementation (generic, opt-in)."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Brainstorm into a constitution or spec (Priority: P1)

A developer about to author a project constitution or a feature spec under
spec-kit wants to think it through collaboratively first. A skill makes
brainstorming the front-end: it explores intent one question at a time, distills
the agreement into a short brief, and hands that to `/speckit-constitution` or
`/speckit-specify` — without producing a parallel design doc.

**Why this priority**: This is the core "way of working"; the issue bridge is
additive.

**Independent Test**: With the skill installed, starting constitution/spec work
routes through brainstorming and ends by invoking the speckit command, not
`writing-plans`.

**Acceptance Scenarios**:

1. **Given** a developer starts a feature under SDD, **When** the skill triggers,
   **Then** brainstorming runs first and its distilled brief feeds `/speckit-specify`.
2. **Given** work is under spec-kit, **When** the brief is ready, **Then** no
   `docs/superpowers/specs/*-design.md` is written and `writing-plans` is not invoked.

### User Story 2 - Turn a spec into a structured GitHub issue (Priority: P2)

After `/speckit-specify` writes a spec, the developer optionally records the
feature as one structured GitHub issue before implementing it. By default the
issue links and summarizes the spec; the spec stays the source of truth.

**Why this priority**: Valuable for issue-first teams, but the SDD loop works
without it.

**Independent Test**: Run the bridge on a spec; a single issue is created (or an
existing one reused) that links the spec, with a summary and acceptance-criteria
checklist.

**Acceptance Scenarios**:

1. **Given** a spec exists, **When** the user accepts the `after_specify` prompt,
   **Then** one GitHub issue is created that links `specs/NNN/spec.md`.
2. **Given** an issue already references the spec, **When** the bridge runs again,
   **Then** no duplicate is created.
3. **Given** the issue body would contain a private codename, **When** the bridge
   runs, **Then** the de-identification gate aborts before publishing.

### Edge Cases

- What happens when `gh` is unauthenticated or absent? The bridge reports and
  stops (use `--dry-run` to preview without `gh`).
- What happens in a repo with no `.destrier/issue.config`? Generic defaults apply
  (no labels/project, summary body).
- What happens when destrier is not loaded in the session? The bridge command
  reports unavailability and stops without error.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: A skill MUST route constitution/spec authoring under SDD through
  brainstorming, distill to an input brief, and hand off to the speckit command.
- **FR-002**: The skill MUST NOT write a parallel design doc or invoke
  `writing-plans` when working under spec-kit.
- **FR-003**: destrier MUST offer (opt-in, prompted via `after_specify`) to create
  one structured GitHub issue from a spec.
- **FR-004**: By default the issue MUST link and summarize the spec, not duplicate
  it; a per-repo config MAY select a fuller body.
- **FR-005**: The bridge MUST run the de-identification gate on the issue body and
  abort on any finding before publishing.
- **FR-006**: The bridge MUST be idempotent — reuse an issue that already
  references the spec instead of creating a duplicate.
- **FR-007**: The bridge MUST support a per-repo, gitignored config for labels,
  project, body mode, title prefix, assignee, and milestone; destrier MUST NOT
  hardcode any project-specific values.
- **FR-008**: The bridge MUST emit no emojis and MUST support a `--dry-run`
  preview that makes no `gh` calls.

### Key Entities *(include if feature involves data)*

- **`spec-driven-brainstorming` skill**: the authoring front-end.
- **`speckit.destrier-sdd.spec-issue` bridge command + `spec-to-issue.sh`**: the
  feature→issue mechanism, registered on `after_specify`.
- **`.destrier/issue.config`**: per-repo issue conventions.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Authoring under SDD reaches `/speckit-constitution` or
  `/speckit-specify` via brainstorming, with no parallel design doc produced.
- **SC-002**: One spec yields exactly one GitHub issue; re-running creates no
  duplicate.
- **SC-003**: A spec containing a private codename never reaches GitHub — the gate
  aborts.
- **SC-004**: destrier ships no project-specific issue conventions; all such
  config lives in the consuming project.

## Assumptions

- The superpowers `brainstorming` skill is usually available; the skill degrades
  to inline one-question exploration if not.
- `gh` is authenticated for repos where issues are created.
- For a shell/markdown plugin, greenfield artifacts
  (`data-model.md`/`contracts/`/`quickstart.md`) remain N/A.
