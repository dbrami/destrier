# destrier constitution — starter values

**How to use this file:** this is *input* for spec-kit's `/speckit-constitution`
command, **not** a replacement for `.specify/memory/constitution.md`. Paste the
principles below (edit as needed) into `/speckit-constitution` so spec-kit fills,
versions, and propagates the constitution through its own lifecycle. Do not copy
this file over the generated constitution — `/speckit-constitution` owns that file.

Suggested prompt:

> Create/update the project constitution with these principles, keeping spec-kit's
> SemVer + Sync Impact Report machinery.

## Principles

1. **Evidence-driven debugging (NON-NEGOTIABLE).** Any failing test, error, crash,
   4xx/5xx/timeout, or surprising behavior is debugged by capturing ground truth
   at the boundary (logs, actual payloads, runtime state) before proposing a fix.
   Treat docs, comments, and prior conclusions as claims to verify against the
   current build/runtime — never infer an input from a downstream effect. Verify
   the fix against the original failure with evidence before claiming it works.

2. **Durable knowledge (OKF knowledgebase).** Decisions, components, and open
   items that outlive a single session are promoted into the Open Knowledge Format
   knowledgebase as cross-linked concepts that *link to* their source artifacts
   rather than duplicating them. The session journal records what changed and why.

3. **Privacy & de-identification gate.** No personal content, secrets, absolute
   home paths, or private project codenames may enter a public repo. Every commit
   passes the security/de-identification scan; author-specific codenames live in a
   gitignored private denylist (`DESTRIER_PRIVATE_DENYLIST`), never in tracked files.

4. **Portability & minimal dependencies.** Shell code is POSIX/bash-3.2-safe (no
   `mapfile`, no associative arrays); new runtime dependencies are justified,
   gated behind explicit prerequisite checks, and kept opt-in. External tools are
   wired in from upstream, not vendored or repackaged.

5. **English-only artifacts.** All authored code, comments, log/print statements,
   identifiers, and docs are English only.

6. **Versioning & commit discipline.** Releases follow SemVer; commits follow
   Conventional Commits (`feat:` minor, `fix:` patch, `BREAKING CHANGE:` major).
   User-facing changes update the README and CHANGELOG in the same change.

7. **Right-sized artifacts for the project type.** For a CLI/plugin project with
   no application build (shell + markdown), `data-model.md`, `contracts/`, and
   `quickstart.md` are **N/A by default** and may be skipped at the Constitution
   Check; the spec → tasks → implement spine is the working subset. Do not produce
   empty greenfield-app artifacts to satisfy a template.

## Governance

- The constitution supersedes ad-hoc preference; deviations must be justified in
  the plan's Constitution Check and recorded.
- Amend via `/speckit-constitution`; bump the constitution version per SemVer and
  let spec-kit propagate changes to the plan/spec/tasks templates.
