---
description: Set "clean" as the default profile for /new-project
allowed-tools: Read, Edit
---

# Set Clean as Default Profile

Make `clean` the default profile in `claude-mastery-project.conf` so that `/new-project PROJECTNAME` (with no profile specified) runs the `clean` profile instead of `default`.

## Steps

### 1. Read the config file

Read `claude-mastery-project.conf` from the project root. If not found, check `~/.claude/claude-mastery-project.conf`.

### 2. Add or update `default_profile` in `[global]`

In the `[global]` section, set:

```
default_profile = clean
```

- If `default_profile` already exists in `[global]`, change its value to `clean`
- If `default_profile` does not exist, add it after the last line in the `[global]` section (before the next `[section]`)

### 3. Confirm

After editing, read the file back and confirm the change was applied. Show the updated `[global]` section to the user.

Tell the user:

> Done. `/new-project PROJECTNAME` will now use the `clean` profile by default — all the AI goodies, zero coding opinions. You can still override with `/new-project PROJECTNAME default` or any other profile name.
