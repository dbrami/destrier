# destrier Constitution

## Core Principles

### I. Evidence-Driven Debugging (NON-NEGOTIABLE)

Any failing test, error, crash, 4xx/5xx/timeout, or surprising behavior is
debugged by capturing ground truth at the boundary (logs, actual payloads,
runtime state) before any fix is proposed. Docs, comments, and prior conclusions
are claims to verify against the current build/runtime — never infer an input
from a downstream effect. The fix is verified against the original failure with
evidence before it is claimed to work.

### II. Durable Knowledge (OKF Knowledgebase)

Decisions, components, and open items that outlive a single session are promoted
into the Open Knowledge Format (OKF) knowledgebase as cross-linked concepts that
**link to** their source artifacts rather than duplicating them. The dated
session journal records what changed and why. Knowledge is a tracked output of
the work, not an afterthought.

### III. Privacy & De-identification Gate (NON-NEGOTIABLE)

No personal content, secrets, absolute home paths, or private project codenames
enter a public repo. Every commit passes the security/de-identification scan;
author-specific codenames live in a gitignored private denylist
(`DESTRIER_PRIVATE_DENYLIST`), never in tracked files. Free-text artifacts
(specs, plans, knowledgebase entries) are in scope for the gate.

### IV. Portability & Minimal Dependencies

Shell code is POSIX/bash-3.2-safe (no `mapfile`, no associative arrays). New
runtime dependencies are justified, gated behind explicit prerequisite checks
with exact install commands, and kept opt-in. External tools are wired in from
upstream and bootstrapped — never vendored, forked, or repackaged — so they stay
current.

### V. Versioning & Commit Discipline

Releases follow SemVer; commits follow Conventional Commits (`feat:` minor,
`fix:` patch, `BREAKING CHANGE:` major). User-facing changes update the README
and CHANGELOG in the same change. Every commit passes the test suite and the
security scan before it lands.

## Right-Sized Artifacts

destrier is a CLI/plugin project (shell + markdown) with no application build.
For such projects, `data-model.md`, `contracts/`, and `quickstart.md` are **N/A
by default** and may be skipped at the Constitution Check; the
`spec → tasks → implement` spine is the working subset. Empty greenfield-app
artifacts must not be produced solely to satisfy a template. English is the only
language for code, comments, log/print statements, identifiers, and docs.

## Development Workflow

Substantive work is brainstormed into a design, planned, and executed against an
explicit plan. Bridges into spec-kit's Spec-Driven Development loop are opt-in and
prompted, never automatic. Bugfixes and features are accompanied by tests in the
plain-bash harness (`test/`); the suite and the security scan are the quality
gates that run before merge.

## Governance

This constitution supersedes ad-hoc preference. Deviations must be justified in
the plan's Constitution Check and recorded. Amend via `/speckit.constitution`;
bump the constitution version per SemVer and let spec-kit propagate changes to
the plan/spec/tasks templates. All reviews verify compliance; complexity must be
justified.

**Version**: 1.0.0 | **Ratified**: 2026-06-24 | **Last Amended**: 2026-06-24
