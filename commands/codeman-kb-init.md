---
description: Initialize today's knowledgebase session summary (an OKF v0.1 bundle) in the current repo and show the last 3 summaries.
---

Run the KB initializer for the current repository, then read the printed recent
summaries before continuing. It creates/extends an Open Knowledge Format (OKF)
v0.1 bundle under `docs/knowledgebase/` (frontmatter, `index.md`, `log.md`).

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/kb-init.sh" "Claude"
```

After running, read the last 3 session summaries it lists and follow the
session-handover skill for the rest of the session. To promote durable
decisions/components/open-items into cross-linked concept files, use:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/kb-concept.sh" <type> "<title>" [tags-csv]
```
