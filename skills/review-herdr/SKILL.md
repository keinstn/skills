---
name: review-herdr
description: Delegate review of a diff or PR to a new agent in a separate Herdr pane — use to get an independent second opinion from a different provider (e.g. codex) on that diff or PR. Read-only — findings only, no fixes. Requires running inside a Herdr-managed pane. Use when asked to review a diff or PR via herdr (e.g. "herdr で review して", "codex にレビューさせて", "この diff を別agentに見てもらって"). For a plan or decision instead of a diff, see `advise-herdr`.
---

# Review via Herdr

Delegate review of a diff or PR to a **new agent running in its own Herdr
pane**, to get an independent second opinion — most valuable when that agent
is a **different provider** than whoever authored the change or is asking for
the review, since a same-model reviewer shares the same blind spots as the
implementer.

This is deliberately **read-only**: the delegated agent reports findings, it
does not fix them. If you also want fixes applied by a delegated agent, that
is a separate, write-scoped task — see `ship-herdr`.

## When to use this vs. reviewing yourself / `/code-review` / native subagent

Prefer reviewing the diff yourself, or your host's own review mechanism
(`/code-review`, `codex exec review`, etc.), when a same-provider review is
enough. Use `review-herdr` when you specifically want:

- **A different provider's** independent judgment (e.g. a `codex` instance
  reviewing a Claude-authored diff, or vice versa) — this is the skill's main
  reason to exist.
- A pane a human can watch live while the review runs.

## Prerequisite

```bash
test "${HERDR_ENV:-}" = 1
```

If that fails, say so and review the diff yourself instead. Do not attempt
the steps below outside Herdr.

## Steps

1. **Decide what the target actually is — this determines whether you need a
   worktree at all:**
   - **Your own uncommitted working-tree diff** (the most common case) — a
     worktree of the same repo does **not** carry uncommitted changes, so a
     child pointed at one would review nothing. Point the child at the
     **same directory** you're in instead, and stop editing while it runs —
     two processes touching your live working tree at once is asking for
     confusion.
   - **A pushed branch or open PR** — no worktree needed either; give the
     child `gh pr diff <n>` or a branch/commit range to fetch and diff.
   - **A different branch than the one currently checked out** — only here
     do you need a worktree (use the `worktree` skill if your host has one)
     so the child gets its own checkout without disturbing yours.

2. **Choose a report path outside the repo** (e.g. `$(mktemp -t
   review-herdr-report)`), and pass it to the child in the prompt. Keeping it
   outside the repo means it can't be swept into a later `git add` or lost if
   a worktree from case 3 above is later removed. As with `ship-herdr`, treat
   the file as the completion predicate — pane output can sit on the
   terminal's alternate screen and never reach scrollback, so don't rely on
   reading the pane alone for the findings.

3. **Split a pane and start the agent:**
   ```bash
   herdr pane split --current --direction right --cwd "<repo-or-worktree-path>" --no-focus
   # read the new pane id from .result.pane.pane_id
   herdr agent start <name> --kind <codex|claude|...> --pane <pane-id>
   ```

4. **Prompt with the review scope and the report contract.** State inline:
   what to review (diff, PR number/URL, or branch range); that this is
   **read-only — do not edit files, do not commit**; the dimensions to cover
   (correctness, security, scope creep, missing tests — adapt to the task);
   and to finish by writing the report path from step 2 as
   `{"findings": [{"file", "line", "summary", "severity"}], "verdict": "..."}`
   and replying with just that path.
   ```bash
   herdr agent prompt <name> "<the prompt above>" --wait --timeout 120000
   ```
   This `--wait` only confirms the prompt was accepted and the agent settled
   into a state (submit-and-settle handshake) — on a fast agent it can return
   `idle` before real work is done. It is not a completion check; step 5 is.

5. **Drive the wait/triage loop.** Review is usually faster and lower-risk
   than `ship-herdr` (no push/PR permission prompts to hit), but still loop
   rather than trusting a single `--wait`:
   ```bash
   herdr agent wait <name> --until blocked --until idle --until done --timeout 180000
   ```
   - On `blocked`: read the pane
     (`herdr agent read <name> --source recent-unwrapped --lines 150`) to see
     what it's asking. Since the task is read-only, `blocked` most likely
     means it wants to run a command it isn't sure is safe (e.g. executing
     tests) — answer if clearly in scope, otherwise escalate to your user.
   - On `idle`/`done`: confirm the report file exists before treating the
     review as finished; if not, read the pane and prompt again.

6. **Read the report file and relay it to your user.** Treat its findings as
   one independent opinion, not a verdict to apply automatically — weigh it
   the way you would any second reviewer's comments, and say so explicitly if
   it disagrees with your own read of the diff.

## When NOT to use this

- A same-provider review is enough — use your own read of the diff or the
  host's built-in review mechanism instead.
- The task also requires fixes, not just findings — use `ship-herdr` (or do
  it yourself) instead; keep this skill read-only.
- There's no diff or PR yet — you want a second opinion on a plan or decision
  before implementing. Use `advise-herdr` instead.
- You are not running inside Herdr (see Prerequisite).
