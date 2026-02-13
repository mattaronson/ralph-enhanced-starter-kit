---
description: Generate a structured test plan for a feature
argument-hint: <feature-name>
---

# Test Plan Generator

Create a structured test plan for: **$ARGUMENTS**

## Branch Safety Check

Before creating test plan files, check the current branch:

```bash
git branch --show-current
```

- If on `main` or `master`: **STOP.** Warn the user and suggest:
  - `/worktree test-<feature>` — creates isolated branch + directory (recommended)
  - `git checkout -b test/<feature>` — creates a branch in the current directory
- If on a feature branch: proceed
- If not a git repo: proceed (skip this check)

## Template

Generate the following markdown document:

```markdown
# [Feature] Test Plan

**Created:** [today's date]
**Feature:** $ARGUMENTS
**Status:** ⬜ Not Started

---

## Quick Status

Feature Area A:    ⬜ NOT TESTED
Feature Area B:    ⬜ NOT TESTED
Feature Area C:    ⬜ NOT TESTED

---

## Prerequisites

- [ ] Required services running
- [ ] Test data created
- [ ] Environment variables set

---

## Test 1: [Happy Path]

### 1.1 [Core scenario]

**Action:** [What to do]
**Expected:** [What should happen — be SPECIFIC]

| Check | Expected | Actual | Status |
|-------|----------|--------|--------|
| Response code | 200 | | ⬜ |
| Data returned | [specific shape] | | ⬜ |
| UI updated | [specific change] | | ⬜ |

---

## Test 2: [Error Cases]

### 2.1 [Invalid input]

**Action:** [What to do]
**Expected:** [Specific error message/behavior]

---

## Test 3: [Edge Cases]

### 3.1 [Empty state]
### 3.2 [Maximum values]
### 3.3 [Concurrent access]

---

## Pass/Fail Criteria

| Criteria | Pass | Fail |
|----------|------|------|
| All happy paths work | Yes | Any failure |
| Error messages shown | Yes | Silent failure |
| Data persists | Yes | Lost on refresh |

---

## Sign-Off

| Test | Tester | Date | Status |
|------|--------|------|--------|
| Test 1 | | | ⬜ |
| Test 2 | | | ⬜ |
| Test 3 | | | ⬜ |
```

Save to `tests/plans/[feature-name]-test-plan.md`

## RuleCatch Report

After saving the test plan, check RuleCatch:

- If the RuleCatch MCP server is available: query for violations related to testing in the project
- Report any violations found (missing test coverage, untested features, etc.)
- If no MCP: suggest checking the RuleCatch dashboard
