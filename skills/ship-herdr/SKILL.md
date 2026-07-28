---
name: ship-herdr
description: Delegate the ship workflow to a new agent in a separate Herdr pane — use to ship with a different provider (e.g. codex) or to keep the work visible/steerable in its own pane. Requires running inside a Herdr-managed pane. Use when asked to ship via herdr or delegate ship to another agent/pane (e.g. "herdr で ship して", "codex に ship させて", "別 pane で ship して").
---

# Ship via Herdr

Delegate the `ship` workflow — implement, verify, commit/push/PR — to a **new
agent running in its own Herdr pane**, instead of doing the work yourself or
handing it to an in-session subagent.

## When to use this vs. `lead` / native subagents

Prefer `lead` or your host's native in-session subagent for same-provider
delegation — it's cheaper, keeps state in one process, and needs no external
tool. Use `ship-herdr` only when you need one of the two things a native
subagent cannot give you:

- **A different provider** doing the implementation (e.g. a `codex` instance,
  not just another instance of your own model). This is this skill's main
  reason to exist.
- **A pane a human can watch or steer live**, separate from your own
  conversation.

If neither applies, use `lead` instead.

## Prerequisite

This only works when you are running inside a Herdr-managed pane:

```bash
test "${HERDR_ENV:-}" = 1
```

If that fails, say so and fall back to the plain `ship` skill in your own
session. Do not attempt any of the steps below outside Herdr.

## Steps

1. **Create the worktree yourself, before spawning anything.** Use the
   `worktree` skill if your host has it; otherwise:
   ```bash
   git worktree add ../<repo>-<branch-slug> -b <type>/<short-description>
   ```
   Creating it here — not letting the child agent create its own — is what
   keeps worktree/branch ownership unambiguous: only the delegated agent may
   write inside this directory from this point on; you must not.

2. **Choose a report path outside the worktree** (e.g. `$(mktemp -t
   ship-herdr-report)`) the child will write its completion summary to.
   Keeping it outside the worktree means it survives even if the worktree is
   later removed, and can't be swept into the child's own `git add`. Passing
   this path in the prompt (next step) turns "the agent said it's done" into
   a file you can check, instead of scraped pane text — pane output can sit
   on the terminal's alternate screen and never reach scrollback, so anything
   you need to keep must not depend on reading the pane alone.

3. **Split a pane and start the agent** (plain shell CLI, no Claude-only
   primitive):
   ```bash
   herdr pane split --current --direction right --cwd "<worktree-path>" --no-focus
   # read the new pane id from .result.pane.pane_id
   herdr agent start <name> --kind <codex|claude|...> --pane <pane-id>
   ```
   Pick `<name>` unique and descriptive (e.g. `ship-<branch-slug>`).

4. **Prompt with the full task, the ship steps, and the report contract.**
   State inline: what to build; that it is already in the target worktree and
   must not create another; to run the project's lint/tests until green; to
   self-review the diff before committing; to commit with [Conventional
   Commits](https://www.conventionalcommits.org/), push, and open a PR; and to
   finish by writing the report path from step 2 as
   `{"branch", "commit", "pr_url_or_reason", "tests": "pass"|"fail", "notes"}`
   and replying with just that path.
   ```bash
   herdr agent prompt <name> "<the prompt above>" --wait --timeout 120000
   ```
   This `--wait` only confirms the prompt was accepted and the agent settled
   into a state (submit-and-settle handshake) — on a fast agent it can return
   `idle` long before the ship work is actually done. It is not a completion
   check; step 5 is.

5. **Drive the wait/triage loop — this is the spine of the skill, not a
   single call.** `agent prompt --wait` only settles on the *lifecycle*
   (idle/done/blocked), not on task completion. Ship is minutes of
   implement → test → commit → push → PR and will very likely hit `blocked`
   more than once (pre-commit hook failures, push/PR permission prompts).
   Loop:
   ```bash
   herdr agent wait <name> --until blocked --until idle --until done --timeout 300000
   ```
   - On `blocked`: run `herdr agent get <name>` and
     `herdr agent read <name> --source recent-unwrapped --lines 150` to see
     what it's asking. Answer with `herdr agent prompt <name> "..."` (or
     `send-keys` for a UI control) **only** if it is clearly within the scope
     you delegated. If it's asking permission for something consequential you
     didn't explicitly authorize, or you don't understand it, escalate to
     your user instead of approving it yourself — your user's ship request
     authorizes the *delegated agent's* push/PR, not you rubber-stamping
     unrelated prompts on its behalf, and you must never push or open the PR
     yourself in its place.
   - On `idle`/`done`: check whether the report file (step 2) now exists
     before treating the task as finished. If not, read the pane and prompt
     again — don't accept "it looks done" without the file.
   - Repeat until the report file exists, or you decide to abandon and report
     back to your user.

6. **Read the report file and relay it.** Report to your user: the pane id
   (leave it running — do not close it unless asked), the agent name, and the
   report contents (branch, commit, PR URL, test result). Treat the report
   file as the completion predicate, not your reading of the pane.

## When NOT to use this

- The task is trivial (a one-liner) — the pane/report overhead isn't worth it.
- Same-provider delegation with no need for a separate visible pane — use
  `lead` or your host's native subagent instead.
- Investigation-only requests — a diagnosis request isn't approval to spawn a
  ship-herdr agent that will push and open a PR; explain findings first and
  let the user confirm they want it shipped.
- You are not running inside Herdr (see Prerequisite).
