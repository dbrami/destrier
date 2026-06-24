---
name: spec-driven-brainstorming
description: Use when authoring a project constitution or a feature specification under Spec-Driven Development (spec-kit) — i.e. before running /speckit-constitution or /speckit-specify. Makes collaborative brainstorming the front-end for those commands: brainstorm the intent, distill it to a short input brief, hand that to the speckit command, and continue the speckit loop — instead of writing a separate design doc and invoking writing-plans. Triggers on "write the constitution", "spec out this feature", "start a new feature under SDD", or any move toward /speckit-constitution / /speckit-specify.
---

# Spec-Driven Brainstorming

Make brainstorming the thinking front-end for spec-kit's authoring commands. The
collaborative exploration produces the understanding; spec-kit owns the canonical
artifacts (`.specify/memory/constitution.md`, `specs/NNN/spec.md`) and the
planning loop.

## When this applies

Use this whenever you are about to author, under spec-kit / Spec-Driven
Development:

- a **constitution** (project governing principles) → feeds `/speckit-constitution`
- a **feature spec** (one capability) → feeds `/speckit-specify`

If you are not working under spec-kit, use plain brainstorming → writing-plans
instead. This skill only reroutes the tail when spec-kit is the target.

## The way of working

1. **Detect the target artifact** — constitution or feature spec.

2. **Brainstorm first.** Invoke the `brainstorming` skill (superpowers) to explore
   one question at a time. If it is unavailable, run an equivalent: ask focused,
   one-at-a-time questions about purpose, constraints, and success criteria. Aim
   the exploration at the speckit artifact:
   - *constitution* — durable principles, non-negotiables, constraints, governance.
   - *feature spec* — the **what and why**: user stories, requirements, success
     criteria, scope and non-goals. **Not** the tech stack — that is
     `/speckit-plan`'s job.

3. **Distill, do not double-document.** Capture the agreed understanding as a
   short **input brief** (about a screen), not a full design doc.

4. **Hand off to spec-kit.** Pass the brief as the argument:
   - `/speckit-constitution <principles brief>` → writes `.specify/memory/constitution.md`.
     (For destrier itself, seed from `templates/destrier-constitution-values.md`.)
   - `/speckit-specify <what-and-why brief>` → scaffolds the feature branch and
     `specs/NNN/spec.md`.

5. **Continue the speckit loop** — `/speckit-clarify` (optional) → `/speckit-plan`
   → `/speckit-tasks` → `/speckit-implement`. This skill's job ends once the
   speckit artifact exists.

## The deliberate reroute

This **replaces** brainstorming's usual tail — writing a
`docs/superpowers/specs/*-design.md` and invoking `writing-plans` — **when working
under SDD**. spec-kit already produces the canonical spec/plan/tasks, so a parallel
superpowers design doc would just duplicate them. Do not write one; do not invoke
`writing-plans`. (Outside SDD, the normal brainstorming tail still applies.)

## Optional: feature → GitHub issue, then implement

After `/speckit-specify`, you can record the feature as a tracked GitHub issue
before implementing (the "issue-first" practice). destrier's spec-kit extension
prompts this on `after_specify` (opt-in); it creates one structured issue that
**links and summarizes** the spec (the spec stays canonical). Then link it from
the PR with `Closes #<n>`. This convention is documented, not enforced.

## Boundaries

- Soft dependency on the superpowers `brainstorming` skill; degrade to inline
  one-question exploration if absent.
- Produces an input brief, never a parallel design doc.
- Does not enforce issue-first or branch policies — it enables the practice.
