---
description: Reset /new-project back to the original "default" profile
allowed-tools: Read, Edit
---

# Reset to Default Profile

Reset `claude-mastery-project.conf` so that `/new-project PROJECTNAME` uses the `default` profile again (full opinionated stack: Next.js, MongoDB, Tailwind, Docker, etc.).

## Steps

### 1. Read the config file

Read `claude-mastery-project.conf` from the project root. If not found, check `~/.claude/claude-mastery-project.conf`.

### 2. Update `default_profile` in `[global]`

- If `default_profile` exists in `[global]`, change its value to `default`
- If `default_profile` does not exist, add `default_profile = default` after the last line in the `[global]` section (before the next `[section]`)

### 3. Confirm

After editing, read the file back and confirm the change was applied. Show the updated `[global]` section to the user.

Tell the user:

> Done. `/new-project PROJECTNAME` will now use the `default` profile again — full opinionated stack (Next.js, MongoDB, Tailwind, Docker, CI, Rybbit, MCP servers). You can still override with `/new-project PROJECTNAME clean` or any other profile name.
