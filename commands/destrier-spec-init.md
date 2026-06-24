---
description: Set up Spec-Driven Development (spec-kit) in the current repo — installs the pinned `specify` CLI, runs `specify init`, and registers destrier's bridge extension.
---

Bring **Spec-Driven Development** to this repository. destrier bootstraps GitHub
[spec-kit](https://github.com/github/spec-kit)'s upstream `specify` CLI (no
vendoring), initializes it, and registers destrier's bridge extension — without
forking any spec-kit command, so `specify self upgrade` keeps working.

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/spec-init.sh"
```

The script verifies prerequisites (`uv`, `python3 >= 3.11`, `git`) and prints the
exact install command for anything missing. It is idempotent: re-running never
clobbers an existing constitution or `specs/`. To only check prerequisites
without making changes:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/spec-init.sh" --check
```

After it succeeds:

1. **Establish principles.** Run `/speckit-constitution` and feed it destrier's
   house rules from `${CLAUDE_PLUGIN_ROOT}/templates/destrier-constitution-values.md`
   (this fills `.specify/memory/constitution.md` via spec-kit's own command — do
   not paste the file in as a replacement).
2. **Drive the loop:** `/speckit-specify` → `/speckit-clarify` → `/speckit-plan`
   → `/speckit-tasks` → `/speckit-implement`. spec-kit installs these as Claude
   **skills** (invoke as `/speckit-…`).
3. **Bridges (optional, prompted):** after `/speckit-plan`, destrier offers to
   record the plan's decisions in the OKF knowledgebase (a link-only pointer, not
   a copy); after `/speckit-taskstoissues`, it offers to run flow-metrics.

> Privacy: **set `DESTRIER_PRIVATE_DENYLIST` before authoring specs.** Spec
> free-text is committed and scanned by the security gate; private codenames must
> not leak — especially when the repo is public.
