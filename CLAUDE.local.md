# CLAUDE.local.md — Personal Overrides

> **This file is gitignored.** It's for YOUR personal preferences — things that shouldn't be shared with the team.
>
> **When to use this vs CLAUDE.md:**
> - `CLAUDE.md` = team rules (checked into git, everyone follows them)
> - `CLAUDE.local.md` = personal preferences (gitignored, only affects you)

---

## My Identity

- GitHub: YourUsername
- SSH: `git@github.com:YourUsername/<repo>.git`

## Communication Style

<!-- Uncomment the style that fits you: -->
<!-- - Respond concisely — I prefer terse explanations -->
<!-- - Be thorough — explain your reasoning in detail -->
<!-- - Show me the code first, explain after -->
<!-- - Always explain trade-offs before making a choice -->

## Commit Preferences

- When creating commits, use conventional commit format (feat:, fix:, docs:, etc.)
<!-- - Always include a scope: feat(auth):, fix(db):, docs(readme): -->
<!-- - Keep commit messages under 50 characters -->

## Testing Preferences

<!-- Uncomment what matches your workflow: -->
<!-- - Run tests after every code change automatically -->
<!-- - Only run tests when I ask -->
<!-- - Always run E2E tests headed so I can watch -->
<!-- - Prefer unit tests over E2E for new features -->

## Deployment Preferences

<!-- Uncomment what matches your workflow: -->
<!-- - Always ask before deploying (default CLAUDE.md behavior) -->
<!-- - Deploy to staging automatically, ask before production -->
<!-- - I handle deployments myself — just build and test -->

## Code Style

<!-- Uncomment what matches your preferences: -->
<!-- - I prefer named exports over default exports -->
<!-- - Use arrow functions for React components -->
<!-- - Prefer early returns over nested if/else -->
<!-- - Use verbose variable names, never abbreviate -->

## Personal Workflows

<!-- Define shortcuts for things you do often: -->
<!-- When I say "quick deploy", I mean: build, test locally, push to staging -->
<!-- When I say "full review", I mean: /review, /security-check, then /commit -->
<!-- When I say "fresh start", I mean: /clear and state the new task -->

## Local Environment

- Node version: 20.x
- Package manager: pnpm
- OS: (your OS here)

## Project-Specific Notes

<!-- Add anything specific to how YOU work on this project: -->
<!-- - I'm the only one working on the auth module -->
<!-- - The /api/v1/billing endpoint is still in development -->
<!-- - Don't touch the migration scripts — they run in CI -->
