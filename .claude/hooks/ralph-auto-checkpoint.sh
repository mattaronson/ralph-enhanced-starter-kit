#!/bin/bash
# PostToolUse: Auto-checkpoint when thresholds reached or stage completed
# 1. Detects .ralph-stage-complete marker → auto-checkpoint + advance stage
# 2. Suggests checkpoint when lines changed exceeds threshold

MARKER_FILE=".ralph-stage-complete"

# --- Stage completion detection (runs even if auto-checkpoint is disabled) ---

if [ -f "$MARKER_FILE" ]; then
  echo ""
  echo "RALPH: Stage marked complete — creating checkpoint and advancing..."
  echo ""

  # Run checkpoint with auto + advance flags
  bash scripts/ralph/create-checkpoint.sh --auto --advance-stage 2>&1

  # Remove marker
  rm -f "$MARKER_FILE"

  # Exit early — no need to also check lines threshold
  exit 0
fi

# --- Lines-changed threshold check ---

# Only run if RALPH is enabled
if [ ! -f ".claude/ralph/config.yml" ]; then
  exit 0
fi

# Check if auto-checkpoint is enabled
AUTO_ENABLED=$(grep -A 1 "auto_checkpoint:" .claude/ralph/config.yml | grep "enabled: true")
if [ -z "$AUTO_ENABLED" ]; then
  exit 0
fi

# Get threshold from config
THRESHOLD=$(grep "lines_changed:" .claude/ralph/config.yml | awk '{print $2}')
THRESHOLD=${THRESHOLD:-500}

# Count lines changed (staged + unstaged)
LINES_CHANGED=$(git diff --stat 2>/dev/null | tail -1 | awk '{print $4+$6}')
STAGED_CHANGED=$(git diff --cached --stat 2>/dev/null | tail -1 | awk '{print $4+$6}')

if [ -z "$LINES_CHANGED" ]; then
  LINES_CHANGED=0
fi
if [ -z "$STAGED_CHANGED" ]; then
  STAGED_CHANGED=0
fi

TOTAL_CHANGED=$((LINES_CHANGED + STAGED_CHANGED))

# Trigger checkpoint suggestion if threshold exceeded
if [ "$TOTAL_CHANGED" -ge "$THRESHOLD" ]; then
  echo ""
  echo "RALPH Auto-Checkpoint Trigger"
  echo "   $TOTAL_CHANGED lines changed (threshold: $THRESHOLD)"
  echo "   Consider running: /ralph-checkpoint"
  echo ""
fi

exit 0
