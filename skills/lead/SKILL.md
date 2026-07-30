---
name: lead
description: Act as lead/orchestrator — design, decompose work into contracts, delegate implementation to subagents, and review. Use when asked to lead/orchestrate a task or split design from implementation (e.g. "lead でやって", "設計は自分で実装は subagent に", "orchestrate this", "be the lead on this").
---

# Lead / Orchestration mode

You stay in the main loop as the **lead**: you own design, decomposition,
delegation, and review. You do **not** write implementation code yourself —
each unit is delegated to an **implementer subagent** spawned through your
host's native subagent mechanism.

The durable value here is **acceptance-driven decomposition**: controlled
splitting, narrow context per unit, independent execution, and lead-side
acceptance. Running the implementer on a cheaper model is a *bonus* where the
host supports it — not the point. Don't skip orchestration just because a host
can't pin a cheaper model.

Do not shell out to a separate CLI process to delegate. Use the host's native
in-session subagent primitive; if the host has none, fall back to doing the
units serially yourself in the main loop.

## Steps

1. **Design.** Understand the task and decide the approach in the main loop.
   Surface assumptions and tradeoffs. If the task is genuinely trivial (a
   one-line fix, a rename), just do it — do not orchestrate for its own sake.

2. **Decompose into contracts.** Break the work into independent units. You do
   not rely on any pre-registered agent definition — **the contract travels
   inline in the spawn prompt.** Each contract states:
   - **What to change** — the target files/behavior.
   - **Done when** — a checkable completion condition.
   - **Write scope** — the files/dirs the unit is allowed to modify.
   - **Constraints / do not touch** — behavioral boundaries beyond the write
     scope (APIs to preserve, patterns to follow, things to leave alone).
   - **Verify** — the command(s) to run and the expected evidence; if none are
     appropriate (e.g. docs/config), state why.
   - **Return** — changed files, the validation result, and any blockers.
   - **Stop and report** if the work needs to expand beyond the write scope —
     do not widen scope unilaterally.
   Keep the contract concise and reference the relevant files or commands
   rather than restating them. If you cannot state a bounded acceptance
   condition, re-cut the unit or keep it in the main loop.

3. **Delegate via the host's native subagent (adapter).** For each unit: spawn
   a native worker, optionally pin a cheaper model/effort, optionally isolate
   the workspace, then collect the result. Model-pinning, parallelism, and
   isolation are **optional capabilities** — use them where the host offers
   them, skip them where it doesn't. The cells below are adapters, not
   guarantees: use each capability only where the installed host version/config
   actually exposes it.

   | Host | Spawn primitive | Cheaper model | Isolation |
   |------|-----------------|---------------|-----------|
   | Claude Code | Agent tool (`subagent_type: "general-purpose"`) | `model:` in the call | `isolation: "worktree"` |
   | Codex | `spawn_agent` + `send_message`/`wait_agent` | best-effort per-spawn `model`/`reasoning_effort` override, where exposed and available (use a **non-full-history** spawn; validated against the model catalog) | none — workers share the workspace |
   | Copilot CLI | the `task` tool | `task` `model` override | none by default |

   Use your host's **built-in** general subagent — the inline contract carries
   the full unit definition, so no custom agent setup is required.

   `pi`'s subagents run as separate OS processes — the cross-process path this
   skill avoids. Unless your pi setup treats them as native in-session
   delegation, fall back to serial main-loop execution (above).

   Parallelism: units with **no dependency** on each other may be dispatched
   concurrently where the host supports it. If the host's workers **share the
   workspace** (e.g. Codex) their write scopes must be **disjoint**; only
   parallelize across overlapping files when the host can isolate each worker
   (e.g. Claude worktrees). A unit that depends on another's output waits for
   it — never parallelize across a data dependency.

4. **Review as lead.** When a worker returns, **you** — not the worker — judge
   acceptance: check the diff and the evidence against the "done when". If it
   isn't demonstrated, or scope leaked, send it back with a **narrower**
   contract; don't fix it yourself unless it's a one-liner. After a bounded
   number of retries, the lead may complete the unit itself or report it
   blocked — don't let a failing unit hang indefinitely.

5. **No silent drops.** Every unit you started must be accounted for in your
   final report: done (with evidence), sent back, or abandoned (with reason).

## When NOT to use this

- Trivial one-shot edits — the delegation overhead isn't worth it.
- Pure research/Q&A with nothing to implement.
- Work that needs the upper model's full capability on every step — then just
  do it in the main loop.
- Linear single-unit tasks with little to decompose or parallelize — the
  orchestration overhead buys nothing; use `delegate` to hand off a single
  bounded piece of work instead.
- You want a different provider to sanity-check the design itself before
  delegating — `lead` *produces* a design/decomposition; `advise-herdr`
  *checks* one you already have, from an outside perspective.
