#!/bin/bash
# Mark current RALPH stage as complete and trigger auto-advancement
set -e

CHECKPOINT_DIR="project-docs/checkpoints"
CURRENT_STATE="$CHECKPOINT_DIR/CURRENT_STATE.md"
CONFIG_FILE=".claude/ralph/config.yml"
MARKER_FILE=".ralph-stage-complete"

# --- Validate prerequisites ---

if [ ! -f "$CONFIG_FILE" ]; then
  echo "Error: RALPH not configured."
  echo "Copy .claude/ralph/config.yml.example to .claude/ralph/config.yml"
  exit 1
fi

if [ ! -f "$CURRENT_STATE" ]; then
  echo "Error: No active RALPH checkpoint."
  echo "Create one with /ralph-checkpoint or: bash scripts/ralph/create-checkpoint.sh"
  exit 1
fi

# --- Extract current state ---

# Read loop name — supports both formats:
#   Loop: feature-development
#   **Loop:** feature-development
CURRENT_LOOP=$(grep -E "^\*?\*?Loop:?\*?\*?" "$CURRENT_STATE" | head -1 | sed 's/.*Loop[*:]*[[:space:]]*//')
CURRENT_LOOP=$(echo "$CURRENT_LOOP" | xargs)  # trim whitespace

# Read stage name — supports both formats:
#   Stage: implement (2/4)
#   **Stage:** implement (2/4)
STAGE_LINE=$(grep -E "^\*?\*?Stage:?\*?\*?" "$CURRENT_STATE" | head -1)
CURRENT_STAGE=$(echo "$STAGE_LINE" | sed 's/.*Stage[*:]*[[:space:]]*//' | awk '{print $1}')
STAGE_NUM=$(echo "$STAGE_LINE" | sed -n 's/.*(\([0-9]*\)\/[0-9]*).*/\1/p')
TOTAL_STAGES=$(echo "$STAGE_LINE" | sed -n 's/.*([0-9]*\/\([0-9]*\)).*/\1/p')

if [ -z "$CURRENT_LOOP" ] || [ -z "$CURRENT_STAGE" ]; then
  echo "Error: Cannot read loop/stage from checkpoint."
  echo "Checkpoint may need loop and stage filled in."
  echo "  Current loop:  '${CURRENT_LOOP:-<empty>}'"
  echo "  Current stage: '${CURRENT_STAGE:-<empty>}'"
  exit 1
fi

# --- Look up stage info from config ---

# Get all stage names for this loop from config
STAGE_NAMES=()
IN_LOOP=false
IN_STAGES=false
while IFS= read -r line; do
  if echo "$line" | grep -q "name: \"$CURRENT_LOOP\""; then
    IN_LOOP=true
    continue
  fi
  if [ "$IN_LOOP" = true ] && echo "$line" | grep -q "stages:"; then
    IN_STAGES=true
    continue
  fi
  if [ "$IN_LOOP" = true ] && [ "$IN_STAGES" = true ]; then
    # Exit when we hit checkpoint_after_stage or a new loop
    if echo "$line" | grep -qE "checkpoint_after_stage:|^  - name:"; then
      break
    fi
    # Capture stage names (indented under stages)
    STAGE_NAME=$(echo "$line" | grep '      - name:' | sed 's/.*name: "\(.*\)"/\1/')
    if [ -n "$STAGE_NAME" ]; then
      STAGE_NAMES+=("$STAGE_NAME")
    fi
  fi
done < "$CONFIG_FILE"

