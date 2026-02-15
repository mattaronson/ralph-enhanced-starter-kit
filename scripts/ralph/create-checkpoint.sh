#!/bin/bash
# Helper: Create checkpoint manually (used by /ralph-checkpoint command)
set -e

CONFIG_FILE=".claude/ralph/config.yml"
CHECKPOINT_DIR="project-docs/checkpoints"
CURRENT_STATE="$CHECKPOINT_DIR/CURRENT_STATE.md"
ARCHIVE_DIR="$CHECKPOINT_DIR/archive"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "Error: RALPH not configured. Run setup first."
  echo "Copy .claude/ralph/config.yml.example to .claude/ralph/config.yml"
  exit 1
fi

# Ensure directories exist
mkdir -p "$CHECKPOINT_DIR"
mkdir -p "$ARCHIVE_DIR"

# Archive previous checkpoint if exists
if [ -f "$CURRENT_STATE" ]; then
  TIMESTAMP=$(date +%Y-%m-%d-%H%M%S)
  cp "$CURRENT_STATE" "$ARCHIVE_DIR/checkpoint-$TIMESTAMP.md"
  echo "Previous checkpoint archived to archive/checkpoint-$TIMESTAMP.md"

  # Enforce max archives
  MAX_ARCHIVES=$(grep "max_archives:" "$CONFIG_FILE" | awk '{print $2}')
  MAX_ARCHIVES=${MAX_ARCHIVES:-10}
  ARCHIVE_COUNT=$(ls -1 "$ARCHIVE_DIR"/checkpoint-*.md 2>/dev/null | wc -l)
  if [ "$ARCHIVE_COUNT" -gt "$MAX_ARCHIVES" ]; then
    ls -t "$ARCHIVE_DIR"/checkpoint-*.md | tail -n +$((MAX_ARCHIVES + 1)) | xargs rm -f 2>/dev/null
    echo "Old archives pruned (keeping last $MAX_ARCHIVES)"
  fi
fi

# Generate file tree hash (hashes each file's content, then hashes the combined result)
# Excludes checkpoint files to avoid chicken-and-egg hash invalidation
HASH=$(find . -type f -not -path '*/.git/*' -not -path '*/node_modules/*' -not -path '*/dist/*' -not -path '*/coverage/*' -not -path '*/checkpoints/CURRENT_STATE.md' -not -path '*/checkpoints/archive/*' 2>/dev/null | sort | xargs md5sum 2>/dev/null | md5sum | awk '{print $1}')

# Fallback to sha256sum if md5sum not available
if [ -z "$HASH" ]; then
  HASH=$(find . -type f -not -path '*/.git/*' -not -path '*/node_modules/*' -not -path '*/dist/*' -not -path '*/coverage/*' -not -path '*/checkpoints/CURRENT_STATE.md' -not -path '*/checkpoints/archive/*' 2>/dev/null | sort | xargs sha256sum 2>/dev/null | sha256sum | awk '{print $1}')
fi

# Get files modified
FILES_MODIFIED=$(git diff --name-only HEAD 2>/dev/null || echo "Not a git repo or no changes")
FILES_COUNT=$(echo "$FILES_MODIFIED" | grep -c '.' 2>/dev/null || echo "0")

# Create checkpoint skeleton
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

echo ""
echo "Checkpoint created at $CURRENT_STATE"
echo "  Files tracked: $FILES_COUNT"
echo "  File tree hash: $HASH"
echo ""
echo "Edit $CURRENT_STATE to fill in loop/stage details,"
echo "or use /ralph-checkpoint command for interactive creation."
