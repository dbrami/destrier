---
description: "Promote the plan's durable decisions into a link-only destrier OKF knowledgebase concept"
---

# Record plan decisions in the destrier knowledgebase

Create a **link-only** Open Knowledge Format (OKF) concept stub in this repo's
durable knowledgebase that points at the plan you just produced. **Never copy the
plan's content** — `specs/<feature>/plan.md` is already the source of record; this
stub only adds a durable, cross-linkable pointer so the decision survives across
sessions in destrier's concept graph.

## Steps

1. **Locate destrier.** Read the destrier plugin root from
   `.specify/extensions/destrier-sdd/.destrier-root` (a single path written at
   `/destrier-spec-init` time). If the file is missing or the path does not
   contain `scripts/kb-concept.sh`, report that destrier is not available in this
   project and stop without error (the bridge is opt-in).

2. **Find the plan.** Use the current feature's plan: the `IMPL_PLAN`/`SPECS_DIR`
   from spec-kit's feature state if available, otherwise the most recently
   modified `specs/*/plan.md`. Derive a short concept title from the feature
   directory name or the plan's Summary (e.g. "spec-kit SDD integration").

3. **Scaffold the concept** (reuses destrier's own scaffolder — do not hand-roll
   the OKF format):

   ```bash
   ROOT="$(cat .specify/extensions/destrier-sdd/.destrier-root)"
   bash "$ROOT/scripts/kb-concept.sh" decision "<concept title>" sdd,plan
   ```

   It prints the absolute path of the created concept file under
   `docs/knowledgebase/concepts/decisions/`.

4. **Make it a pointer, not a copy.** Edit the created concept:
   - Replace the `description:` frontmatter `TODO` with a one-line summary of the
     decision (≤ 120 chars).
   - Replace the body `TODO` with one or two sentences naming the decision, then
     a link to the plan under `## Related` using a path **relative to the concept
     file** (the concept is at `docs/knowledgebase/concepts/decisions/<slug>.md`;
     the plan is at `specs/<feature>/plan.md`). Also link the spec
     (`specs/<feature>/spec.md`) if present.

5. **Report** the concept path you created and confirm no plan content was copied.

## Notes

- Privacy: this writes into `docs/knowledgebase/`, which is committed and scanned
  by destrier's security gate. Do not paste secrets or private codenames into the
  summary; set `DESTRIER_PRIVATE_DENYLIST` before authoring specs.
- If a concept for this decision already exists, `kb-concept.sh` exits non-zero;
  treat that as "already recorded" and just report the existing path.
