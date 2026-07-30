---
name: delegate
description: Hand a bounded piece of work to a subagent under an explicit contract, then check what comes back. Use when asked to delegate a specific task to a subagent, whatever its kind — implementation, research, or brainstorming (e.g. "この作業を subagent に投げて", "サブエージェントに調べさせて", "delegate this refactor to a subagent", "have subagents look into these in parallel").
---

# Delegate

Hand a **bounded piece of work** to a subagent under an explicit contract,
spawned through your host's native subagent mechanism, and judge what comes
back yourself. The work can be anything — a change, a question, a set of
angles to brainstorm.

The value is the **contract**: a narrow context, a stated acceptance
condition, and lead-side judgement of the result. A handoff without an
acceptance condition isn't delegation, it's hoping.

This is a **single handoff** (one unit, or a small fan-out over one bounded
piece of work) while you stay free to do everything else yourself. That's the
seam with `lead`: `lead` is a whole-task posture — decompose the entire task,
abstain from implementing any of it, review every unit — and it explicitly
disclaims the single-unit case. Reach for `lead` when the whole task is being
orchestrated; reach for `delegate` for one well-formed handoff.

Do not shell out to a separate CLI process to delegate. Use the host's native
in-session subagent primitive; if the host has none, do the work yourself in
the main loop.

## Steps

1. **Decide what to hand off.** Pick a piece with a boundary you can state.
   If you can't state a checkable acceptance condition, either re-cut it or
   keep it — a unit you can't judge on return is worse than no delegation. If
   it's a quick lookup or a one-line edit, just do it; the handoff overhead
   isn't worth it.

2. **Write the contract.** You do not rely on any pre-registered agent
   definition — **the contract travels inline in the spawn prompt.** State:
   - **What to do** — the target files/behavior for a change; the question,
     hypothesis, or angle for an inquiry.
   - **Done when** — a checkable completion condition. For a **change**, the
     behavior or test that must hold. For an **inquiry**, state it as
     **acceptance evidence**: sources with dates for factual claims,
     observation kept separate from inference, disconfirming evidence
     actively sought (not only supporting evidence), and claims stated so
     they could be checked or falsified. There is no test to run for an
     inquiry, so the evidentiary bar has to be explicit or the worker returns
     a confident-sounding but unverifiable summary.
   - **Scope** — for a change, the files/dirs the unit may modify. For an
     inquiry, **read-only: investigate and report, do not edit files or
     commit** — a worker reasoning about a question is prone to "helpfully"
     start acting on it — plus any source or time boundaries.
   - **Constraints / do not touch** — boundaries beyond scope: APIs or
     patterns to preserve, what not to assume, and no fabrication.
   - **Independence** — when several units attack the same question in
     parallel, give each a distinct hypothesis, source class, or angle
     rather than the same question reframed. Identical framing over the same
     sources yields correlated answers that only look like independent
     confirmation.
   - **Verify** — for a change, the command(s) to run and the expected
     evidence; if none apply (e.g. docs/config), say why. For an inquiry,
     there's nothing to run — the acceptance evidence above is the
     equivalent.
   - **Return** — changed files and the validation result, or the summary
     and the evidence behind it, plus any blockers or open questions.
   - **Stop and report** if the work needs to expand beyond scope — do not
     widen it unilaterally.
   Keep it concise: reference the relevant files or commands rather than
   restating them.

3. **Spawn via the host's native subagent (adapter).** Optionally pin a
   cheaper model/effort, optionally isolate the workspace, then collect the
   result. Model-pinning, parallelism, and isolation are **optional
   capabilities** — use them where the host offers them, skip them where it
   doesn't. The cells below are adapters, not guarantees: use each capability
   only where the installed host version/config actually exposes it.

   | Host | Spawn primitive | Cheaper model | Isolation |
   |------|-----------------|---------------|-----------|
   | Claude Code | Agent tool (`subagent_type: "general-purpose"`) | `model:` in the call | `isolation: "worktree"` |
   | Codex | `spawn_agent` + `send_message`/`wait_agent` | best-effort per-spawn `model`/`reasoning_effort` override, where exposed and available (use a **non-full-history** spawn; validated against the model catalog) | none — workers share the workspace |
   | Copilot CLI | the `task` tool | `task` `model` override | none by default |

   Use your host's **built-in** general subagent — the inline contract
   carries the full unit definition, so no custom agent setup is required.

   `pi`'s subagents run as separate OS processes — the cross-process path
   this skill avoids. Unless your pi setup treats them as native in-session
   delegation, do the work in the main loop instead.

   Parallelism: units with **no dependency** on each other may be dispatched
   concurrently where the host supports it. Change units that share a
   workspace (e.g. Codex) must have **disjoint write scopes**; only
   parallelize across overlapping files where the host can isolate each
   worker (e.g. Claude worktrees). Read-only inquiry units can't collide, so
   they parallelize freely. A unit that depends on another's output waits for
   it — never parallelize across a data dependency.

4. **Judge the result yourself.** The worker's report is **input**, not an
   accepted answer.
   - For a change: check the diff and the evidence against the "done when".
     If it isn't demonstrated, or scope leaked, send it back with a
     **narrower** contract; don't fix it yourself unless it's a one-liner.
   - For an inquiry: check the answer against its stated acceptance
     evidence, and send back anything asserted without the evidence it
     promised. Where parallel workers disagree, reconcile by weighing
     evidence quality (source recency, directness, whether disconfirming
     evidence was actually sought) — never by majority vote among workers.
     Carry the residual uncertainty into your own answer rather than
     laundering several confident summaries into one falsely-confident one.

   After a bounded number of retries, complete the unit yourself or report it
   blocked — don't let a failing unit hang indefinitely. Every unit you
   started must be accounted for: done (with evidence), sent back, or
   abandoned (with reason).

## When NOT to use this

- The **whole task** is being orchestrated — you're decomposing everything
  and abstaining from the implementation yourself. That's `lead`.
- A quick lookup or a one-line edit — the handoff overhead isn't worth it.
- Work that needs your own full capability on every step — just do it in the
  main loop.
- What you actually want is the **user's own decision or authorization**, not
  another agent's output — don't launder a decision the user should make
  through a subagent; ask them directly.
- The work needs genuine multi-stage pipelining, barriers, or a judge panel
  across many candidates — invoke your host's heavier orchestration primitive
  (e.g. Claude Code's Workflow tool) directly. That's a separate, explicitly
  invoked tool, not a branch inside this skill.
- You want a different provider's independent opinion on a plan you already
  have — see `advise-herdr`.
