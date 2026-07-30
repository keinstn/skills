---
name: delegate
description: Act as lead for inquiry work — decompose a research or brainstorming question into independent angles, delegate each to a subagent, and synthesize the reconciled answer. Use when asked to delegate research, investigate something in parallel, or get independent takes on a question (e.g. "サブエージェントに調べさせて", "look into these in parallel and report back", "get independent takes on this question").
---

# Delegate / Inquiry orchestration mode

You stay in the main loop as the lead for **inquiry work** — research,
brainstorming, multi-angle investigation. You do not do all the digging
yourself: each angle is delegated to a **worker subagent** spawned through
your host's native subagent mechanism, and you **synthesize** their findings
into one reconciled answer.

This is `lead`'s sibling for work with nothing to implement. Where `lead`
decomposes a coding task into write-scoped, test-verified units, `delegate`
decomposes a question into independently-investigated angles, backed by
evidence rather than a diff. Don't run both on the same task — decide which
shape the work has first.

Do not shell out to a separate CLI process to delegate. Use the host's native
in-session subagent primitive; if the host has none, fall back to
investigating the angles serially yourself in the main loop.

## Steps

1. **Frame the question.** Understand what's being asked and decide the
   angles worth investigating independently — distinct hypotheses, source
   classes, or perspectives, not the same question asked N times. If there's
   really only one angle, or the answer is a quick lookup, just answer it —
   do not orchestrate for its own sake.

2. **Decompose into inquiry contracts.** One per angle. You do not rely on
   any pre-registered agent definition — **the contract travels inline in
   the spawn prompt.** Each contract states:
   - **What to investigate** — the question, hypothesis, or angle this unit
     owns, distinct from the others' (see Independence below).
   - **Acceptance evidence** — what must accompany the answer for it to be
     usable: sources with dates for factual claims, observations kept
     separate from inference, disconfirming evidence actively sought (not
     only supporting evidence), and claims stated so they could be checked
     or falsified. This replaces `lead`'s "Verify" — there is no test to
     run, so the evidentiary bar has to be stated explicitly or the worker
     will return a confident-sounding but unverifiable summary.
   - **Constraints** — scope and source boundaries (e.g. files/paths/time
     range/what not to assume), an explicit no-fabrication instruction, and
     **read-only: investigate and report, do not edit files or commit** — a
     worker reasoning about a question is prone to "helpfully" start
     acting on it.
   - **Independence** — this unit's hypothesis, source class, or angle,
     stated so it's distinct from its siblings' rather than the same
     question reframed. Assign these when you split the question in step 1:
     identical framing plus the same sources produces correlated answers
     that only look like independent confirmation.
   - **Return** — a summary, the evidence behind it, and open
     questions/caveats.
   - **Stop and report** if the angle turns out to need something outside
     its scope (e.g. it depends on another unit's answer) — do not widen
     scope unilaterally.
   If you cannot state a concrete evidentiary bar, re-cut the unit or answer
   it yourself in the main loop.

3. **Delegate via the host's native subagent (adapter).** Same adapters as
   `lead`:

   | Host | Spawn primitive | Cheaper model |
   |------|-----------------|---------------|
   | Claude Code | Agent tool (`subagent_type: "general-purpose"`) | `model:` in the call |
   | Codex | `spawn_agent` + `send_message`/`wait_agent` | best-effort per-spawn `model`/`reasoning_effort` override, where exposed and available (use a **non-full-history** spawn; validated against the model catalog) |
   | Copilot CLI | the `task` tool | `task` `model` override |

   Use your host's **built-in** general subagent — the inline contract
   carries the full unit definition, so no custom agent setup is required.
   The contract's read-only constraint (above) stands in for `lead`'s
   write-scope isolation — there's nothing to isolate as long as the worker
   respects it.

   `pi`'s subagents run as separate OS processes — the cross-process path
   this skill avoids. Unless your pi setup treats them as native in-session
   delegation, fall back to serial main-loop investigation (above).

   Units with no data dependency on each other may be dispatched
   concurrently wherever the host supports it — a read-only worker can't
   produce a shared-workspace write conflict. A unit that depends on
   another's answer waits for it.

   If your host also exposes a heavier multi-stage orchestration primitive
   (e.g. Claude Code's Workflow tool), that is a separate, explicitly
   invoked tool — not a branch inside this skill. Call it directly when the
   task genuinely needs pipelining, barriers, or a judge panel across many
   candidates. `delegate` covers the common case: a handful of angles,
   investigated in parallel, synthesized once.

4. **Synthesize as lead — do not just relay.** A worker's report is
   **input**, not an accepted final answer. When workers return, reconcile
   them yourself:
   - Check each against its stated acceptance evidence; a claim missing the
     evidence it promised goes back with a narrower contract, the same way
     `lead` sends back undemonstrated work.
   - Where workers disagree, reconcile by weighing evidence quality (source
     recency, directness, whether disconfirming evidence was actually
     sought) — never by majority vote among the workers.
   - State the synthesized answer's own uncertainty and open questions;
     don't launder several confident-sounding worker summaries into one
     falsely-confident answer.

5. **No silent drops.** Every angle you started must be accounted for in
   your final report: synthesized (with evidence), sent back, or abandoned
   (with reason).

## When NOT to use this

- Implementation work — use `lead`; this skill is for questions, not diffs.
- A single quick lookup with nothing to decompose — just answer it.
- What you actually want is the **user's own decision or authorization**,
  not another agent's opinion — don't launder a decision the user should
  make through a subagent; ask them directly.
- The task needs genuine multi-stage pipelining, barriers, or a judge panel
  across many candidates — invoke your host's heavier orchestration tool
  (e.g. Workflow) directly instead of forcing it through this contract
  shape.
- You want a different provider's independent opinion on a plan you already
  have — see `advise-herdr` instead.
