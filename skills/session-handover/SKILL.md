---
name: session-handover
description: Use at the start and end of any work session to maintain a durable, model-labeled knowledgebase. At start, read the last few session summaries for continuity; during work, append dated deltas; at end, update the index. Use when resuming work, handing off between sessions or agents, or when the user mentions a knowledgebase, session summary, or handover.
---

# Session Handover

Maintain continuity across sessions with a lightweight, append-only knowledgebase.

## Start of session
1. Run `scripts/kb-init.sh <your-agent-label>` (or `/codeman-kb-init`). It creates
   today's `docs/knowledgebase/sessions/YYYY-MM-DD-summary.md` if needed and prints
   the last 3 summaries.
2. Read those summaries before acting. If work is in flight, also check `git status`
   and any linked issue/PR before assuming what remains.

## During the session
Append deltas under a metadata header that records the model and effort tier:

```
### [Agent: <name> | Model: <model + effort> | Timestamp: YYYY-MM-DD HH:MM]
- What changed / decisions / open items
```

## End of session
Update `docs/knowledgebase/INDEX.md` with a one-line pointer to today's summary.
Record whether work was committed/pushed or left local, and name any linked issue/PR
so the next session can reconcile the knowledgebase with the repo state.

Templates live in this plugin's `templates/` (`session-summary.md`, `INDEX.md`).
This skill ships no content — only the workflow.
