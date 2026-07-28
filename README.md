# skills

Portable [Agent Skills](https://github.com/vercel-labs/skills) shared across AI
coding agents (Claude Code, Codex, and others).

Each skill is a self-contained `skills/<name>/SKILL.md`. The skills here are
agent-agnostic — they avoid tool- or vendor-specific primitives so they work
across agents. (Agent-specific skills, e.g. ones that rely on Claude Code
subagents, live elsewhere and are intentionally not published here.)

## Skills

- **agent-task** — Create a GitHub issue formatted for an AI coding agent.
- **harness** — Set up a project's dev tooling (gitignore, lint/format config,
  task runner, CI, hooks, tests) for whatever language the project uses.
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
