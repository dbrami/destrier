---
description: "Run destrier flow-metrics now that tasks have become GitHub issues"
---

# Flow-metrics after tasks -> issues

`/speckit-taskstoissues` just converted `tasks.md` into GitHub issues. destrier's
`flow-metrics` reports throughput and cycle-time over GitHub **issues** (it has no
`tasks.md` code path), so this is the moment the data exists to measure.

## Steps

1. **Locate destrier.** Read the plugin root from `<git-dir>/destrier-root`,
   where `<git-dir>` is `git rev-parse --git-dir`. If missing or it does not
   contain `scripts/flow-metrics.py`, report that destrier is unavailable and stop
   without error.

2. **Confirm prerequisites.** `flow-metrics` needs `gh` authenticated for this
   repo. If `gh auth status` fails, tell the user to run `gh auth login` and stop.

3. **Run it** for the current repo (default window is the last 12 weeks):

   ```bash
   ROOT="$(cat "$(git rev-parse --git-dir)/destrier-root")"
   python3 "$ROOT/scripts/flow-metrics.py"
   ```

   To scope to specific repos or a different window, pass `--repo owner/name`
   (repeatable) and/or `--weeks N`.

4. **Report** the throughput trend, cycle-time p50/p85, and WIP-aging summary it
   prints. The leading indicator is rising WIP with flat throughput.
