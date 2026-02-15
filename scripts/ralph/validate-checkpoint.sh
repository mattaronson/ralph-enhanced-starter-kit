#!/bin/bash
# Helper: Validate checkpoint integrity
set -e

CHECKPOINT_DIR="project-docs/checkpoints"
CURRENT_STATE="$CHECKPOINT_DIR/CURRENT_STATE.md"

if [ ! -f "$CURRENT_STATE" ]; then
  echo "No checkpoint found at $CURRENT_STATE"
  exit 1
fi

echo "Validating checkpoint..."
echo ""

# Check checkpoint is non-empty
if [ ! -s "$CURRENT_STATE" ]; then
  echo "FAIL: Checkpoint file is empty"
  exit 1
fi

# Extract stored hash
STORED_HASH=$(grep "File Tree Hash:" "$CURRENT_STATE" | awk '{print $4}')

if [ -z "$STORED_HASH" ]; then
  echo "Warning: No file tree hash found in checkpoint"
  echo "  Checkpoint may have been created manually"
  exit 1
fi

# Generate current hash (hashes each file's content, then hashes the combined result)
# Excludes checkpoint files to avoid chicken-and-egg hash invalidation
CURRENT_HASH=$(find . -type f -not -path '*/.git/*' -not -path '*/node_modules/*' -not -path '*/dist/*' -not -path '*/coverage/*' -not -path '*/checkpoints/CURRENT_STATE.md' -not -path '*/checkpoints/archive/*' 2>/dev/null | sort | xargs md5sum 2>/dev/null | md5sum | awk '{print $1}')

# Fallback to sha256sum if md5sum not available
if [ -z "$CURRENT_HASH" ]; then
  CURRENT_HASH=$(find . -type f -not -path '*/.git/*' -not -path '*/node_modules/*' -not -path '*/dist/*' -not -path '*/coverage/*' -not -path '*/checkpoints/CURRENT_STATE.md' -not -path '*/checkpoints/archive/*' 2>/dev/null | sort | xargs sha256sum 2>/dev/null | sha256sum | awk '{print $1}')
fi

# Check for required sections
echo "Checking checkpoint structure..."
MISSING_SECTIONS=""

grep -q "## Status" "$CURRENT_STATE" || MISSING_SECTIONS="$MISSING_SECTIONS Status"
grep -q "## Completed Work" "$CURRENT_STATE" || MISSING_SECTIONS="$MISSING_SECTIONS CompletedWork"
grep -q "## Next Objectives\|## Next Stage" "$CURRENT_STATE" || MISSING_SECTIONS="$MISSING_SECTIONS NextObjectives"

if [ -n "$MISSING_SECTIONS" ]; then
  echo "Warning: Missing sections:$MISSING_SECTIONS"
fi

# Compare hashes
if [ "$STORED_HASH" = "$CURRENT_HASH" ]; then
  echo "Checkpoint valid — file tree matches"
  exit 0
else
  echo "Warning: File tree has changed since checkpoint"
  echo "  Stored:  $STORED_HASH"
  echo "  Current: $CURRENT_HASH"
  echo ""
  echo "Files changed since checkpoint:"
  git status --short 2>/dev/null || echo "  (not a git repo — cannot show diff)"
  exit 1
fi
