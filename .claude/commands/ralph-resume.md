---
description: Resume work from the last RALPH checkpoint
allowed-tools: Bash, Read, Write, Edit, AskUserQuestion
---

# Command: /ralph-resume

Resume work from the last RALPH checkpoint.

## What This Does

1. Loads `CURRENT_STATE.md` checkpoint
2. Verifies file tree integrity
3. Reviews completed work
4. Confirms next stage objectives
5. Resumes execution at current stage

## When To Use

- Starting new session after checkpoint
- After context cleared with `/clear`
- When returning to paused work

## Execution Steps

### Step 1 — Check for Checkpoint

```bash
ls project-docs/checkpoints/CURRENT_STATE.md 2>/dev/null
```

If not found:
- "No checkpoint found. Start fresh or use `/ralph-checkpoint` to create one."
- Stop execution

### Step 2 — Load Checkpoint

```bash
cat project-docs/checkpoints/CURRENT_STATE.md
```

Parse the checkpoint to extract:
- Loop name
- Current stage and stage number
- Completed stages
- Next stage and objectives
- File tree hash
- Open questions/blockers

### Step 3 — Check Checkpoint Age

Extract the timestamp from the checkpoint. If older than 7 days:

```
Warning: Checkpoint is {{AGE}} days old.
The project may have changed significantly since this checkpoint.
Consider creating a fresh checkpoint with /ralph-checkpoint.
```

Ask: "Continue with this checkpoint anyway? (y/n)"

### Step 4 — Verify File Tree Integrity

Generate current file tree hash:

```bash
find . -type f -not -path '*/.git/*' -not -path '*/node_modules/*' -not -path '*/dist/*' -not -path '*/coverage/*' | sort | md5sum | awk '{print $1}'
```

On Windows (if md5sum not available):
```bash
find . -type f -not -path '*/.git/*' -not -path '*/node_modules/*' -not -path '*/dist/*' -not -path '*/coverage/*' | sort | sha256sum | awk '{print $1}'
```

Compare with stored hash:
- If match: "File tree verified — no changes since checkpoint."
- If mismatch: "Warning: File tree changed since checkpoint. Files may have been modified manually. Review changes before proceeding."

If mismatch, show what changed:
```bash
git status --short 2>/dev/null
```

### Step 5 — Display Checkpoint Summary

```
Resuming: {{LOOP_NAME}}
Stage: {{CURRENT_STAGE}} ({{STAGE_NUMBER}}/{{TOTAL_STAGES}})

Completed:
  [x] {{STAGE_1}}: {{SUMMARY_1}}
  [x] {{STAGE_2}}: {{SUMMARY_2}}

Current stage progress:
  {{CURRENT_STAGE_WORK}}

Next objectives:
  - [ ] {{OBJECTIVE_1}}
  - [ ] {{OBJECTIVE_2}}
  - [ ] {{OBJECTIVE_3}}
```

### Step 6 — Check for Blockers

If the checkpoint has open questions or blockers:

```
Blockers from last session:
  {{OPEN_QUESTIONS}}

These should be resolved before proceeding.
```

### Step 7 — Confirm Resume

Ask: "Ready to proceed with {{NEXT_STAGE}}? (y/n)"

- If **yes**: Begin executing next stage objectives. Load the RALPH config to understand the full loop context, then work through each objective.
- If **no**: "Use `/ralph-status` to review or `/ralph-checkpoint` to update state."

### Step 8 — Load Context

If resuming, also load:
- `.claude/ralph/config.yml` for loop definitions
- Key decisions from checkpoint for context
- Modified files list for awareness

Then begin working on the next stage objectives.

## Safety Checks

- Verify checkpoint timestamp is reasonable (< 7 days old)
- Check for file tree hash mismatch (manual changes)
- Warn if checkpoint indicates blockers or open questions
- Never skip directly to a later stage — always resume from current position
