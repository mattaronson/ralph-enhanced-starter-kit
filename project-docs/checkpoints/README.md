# RALPH Checkpoints

This directory contains RALPH loop checkpoints for multi-session work.

## Files

- **CURRENT_STATE.md** - Active checkpoint (gitignored)
  - Created by `/ralph-checkpoint`
  - Loaded by `/ralph-resume`
  - Displayed by `/ralph-status`

- **archive/** - Previous checkpoints (gitignored)
  - Auto-archived when new checkpoint created
  - Max 10 archives kept (configurable)
  - Named: `checkpoint-YYYY-MM-DD-HHMMSS.md`

## Usage

### Create Checkpoint
```bash
/ralph-checkpoint
```
Saves current loop state, completed work, and next objectives.

### Resume From Checkpoint
```bash
/ralph-resume
```
Loads checkpoint, verifies integrity, displays next objectives.

### Check Status
```bash
/ralph-status
```
Shows current loop, stage, progress, and blockers.

### Complete Stage and Advance
```bash
/ralph-complete-stage
```
Marks current stage as done, auto-checkpoints, and advances to the next stage.
On the final stage, marks the entire loop as COMPLETED.

## Loop Configuration

Loops defined in `.claude/ralph/config.yml`:

- **feature-development**: Standard feature workflow (plan, implement, test, document)
- **migration**: Project migration workflow (assess, migrate, validate, cleanup)
- **debugging**: Systematic debugging workflow (reproduce, diagnose, fix, verify)

### Custom Loops

Add custom loops to `config.yml`:

```yaml
loops:
  - name: "my-custom-loop"
    description: "Description"
    stages:
      - name: "stage1"
        objectives: ["objective1", "objective2"]
      - name: "stage2"
        objectives: ["objective3", "objective4"]
    checkpoint_after_stage: true
```

See `.claude/ralph/templates/loop-definitions.yml` for more pre-built loop templates.

## Auto-Checkpoint

Automatic checkpoints trigger when:
- 500+ lines changed (configurable)
- 30+ minutes elapsed (configurable)
- Before major refactors (if enabled)
- **Stage marked complete** via `/ralph-complete-stage`

When a stage is completed, the PostToolUse hook automatically:
1. Creates a new checkpoint with the completed stage recorded
2. Advances to the next stage in the loop
3. Populates next-stage objectives from the config

Configure thresholds in `.claude/ralph/config.yml` under `auto_checkpoint`.

## Safety

- File tree hash verified on resume
- Warns if manual changes detected since checkpoint
- Archives previous checkpoints automatically
- Checkpoint age checked on resume (warns if > 7 days)

## Helper Scripts

Shell scripts for manual checkpoint operations:

```bash
# Create checkpoint from command line
bash scripts/ralph/create-checkpoint.sh

# Create checkpoint with auto stage advancement (used by hooks)
bash scripts/ralph/create-checkpoint.sh --auto --advance-stage

# Mark current stage as complete (triggers auto-advancement)
bash scripts/ralph/complete-stage.sh

# Validate current checkpoint integrity
bash scripts/ralph/validate-checkpoint.sh

# Show current checkpoint or restore from archive
bash scripts/ralph/restore-checkpoint.sh
bash scripts/ralph/restore-checkpoint.sh checkpoint-2025-01-15-143000.md
```

## Integration

RALPH works with other starter kit features:
- Hooks verify checkpoints and suggest auto-checkpoints
- Commands create/load/display state interactively
- CLAUDE.md documents the checkpoint protocol
- Setup script configures RALPH defaults
