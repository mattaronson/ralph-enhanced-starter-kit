#!/bin/bash
# Helper: Create checkpoint (used by /ralph-checkpoint command and auto-advancement)
#
# Flags:
#   --auto            Suppress interactive prompts (used by hooks)
#   --advance-stage   Read .ralph-stage-complete marker and advance to next stage
set -e

CONFIG_FILE=".claude/ralph/config.yml"
CHECKPOINT_DIR="project-docs/checkpoints"
CURRENT_STATE="$CHECKPOINT_DIR/CURRENT_STATE.md"
ARCHIVE_DIR="$CHECKPOINT_DIR/archive"
MARKER_FILE=".ralph-stage-complete"

# Parse flags
AUTO_MODE=false
ADVANCE_STAGE=false
for arg in "$@"; do
  case "$arg" in
    --auto) AUTO_MODE=true ;;
    --advance-stage) ADVANCE_STAGE=true ;;
  esac
done

if [ ! -f "$CONFIG_FILE" ]; then
  echo "Error: RALPH not configured. Run setup first."
  echo "Copy .claude/ralph/config.yml.example to .claude/ralph/config.yml"
  exit 1
fi

# Ensure directories exist
mkdir -p "$CHECKPOINT_DIR"
mkdir -p "$ARCHIVE_DIR"

# --- Read previous checkpoint state (for advancement) ---

PREV_LOOP=""
PREV_STAGE=""
PREV_COMPLETED_WORK=""
NEW_LOOP=""
NEW_STAGE=""
NEW_STAGE_NUM=""
NEW_TOTAL=""
NEXT_STAGE_NAME=""
NEXT_OBJECTIVES_TEXT=""
LOOP_COMPLETED=false

if [ "$ADVANCE_STAGE" = true ] && [ -f "$MARKER_FILE" ]; then
  # Read marker metadata
  MARKER_LOOP=$(grep "^loop=" "$MARKER_FILE" | cut -d= -f2)
  MARKER_COMPLETED_STAGE=$(grep "^completed_stage=" "$MARKER_FILE" | cut -d= -f2)
  MARKER_INDEX=$(grep "^completed_stage_index=" "$MARKER_FILE" | cut -d= -f2)
  MARKER_TOTAL=$(grep "^total_stages=" "$MARKER_FILE" | cut -d= -f2)
  MARKER_IS_FINAL=$(grep "^is_final=" "$MARKER_FILE" | cut -d= -f2)

  NEW_LOOP="$MARKER_LOOP"

  if [ "$MARKER_IS_FINAL" = "true" ]; then
    # Loop is complete
    LOOP_COMPLETED=true
    NEW_STAGE="COMPLETED"
    NEW_STAGE_NUM="$MARKER_TOTAL"
    NEW_TOTAL="$MARKER_TOTAL"
  else
    # Advance to next stage — read stage names from config
    STAGE_NAMES=()
    IN_LOOP=false
    IN_STAGES=false
    while IFS= read -r line; do
      if echo "$line" | grep -q "name: \"$MARKER_LOOP\""; then
        IN_LOOP=true
        continue
      fi
      if [ "$IN_LOOP" = true ] && echo "$line" | grep -q "stages:"; then
        IN_STAGES=true
        continue
      fi
      if [ "$IN_LOOP" = true ] && [ "$IN_STAGES" = true ]; then
        if echo "$line" | grep -qE "checkpoint_after_stage:|^  - name:"; then
          break
        fi
        STAGE_NAME=$(echo "$line" | grep '      - name:' | sed 's/.*name: "\(.*\)"/\1/')
        if [ -n "$STAGE_NAME" ]; then
          STAGE_NAMES+=("$STAGE_NAME")
        fi
      fi
    done < "$CONFIG_FILE"

    NEXT_INDEX=$((MARKER_INDEX + 1))
    NEW_STAGE="${STAGE_NAMES[$NEXT_INDEX]}"
    NEW_STAGE_NUM="$((NEXT_INDEX + 1))"
    NEW_TOTAL="${#STAGE_NAMES[@]}"

    # Get next stage objectives from config
    # Handles both inline format: objectives: ["A", "B", "C"]
    # and multi-line format:     objectives:\n  - "A"\n  - "B"
    NEXT_OBJECTIVES_TEXT=""
    OBJ_LINE=$(grep -A 1 "name: \"$NEW_STAGE\"" "$CONFIG_FILE" | grep "objectives:")

    if echo "$OBJ_LINE" | grep -q '\['; then
      # Inline array: objectives: ["Write code", "Follow TypeScript standards"]
      OBJS=$(echo "$OBJ_LINE" | sed 's/.*\[//;s/\].*//' | tr ',' '\n')
      while IFS= read -r item; do
        item=$(echo "$item" | sed 's/^ *//;s/ *$//;s/^"//;s/"$//')
        if [ -n "$item" ]; then
          NEXT_OBJECTIVES_TEXT="$NEXT_OBJECTIVES_TEXT
