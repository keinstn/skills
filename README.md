# skills

Portable [Agent Skills](https://github.com/vercel-labs/skills) shared across AI
coding agents (Claude Code, Codex, and others).

Each skill is a self-contained `skills/<name>/SKILL.md`. The skills here are
agent-agnostic — they avoid tool- or vendor-specific primitives so they work
across agents. (Agent-specific skills, e.g. ones that rely on Claude Code
subagents, live elsewhere and are intentionally not published here.)

## Skills

- **advise-herdr** — Delegate a plan or decision to a new agent in a separate
  Herdr pane, for an independent second opinion from a different provider
  before implementing.
- **agent-task** — Create a GitHub issue formatted for an AI coding agent.
- **flutter-ios-screenshots** — Capture App Store screenshots of a Flutter app
  on an iOS simulator at the size App Store Connect requires, with a clean
  status bar and no debug artifacts.
- **git-retro** — Turn a period of GitHub activity into a personal
  development retrospective, combining a data digest with follow-up
  questions to surface context the data alone can't.
- **harness** — Set up a project's dev tooling (gitignore, lint/format config,
  task runner, CI, hooks, tests) for whatever language the project uses.
- **lead** — Act as lead/orchestrator: decompose work into contracts, delegate
  implementation to subagents, and review.
- **review-herdr** — Delegate code review to a new agent in a separate Herdr
  pane, for an independent second opinion from a different provider.
- **ship** — Implement in a worktree, verify locally, then commit/push/PR and
  review the diff.
- **ship-herdr** — Delegate the `ship` workflow to a new agent in a separate
  Herdr pane, for a different provider (e.g. codex) or a live-steerable pane.
- **worktree** — Create a git worktree adjacent to the current repo before
  starting implementation.

## Install

Uses the [`skills`](https://github.com/vercel-labs/skills) CLI via `npx`.

Install everything, to every detected agent:

```sh
npx skills add keinstn/skills -s '*' -a '*' -g -y
```

Install a single skill:

```sh
npx skills add keinstn/skills -s worktree -a claude-code -g -y
```

Install a subset to specific agents:

```sh
npx skills add keinstn/skills -s agent-task,harness -a claude-code -a codex -g -y
```

- `-g` installs globally (user-level); drop it to install into the current
  project instead.
- `-a` selects agents (`claude-code`, `codex`, …; `'*'` for all detected).
- `-s` selects skills (`'*'` for all).

## Updating

```sh
npx skills update -g
```

## Local development

Try a skill straight from a local checkout, without installing:

```sh
npx skills use ~/Projects/skills@worktree --agent claude-code
```

Typical loop — iterate against the local checkout, then publish:

```sh
# edit skills/<name>/SKILL.md
npx skills use ~/Projects/skills@<name> --agent claude-code   # trial, live from disk
git push                                                      # publish
npx skills update -g                                          # refresh installed copies
```
