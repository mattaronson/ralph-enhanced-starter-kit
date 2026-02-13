---
description: Smart commit with context — generates conventional commit message
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*), Bash(git diff:*)
argument-hint: [optional commit message override]
---

# Smart Commit

## Context
- Current git status: !`git status --short`
- Current diff: !`git diff HEAD --stat`
- Current branch: !`git branch --show-current`
- Recent commits: !`git log --oneline -5`

## Branch Safety Check

Before committing, verify you are NOT on main/master:

```bash
git branch --show-current
```

- If on `main` or `master`: **STOP.** Warn the user:
  - "You are committing directly to main. Create a feature branch first."
  - Suggest: `/worktree <task-name>` or `git checkout -b <branch-name>`
  - Only proceed if the user explicitly confirms they want to commit to main
- If on a feature branch: proceed normally

## Task

Review the staged changes and create a commit.

### Rules
1. Use **conventional commit** format: `type(scope): description`
   - Types: feat, fix, docs, style, refactor, test, chore, perf
2. Description should be concise but descriptive (max 72 chars)
3. If changes span multiple concerns, suggest splitting into multiple commits
4. NEVER commit .env files or secrets
5. Verify .gitignore includes .env before committing

### If message provided
Use this as the commit message: $ARGUMENTS

### If no message provided
Generate an appropriate commit message based on the diff.

### RuleCatch Report (post-commit)

After the commit succeeds, check RuleCatch for violations in the committed files:

- If the RuleCatch MCP server is available: query for violations on the files in this commit
- Report: "RuleCatch: X violations found in committed files" (with details if any)
- If no MCP available: remind the user — "Check your RuleCatch dashboard for violations in this commit"
- If violations are found: DO NOT undo the commit, just report them so the user can decide
