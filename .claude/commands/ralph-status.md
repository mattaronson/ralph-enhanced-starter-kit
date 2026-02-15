---
description: Display current RALPH loop state and progress
allowed-tools: Bash, Read
---

# Command: /ralph-status

Display current RALPH loop state and progress.

## What This Does

Shows overview of:
- Active loop and current stage
- Completed stages with summaries
- Remaining stages
- Files modified since checkpoint
- Open questions/blockers
- Last checkpoint time

## When To Use

- Quick progress check
- Before creating new checkpoint
- When resuming after long break
- To confirm loop configuration

## Execution Steps

### Step 1 — Check for Checkpoint

```bash
ls project-docs/checkpoints/CURRENT_STATE.md 2>/dev/null
```

If not found:
```
No active RALPH loop.

To get started:
  1. Configure loops in .claude/ralph/config.yml
     (copy from .claude/ralph/config.yml.example)
  2. Start working on your task
  3. Run /ralph-checkpoint to save progress
```
Stop execution.

### Step 2 — Load Checkpoint

```bash
cat project-docs/checkpoints/CURRENT_STATE.md
```

Parse the checkpoint content.

### Step 3 — Calculate Time Since Checkpoint

Extract timestamp and calculate elapsed time. Display as:
- "X minutes ago" (if < 1 hour)
- "X hours ago" (if < 24 hours)
- "X days ago" (if >= 24 hours)

### Step 4 — Count File Changes Since Checkpoint

```bash
git diff --name-only HEAD 2>/dev/null | wc -l
git diff --cached --name-only 2>/dev/null | wc -l
```

### Step 5 — Load Loop Config

```bash
cat .claude/ralph/config.yml 2>/dev/null
```

Match the checkpoint's loop name to the config to get all stages.

### Step 6 — Display Status

Format and display:

```
RALPH Status
═══════════════════════════════════════
Loop: {{LOOP_NAME}}
Stage: {{CURRENT_STAGE}} ({{STAGE_NUMBER}}/{{TOTAL_STAGES}})
Last checkpoint: {{TIME_AGO}}

Progress:
  [x] {{STAGE_1}}  — {{SUMMARY_1}}
  [>] {{STAGE_2}}  — {{CURRENT_WORK}} (in progress)
  [ ] {{STAGE_3}}  — Not started
  [ ] {{STAGE_4}}  — Not started

Next objectives:
  - {{OBJECTIVE_1}}
  - {{OBJECTIVE_2}}
  - {{OBJECTIVE_3}}

Blockers: {{BLOCKERS_OR_NONE}}
Files changed since checkpoint: {{FILE_COUNT}}
═══════════════════════════════════════
```

Legend:
- `[x]` = completed stage
- `[>]` = current/in-progress stage
- `[ ]` = not started

### Step 7 — Suggest Actions

Based on status, suggest next action:
- If blockers exist: "Resolve blockers before proceeding."
- If stage is nearly complete: "Consider running `/ralph-checkpoint` to save progress."
- If checkpoint is old (> 4 hours): "Checkpoint is getting stale — consider updating with `/ralph-checkpoint`."
- If all stages complete: "Loop complete! Create a final checkpoint with `/ralph-checkpoint` to record completion."
