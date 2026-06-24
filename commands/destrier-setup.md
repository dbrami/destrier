---
description: Bootstrap destrier's external tools — build gitnexus from git and install roborev via its official installer.
---

Run the destrier bootstrap. It first verifies every prerequisite (git, rg, jq,
node, npm, python3, gh, curl), then installs gitnexus (git clone + build) and
roborev (official installer); neither tool is vendored or repackaged by destrier.

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/bootstrap.sh"
```

If any prerequisite is missing, the script prints the exact install command for
the user's platform. To have destrier install the missing prerequisites
automatically via the detected package manager (brew/apt/dnf/yum), re-run with:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/bootstrap.sh" --install-deps
```

After it finishes, tell the user to restart Claude Code so the gitnexus MCP
server loads, and to run `gitnexus analyze` once per repository they want indexed.

## Optional: Spec-Driven Development

destrier can also bring GitHub spec-kit's Spec-Driven Development loop into a repo
(`constitution → specify → plan → tasks → implement`). This is **opt-in** and
per-repo — it is not installed by bootstrap. It needs `uv` and `python3 >= 3.11`
(the prerequisite check reports `uv` status). To enable it in the current repo,
run `/destrier-spec-init`.