- [ ] $item"
        fi
      done <<< "$OBJS"
    else
      # Multi-line: read objectives list after the objectives: key
      IN_NEXT_STAGE=false
      IN_OBJECTIVES=false
      while IFS= read -r line; do
        if echo "$line" | grep -q "name: \"$NEW_STAGE\""; then
          IN_NEXT_STAGE=true
          continue
        fi
        if [ "$IN_NEXT_STAGE" = true ] && echo "$line" | grep -q "objectives:"; then
          IN_OBJECTIVES=true
          continue
        fi
        if [ "$IN_NEXT_STAGE" = true ] && [ "$IN_OBJECTIVES" = true ]; then
          if echo "$line" | grep -q '^ *- "'; then
            OBJ=$(echo "$line" | sed 's/.*- "\(.*\)".*/\1/')
            NEXT_OBJECTIVES_TEXT="$NEXT_OBJECTIVES_TEXT
- [ ] $OBJ"
          else
            break
          fi
        fi
      done < "$CONFIG_FILE"
    fi

    # Figure out what stage comes AFTER the new stage (for "Next Stage" section)
    if [ "$((NEXT_INDEX + 1))" -lt "${#STAGE_NAMES[@]}" ]; then
      NEXT_STAGE_NAME="${STAGE_NAMES[$((NEXT_INDEX + 1))]}"
    else
      NEXT_STAGE_NAME="(final stage)"
    fi
  fi

  # Build completed stages summary from previous checkpoint
  if [ -f "$CURRENT_STATE" ]; then
    PREV_COMPLETED_WORK=$(sed -n '/## Completed Work/,/## Next/p' "$CURRENT_STATE" | head -n -1 | tail -n +2)
  fi
fi

# --- Archive previous checkpoint if exists ---

if [ -f "$CURRENT_STATE" ]; then
  TIMESTAMP=$(date +%Y-%m-%d-%H%M%S)
  cp "$CURRENT_STATE" "$ARCHIVE_DIR/checkpoint-$TIMESTAMP.md"
  if [ "$AUTO_MODE" = false ]; then
    echo "Previous checkpoint archived to archive/checkpoint-$TIMESTAMP.md"
  fi

  # Enforce max archives
  MAX_ARCHIVES=$(grep "max_archives:" "$CONFIG_FILE" | awk '{print $2}')
  MAX_ARCHIVES=${MAX_ARCHIVES:-10}
  ARCHIVE_COUNT=$(ls -1 "$ARCHIVE_DIR"/checkpoint-*.md 2>/dev/null | wc -l)
  if [ "$ARCHIVE_COUNT" -gt "$MAX_ARCHIVES" ]; then
    ls -t "$ARCHIVE_DIR"/checkpoint-*.md | tail -n +$((MAX_ARCHIVES + 1)) | xargs rm -f 2>/dev/null
    if [ "$AUTO_MODE" = false ]; then
      echo "Old archives pruned (keeping last $MAX_ARCHIVES)"
    fi
  fi
fi

# --- Generate file tree hash ---

HASH=$(find . -type f -not -path '*/.git/*' -not -path '*/node_modules/*' -not -path '*/dist/*' -not -path '*/coverage/*' -not -path '*/checkpoints/CURRENT_STATE.md' -not -path '*/checkpoints/archive/*' 2>/dev/null | sort | xargs md5sum 2>/dev/null | md5sum | awk '{print $1}')

if [ -z "$HASH" ]; then
  HASH=$(find . -type f -not -path '*/.git/*' -not -path '*/node_modules/*' -not -path '*/dist/*' -not -path '*/coverage/*' -not -path '*/checkpoints/CURRENT_STATE.md' -not -path '*/checkpoints/archive/*' 2>/dev/null | sort | xargs sha256sum 2>/dev/null | sha256sum | awk '{print $1}')
