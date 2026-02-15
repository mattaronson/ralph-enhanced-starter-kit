#!/bin/bash
# PostToolUse: Auto-checkpoint when thresholds reached
# Suggests creating a checkpoint when lines changed exceeds threshold

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
