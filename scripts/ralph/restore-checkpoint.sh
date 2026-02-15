#!/bin/bash
# Helper: Restore and display checkpoint for review
set -e

CHECKPOINT_DIR="project-docs/checkpoints"
CURRENT_STATE="$CHECKPOINT_DIR/CURRENT_STATE.md"
ARCHIVE_DIR="$CHECKPOINT_DIR/archive"

# Check for argument — restore from archive
if [ -n "$1" ]; then
  ARCHIVE_FILE="$ARCHIVE_DIR/$1"
  if [ ! -f "$ARCHIVE_FILE" ]; then
    echo "Archive not found: $ARCHIVE_FILE"
    echo ""
    echo "Available archives:"
    ls -1t "$ARCHIVE_DIR"/checkpoint-*.md 2>/dev/null || echo "  (none)"
    exit 1
  fi

  # Back up current checkpoint before restoring
  if [ -f "$CURRENT_STATE" ]; then
    TIMESTAMP=$(date +%Y-%m-%d-%H%M%S)
    cp "$CURRENT_STATE" "$ARCHIVE_DIR/checkpoint-$TIMESTAMP.md"
    echo "Current checkpoint backed up to archive/checkpoint-$TIMESTAMP.md"
  fi

  cp "$ARCHIVE_FILE" "$CURRENT_STATE"
  echo "Restored from: $1"
  echo ""
fi

# Check current checkpoint exists
if [ ! -f "$CURRENT_STATE" ]; then
  echo "No checkpoint to restore from."
  echo ""
  echo "Available archives:"
  ls -1t "$ARCHIVE_DIR"/checkpoint-*.md 2>/dev/null || echo "  (none)"
  echo ""
  echo "Usage:"
  echo "  ./scripts/ralph/restore-checkpoint.sh                    # Show current checkpoint"
  echo "  ./scripts/ralph/restore-checkpoint.sh checkpoint-FILE.md # Restore from archive"
  exit 1
fi

# Validate first
echo "Running validation..."
bash scripts/ralph/validate-checkpoint.sh 2>/dev/null || echo "Warning: Validation returned warnings (see above)"
echo ""
echo "═══════════════════════════════════════"
echo "CHECKPOINT CONTENTS"
echo "═══════════════════════════════════════"
echo ""

cat "$CURRENT_STATE"

echo ""
echo "═══════════════════════════════════════"
echo "Checkpoint loaded. Review above and continue work."
echo "Use /ralph-resume in Claude to resume interactively."
