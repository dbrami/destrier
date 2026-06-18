---
description: Bootstrap codeman's external tools — build gitnexus from git and install roborev via its official installer.
---

Run the codeman bootstrap. It installs gitnexus (git clone + build) and roborev
(official installer); neither tool is vendored or repackaged by codeman.

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/bootstrap.sh"
```

If a prerequisite is missing, the script prints exactly what to install. After it
finishes, tell the user to restart Claude Code so the gitnexus MCP server loads,
and to run `gitnexus analyze` once per repository they want indexed.