fi

# --- Get files modified ---

FILES_MODIFIED=$(git diff --name-only HEAD 2>/dev/null || echo "Not a git repo or no changes")
FILES_COUNT=$(echo "$FILES_MODIFIED" | grep -c '.' 2>/dev/null || echo "0")

# --- Write checkpoint ---

if [ "$ADVANCE_STAGE" = true ] && [ -n "$NEW_LOOP" ]; then
  # Auto-advancement checkpoint with populated loop/stage info
  if [ "$LOOP_COMPLETED" = true ]; then
    cat > "$CURRENT_STATE" << EOF
# RALPH Checkpoint

**Generated:** $(date -Iseconds 2>/dev/null || date)
**Loop:** $NEW_LOOP
**Stage:** COMPLETED ($NEW_TOTAL/$NEW_TOTAL)
**File Tree Hash:** $HASH

## Status

LOOP COMPLETED

## Completed Work

$PREV_COMPLETED_WORK
- [x] $MARKER_COMPLETED_STAGE: Completed (final stage)

## Next Objectives

Loop "$NEW_LOOP" is complete. Start a new loop or end RALPH session.

## Files Modified

$FILES_MODIFIED

## Notes

Loop completed at $(date -Iseconds 2>/dev/null || date).
Consider archiving this checkpoint and starting fresh.

---
*Loop complete. Start new loop with /ralph-checkpoint or review with /ralph-status.*
EOF
  else
    cat > "$CURRENT_STATE" << EOF
# RALPH Checkpoint

**Generated:** $(date -Iseconds 2>/dev/null || date)
**Loop:** $NEW_LOOP
**Stage:** $NEW_STAGE ($NEW_STAGE_NUM/$NEW_TOTAL)
**File Tree Hash:** $HASH

## Completed Work

$PREV_COMPLETED_WORK
- [x] $MARKER_COMPLETED_STAGE: Completed

## Next Objectives
$NEXT_OBJECTIVES_TEXT

## Files Modified

$FILES_MODIFIED

## Notes

Auto-advanced from $MARKER_COMPLETED_STAGE to $NEW_STAGE.

---
*Resume with: /ralph-resume*
EOF
  fi
else
  # Standard manual checkpoint skeleton
  cat > "$CURRENT_STATE" << EOF
# RALPH Checkpoint

**Generated:** $(date -Iseconds 2>/dev/null || date)
**File Tree Hash:** $HASH

## Status

Loop: [Set loop name]
Stage: [Set current stage]

## Completed Work

[Summary of completed work]

## Next Objectives

- [ ] [Objective 1]
- [ ] [Objective 2]

## Files Modified

$FILES_MODIFIED

## Notes

[Any notes or blockers]

---
*Resume with: /ralph-resume*
EOF
fi

# --- Output ---

if [ "$AUTO_MODE" = true ]; then
  # Concise output for hook-triggered runs
  if [ "$LOOP_COMPLETED" = true ]; then
    echo ""
    echo "RALPH: Loop '$NEW_LOOP' COMPLETED"
    echo "  All $NEW_TOTAL stages done. Checkpoint archived."
    echo "  Start a new loop or review with /ralph-status"
    echo ""
  elif [ "$ADVANCE_STAGE" = true ] && [ -n "$NEW_STAGE" ]; then
    echo ""
    echo "RALPH: Advanced to $NEW_STAGE ($NEW_STAGE_NUM/$NEW_TOTAL)"
    echo "  Checkpoint saved. Objectives:"
    echo "$NEXT_OBJECTIVES_TEXT"
    echo ""
  else
    echo ""
    echo "RALPH: Checkpoint created"
    echo "  File tree hash: $HASH"
    echo ""
  fi
else
  # Verbose output for manual runs
  echo ""
  echo "Checkpoint created at $CURRENT_STATE"
  echo "  Files tracked: $FILES_COUNT"
  echo "  File tree hash: $HASH"
  if [ "$ADVANCE_STAGE" = true ] && [ -n "$NEW_STAGE" ]; then
    echo "  Advanced to: $NEW_STAGE ($NEW_STAGE_NUM/$NEW_TOTAL)"
  fi
  echo ""
  if [ "$ADVANCE_STAGE" != true ]; then
    echo "Edit $CURRENT_STATE to fill in loop/stage details,"
    echo "or use /ralph-checkpoint command for interactive creation."
  fi
fi