TOTAL=${#STAGE_NAMES[@]}

if [ "$TOTAL" -eq 0 ]; then
  echo "Error: Could not find stages for loop '$CURRENT_LOOP' in config."
  echo "Check .claude/ralph/config.yml"
  exit 1
fi

# Find current stage index (0-based)
CURRENT_INDEX=-1
for i in "${!STAGE_NAMES[@]}"; do
  if [ "${STAGE_NAMES[$i]}" = "$CURRENT_STAGE" ]; then
    CURRENT_INDEX=$i
    break
  fi
done

if [ "$CURRENT_INDEX" -eq -1 ]; then
  echo "Error: Stage '$CURRENT_STAGE' not found in loop '$CURRENT_LOOP'."
  echo "Available stages: ${STAGE_NAMES[*]}"
  exit 1
fi

STAGE_DISPLAY="$((CURRENT_INDEX + 1))/$TOTAL"
IS_FINAL=false
if [ "$((CURRENT_INDEX + 1))" -eq "$TOTAL" ]; then
  IS_FINAL=true
fi

# --- Get next stage info ---

if [ "$IS_FINAL" = false ]; then
  NEXT_INDEX=$((CURRENT_INDEX + 1))
  NEXT_STAGE="${STAGE_NAMES[$NEXT_INDEX]}"
  NEXT_DISPLAY="$((NEXT_INDEX + 1))/$TOTAL"

  # Get next stage objectives from config
  # Handles both inline: objectives: ["A", "B"] and multi-line formats
  NEXT_OBJECTIVES=()
  OBJ_LINE=$(grep -A 1 "name: \"$NEXT_STAGE\"" "$CONFIG_FILE" | grep "objectives:")

  if echo "$OBJ_LINE" | grep -q '\['; then
    # Inline array format
    OBJS=$(echo "$OBJ_LINE" | sed 's/.*\[//;s/\].*//' | tr ',' '\n')
    while IFS= read -r item; do
      item=$(echo "$item" | sed 's/^ *//;s/ *$//;s/^"//;s/"$//')
      if [ -n "$item" ]; then
        NEXT_OBJECTIVES+=("$item")
      fi
    done <<< "$OBJS"
  else
    # Multi-line format
    IN_NEXT_STAGE=false
    IN_OBJECTIVES=false
    while IFS= read -r line; do
      if echo "$line" | grep -q "name: \"$NEXT_STAGE\""; then
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
          NEXT_OBJECTIVES+=("$OBJ")
        else
          break
        fi
      fi
    done < "$CONFIG_FILE"
  fi
fi

# --- Display and confirm ---

echo ""
echo "RALPH Stage Completion"
echo ""
echo "  Loop:  $CURRENT_LOOP"
echo "  Stage: $CURRENT_STAGE ($STAGE_DISPLAY)"
echo ""

if [ "$IS_FINAL" = true ]; then
  echo "  This is the FINAL stage of the loop."
  echo "  Completing will mark the entire loop as DONE."
else
  echo "  Next stage: $NEXT_STAGE ($NEXT_DISPLAY)"
  if [ ${#NEXT_OBJECTIVES[@]} -gt 0 ]; then
    echo "  Next objectives:"
    for obj in "${NEXT_OBJECTIVES[@]}"; do
      echo "    - $obj"
    done
  fi
fi

echo ""

# If --yes flag passed, skip confirmation (used by auto-advancement)
if [ "$1" = "--yes" ]; then
  CONFIRM="y"
else
  read -p "Mark stage '$CURRENT_STAGE' as complete? (y/n): " CONFIRM
fi

if [ "$CONFIRM" = "y" ] || [ "$CONFIRM" = "Y" ]; then
  # Write marker file with metadata for the hook to use
  cat > "$MARKER_FILE" << MARKER_EOF
loop=$CURRENT_LOOP
completed_stage=$CURRENT_STAGE
completed_stage_index=$CURRENT_INDEX
total_stages=$TOTAL
is_final=$IS_FINAL
MARKER_EOF

  if [ "$IS_FINAL" = true ]; then
    echo "COMPLETED" >> "$MARKER_FILE"
  fi

  echo ""
  echo "Stage '$CURRENT_STAGE' marked complete."

  if [ "$IS_FINAL" = true ]; then
    echo "  Loop '$CURRENT_LOOP' will be marked COMPLETED on next action."
  else
    echo "  Will advance to: $NEXT_STAGE ($NEXT_DISPLAY)"
  fi

  echo "  Auto-checkpoint will trigger on next tool use."
else
  echo "Cancelled."
fi
