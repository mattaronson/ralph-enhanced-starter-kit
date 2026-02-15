---
description: Create a RALPH checkpoint to persist current work state
allowed-tools: Bash, Read, Write, Edit, AskUserQuestion
---

# Command: /ralph-checkpoint

Create a RALPH checkpoint to persist current work state.

## What This Does

1. Captures current loop and stage
2. Documents completed work
3. Records file changes and state hash
4. Identifies next stage objectives
5. Saves checkpoint to `project-docs/checkpoints/CURRENT_STATE.md`
6. Archives previous checkpoint

## When To Use

- End of work session
- Before major refactors
- After completing a loop stage
- When approaching token limit
- Before context switch to different task

## Execution Steps

### Step 1 — Check RALPH Configuration

```bash
ls .claude/ralph/config.yml 2>/dev/null
```

If no config exists:
- "RALPH not configured. Run `/setup` and enable RALPH, or copy `.claude/ralph/config.yml.example` to `.claude/ralph/config.yml`"
- Stop execution

### Step 2 — Load Current Config

```bash
cat .claude/ralph/config.yml
```

Read the config to determine:
- Available loops and their stages
- Checkpoint storage paths
- Max archive count

### Step 3 — Check for Existing Checkpoint

```bash
ls project-docs/checkpoints/CURRENT_STATE.md 2>/dev/null
```

If exists, read it to determine current loop and stage context.

### Step 4 — Gather Checkpoint Data

Ask the user using AskUserQuestion:

1. **"Which loop are you working in?"** — Show options from config (feature-development, migration, debugging)
2. **"Which stage are you on?"** — Show stages for selected loop
3. **"Summarize work completed in current stage:"** — Free text

### Step 5 — Generate File Tree Hash

```bash
find . -type f -not -path '*/.git/*' -not -path '*/node_modules/*' -not -path '*/dist/*' -not -path '*/coverage/*' | sort | md5sum | awk '{print $1}'
```

On Windows (if md5sum not available):
```bash
find . -type f -not -path '*/.git/*' -not -path '*/node_modules/*' -not -path '*/dist/*' -not -path '*/coverage/*' | sort | sha256sum | awk '{print $1}'
```

### Step 6 — Get Files Modified

```bash
git diff --name-only HEAD 2>/dev/null || echo "Not a git repo or no changes"
git diff --cached --name-only 2>/dev/null
```

### Step 7 — Archive Previous Checkpoint

If `CURRENT_STATE.md` exists:

```bash
TIMESTAMP=$(date +%Y-%m-%d-%H%M%S)
mkdir -p project-docs/checkpoints/archive
cp project-docs/checkpoints/CURRENT_STATE.md "project-docs/checkpoints/archive/checkpoint-$TIMESTAMP.md"
```

Then enforce max archives (from config, default 10):

```bash
MAX_ARCHIVES=10
ls -t project-docs/checkpoints/archive/checkpoint-*.md 2>/dev/null | tail -n +$((MAX_ARCHIVES + 1)) | xargs rm -f 2>/dev/null
```

### Step 8 — Write New Checkpoint

Use the template from `.claude/ralph/templates/checkpoint.md` and fill in all variables:

- `{{TIMESTAMP}}` — Current ISO timestamp
- `{{SESSION_ID}}` — Generate a short unique ID (first 8 chars of timestamp hash)
- `{{LOOP_NAME}}` — Selected loop name
- `{{CURRENT_STAGE}}` — Current stage name
- `{{STAGE_NUMBER}}` / `{{TOTAL_STAGES}}` — Stage position
- `{{COMPLETED_STAGES}}` — List of completed stages with summaries
- `{{CURRENT_STAGE_WORK}}` — User's work summary
- `{{NEXT_STAGE}}` — Next stage name (or "LOOP COMPLETE" if final stage)
- `{{NEXT_STAGE_OBJECTIVES}}` — Objectives for next stage
- `{{FILES_MODIFIED}}` — Git diff file list
- `{{FILE_TREE_HASH}}` — Generated hash
- `{{KEY_DECISIONS}}` — Ask user or leave "None noted"
- `{{OPEN_QUESTIONS}}` — Ask user or leave "None"
- `{{NOTES}}` — Any additional notes

Write the filled template to `project-docs/checkpoints/CURRENT_STATE.md`.

### Step 9 — Confirm

Display:

```
Checkpoint created
  Loop: {{LOOP_NAME}}
  Stage: {{CURRENT_STAGE}} ({{STAGE_NUMBER}}/{{TOTAL_STAGES}})
  Files changed: {{FILE_COUNT}}
  Next stage: {{NEXT_STAGE}}

Resume with: /ralph-resume
```
