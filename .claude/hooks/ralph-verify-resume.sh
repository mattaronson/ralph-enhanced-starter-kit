#!/bin/bash
# PreToolUse: Verify checkpoint integrity when resuming
# Warns if file tree has changed since last checkpoint

# Only check if a checkpoint exists
if [ ! -f "project-docs/checkpoints/CURRENT_STATE.md" ]; then
  exit 0
fi

# Extract stored hash from checkpoint
STORED_HASH=$(grep "File Tree Hash:" project-docs/checkpoints/CURRENT_STATE.md | awk '{print $4}')

if [ -z "$STORED_HASH" ]; then
  exit 0
fi

# Generate current hash (exclude .git, node_modules, dist, coverage)
CURRENT_HASH=$(find . -type f -not -path '*/.git/*' -not -path '*/node_modules/*' -not -path '*/dist/*' -not -path '*/coverage/*' 2>/dev/null | sort | md5sum 2>/dev/null | awk '{print $1}')

# Fallback to sha256sum if md5sum not available
if [ -z "$CURRENT_HASH" ]; then
  CURRENT_HASH=$(find . -type f -not -path '*/.git/*' -not -path '*/node_modules/*' -not -path '*/dist/*' -not -path '*/coverage/*' 2>/dev/null | sort | sha256sum 2>/dev/null | awk '{print $1}')
fi

# Compare
if [ -n "$CURRENT_HASH" ] && [ "$STORED_HASH" != "$CURRENT_HASH" ]; then
  echo ""
  echo "RALPH Resume Warning"
  echo "   File tree has changed since last checkpoint"
  echo "   Review changes before proceeding"
  echo ""
fi

exit 0
