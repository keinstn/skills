---
name: ship
description: Implement in a worktree, verify locally, then commit/push/PR and review the diff. Use when asked to ship/deliver a change end-to-end (e.g. "ship して", "実装してPRまで作って").
---

# Ship

Deliver a change end-to-end using whatever tooling the project actually has —
don't assume a specific runner (`just`, `make`, `npm`, `uv`, etc.). Discover it
from the project's own docs/config (AGENTS.md, CLAUDE.md, README, justfile,
Makefile, package.json, ...) before running anything.

1. Start in an isolated git worktree (skip if already in one). Use the
   `worktree` skill if your host has it; otherwise create one directly:
   `git worktree add ../<repo>-<branch-slug> -b <type>/<short-description>`.
2. Implement the change.
3. Run the project's lint and full test suite; fix failures until green.
4. Review the working-tree diff and fix findings — before committing, so the PR
   history doesn't carry separate "address review" fix-up commits. Use the
   strongest review mechanism your host offers:
   - Claude Code → `/code-review`
   - Codex → `codex exec review`
   - otherwise → review the diff yourself against the change's intent
     (correctness, scope creep, leftover debug code, missing tests).
5. Commit using [Conventional Commits](https://www.conventionalcommits.org/),
   push, and open a PR. Write commit messages, PR title/body, and any linked
   issue text in English.

## When NOT to use this

- Investigation-only requests — a diagnosis request isn't approval to create a
  worktree, branch, or PR; explain findings first and let the user confirm they
  want implementation.
