---
description: Mark current RALPH stage as complete and advance to next stage
allowed-tools: Bash, Read, Write, Edit
---

# Command: /ralph-complete-stage

Mark the current RALPH stage as complete, create an auto-checkpoint, and advance to the next stage in the loop.

## What This Does

1. Reads current loop and stage from `CURRENT_STATE.md`
2. Looks up stage list from `.claude/ralph/config.yml`
3. Shows current stage, next stage, and upcoming objectives
4. Asks user to confirm completion
5. Creates a `.ralph-stage-complete` marker file
6. Next PostToolUse hook triggers auto-checkpoint with stage advancement
7. Checkpoint is created and stage advances automatically

## When To Use

- Finished all objectives for current stage
- Ready to move to next stage in the loop
- Want automatic checkpoint + advancement in one step
- Final stage: marks the entire loop as COMPLETED

## Execution Steps

1. Check that `project-docs/checkpoints/CURRENT_STATE.md` exists
   - If not: "No active checkpoint. Create one with `/ralph-checkpoint` first."

2. Check that `.claude/ralph/config.yml` exists
   - If not: "RALPH not configured. Run `/setup` or copy config.yml.example."

3. Run the stage completion helper:
```bash
bash scripts/ralph/complete-stage.sh
```

4. The script will:
   - Display current loop and stage
   - Show next stage objectives
   - Ask for confirmation
   - Create `.ralph-stage-complete` marker

5. After confirmation, run any command (even a simple `ls`) to trigger the PostToolUse hook, which will:
   - Detect the `.ralph-stage-complete` marker
   - Auto-create checkpoint via `scripts/ralph/create-checkpoint.sh --auto --advance-stage`
   - Remove the marker file
   - Display advancement confirmation

6. Verify advancement:
```bash
bash scripts/ralph/restore-checkpoint.sh
```

## Example: Mid-Loop Advancement

```
/ralph-complete-stage

RALPH Stage Completion

  Loop:  migration
  Stage: migrate (2/4)

  Next stage: validate (3/4)
  Next objectives:
    - All tests pass
    - No TypeScript errors
    - Manual smoke test

Mark stage 'migrate' as complete? (y/n): y

Stage 'migrate' marked complete.
  Will advance to: validate (3/4)
  Auto-checkpoint will trigger on next tool use.
```

## Example: Final Stage (Loop Completion)

```
/ralph-complete-stage

RALPH Stage Completion

  Loop:  migration
  Stage: cleanup (4/4)

  This is the FINAL stage of the loop.
  Completing will mark the entire loop as DONE.

Mark stage 'cleanup' as complete? (y/n): y

Stage 'cleanup' marked complete.
  Loop 'migration' will be marked COMPLETED on next action.
  Auto-checkpoint will trigger on next tool use.
```

## Safety

- Requires explicit user confirmation before marking complete
- Validates checkpoint and config exist
- Validates current stage is in the loop definition
- Final stage completion clearly warns it ends the loop
- Manual `/ralph-checkpoint` still works for mid-stage saves (doesn't advance)

## Related Commands

- `/ralph-checkpoint` — Manual checkpoint (does NOT advance stage)
- `/ralph-resume` — Resume from last checkpoint
- `/ralph-status` — View current loop progress
