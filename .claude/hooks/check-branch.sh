#!/usr/bin/env bash
# Branch Protection Hook — PreToolUse (Bash)
# Blocks committing directly to main/master when auto_branch is enabled.
# Exit code 2 = block operation and tell Claude why.
#
# Based on Claude Code Mastery Guides V1-V5 by TheDecipherist

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))" 2>/dev/null)

if [ -z "$COMMAND" ]; then
    exit 0
fi

# Only check git commit commands
if ! echo "$COMMAND" | grep -qE 'git\s+commit'; then
    exit 0
fi

# Must be in a git repo
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    exit 0
fi

BRANCH=$(git branch --show-current 2>/dev/null)

# Only care about main/master
if [ "$BRANCH" != "main" ] && [ "$BRANCH" != "master" ]; then
    exit 0
fi

# Check auto_branch setting (default: true)
AUTO_BRANCH="true"
CONF="claude-mastery-project.conf"
if [ -f "$CONF" ]; then
    SETTING=$(grep -E '^\s*auto_branch\s*=' "$CONF" 2>/dev/null | head -1 | sed 's/.*=\s*//' | sed 's/\s*#.*//' | tr -d ' ')
    if [ -n "$SETTING" ]; then
        AUTO_BRANCH="$SETTING"
    fi
fi

if [ "$AUTO_BRANCH" = "true" ]; then
    echo "BLOCKED: You're committing directly to '$BRANCH' with auto_branch enabled." >&2
    echo "Create a feature branch first:" >&2
    echo "  git checkout -b feat/<feature-name>" >&2
    echo "  Or use: /worktree <name>" >&2
    exit 2
fi

# auto_branch is explicitly false — user chose to work on main
exit 0
