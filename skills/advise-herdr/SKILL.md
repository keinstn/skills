---
name: advise-herdr
description: Delegate a plan, approach, or decision to a new agent in a separate Herdr pane for an independent second opinion from a different provider — before you implement, not after. Requires running inside a Herdr-managed pane. Use when asked to get advice on a plan/approach via herdr (e.g. "この方針でいいか別agentに聞いて", "plan をcodexに見てもらって", "別agentに相談して").
---

# Advise via Herdr

Delegate a **plan, approach, or decision you haven't implemented yet** to a
new agent running in its own Herdr pane, to get an independent second opinion
— most valuable when that agent is a **different provider** than you, since a
same-provider check shares your blind spots.

This is a **pre-implementation gut-check**: the child answers a question, it
does not implement anything. If the decision is already made and there's a
diff or PR to check instead, see `review-herdr`.

## When to use this vs. checking yourself / your host's own advisor mechanism / `lead`

Prefer checking with yourself, or your host's own advisor/consult mechanism
(a stronger-model escalation, an in-session advisor tool, etc.), when a
same-provider check is enough. Use `advise-herdr` when you specifically want:

- **A different provider's** independent judgment on a plan (e.g. a `codex`
  instance checking a Claude-drafted plan, or vice versa) — this is the
  skill's main reason to exist.
- A pane a human can watch live while the consult runs.

`lead` *produces* a design/decomposition by orchestrating implementers.
`advise-herdr` *checks* a design you already have, from an outside
perspective. They compose: design with `lead`, then sanity-check the result
with `advise-herdr` before delegating implementation.

## Prerequisite

```bash
test "${HERDR_ENV:-}" = 1
```

If that fails, say so and fall back to a same-provider check in your own
session instead. Do not attempt the steps below outside Herdr.

## Steps

1. **Triage what grounding the question needs.**
   - **Repo-grounded** (the plan concerns this codebase) — point `--cwd` at
     the repo, tell the child it is **read-only**, and cite the exact
     files/paths or commit range it must read before answering. Don't rely on
     the child to go discover context on its own; a same-repo but
     under-oriented child gives confident noise, not signal.
   - **Repo-independent** (a general design/approach question) — point it at
     a scratch directory with no repo access; the brief (next step) is its
     entire world.

2. **Write the brief to a file, don't inline it in the prompt.** Multi-
   paragraph context with quotes/newlines is a shell-quoting hazard in an
   inline `herdr agent prompt` string, and a file is inspectable before you
   send it and relayable to your user afterward. Writing it also forces the
   packaging to actually happen rather than being improvised into a one-liner.
   Choose a path outside the repo (e.g. `$(mktemp -t advise-herdr-brief)`) and
   include:
   - The decision to be made, and its **cost/reversibility** if wrong.
   - Constraints it must respect.
   - Options already considered **and why each was rejected**.
   - What a good answer needs to address.
   - The artifacts (files, paths, commit range) it should read, if grounded.
   - An **anti-sycophancy instruction**: if you state a preferred option in
     the brief, explicitly tell the child to argue against it. A same-blind-
     spot rubber stamp defeats the entire reason to ask a different provider.

3. **Choose a report path outside the repo** (e.g. `$(mktemp -t
   advise-herdr-report)`) for the child's answer, for the same reason as the
   brief — it survives worktree cleanup and can't be swept into a `git add`.

4. **Split a pane and start the agent:**
   ```bash
   herdr pane split --current --direction right --cwd "<repo-or-scratch-path>" --no-focus
   # read the new pane id from .result.pane.pane_id
   herdr agent start <name> --kind <codex|claude|...> --pane <pane-id>
   ```

5. **Prompt with the brief and report contract.** Since the brief is already
   a file, the prompt itself is trivial: read the brief path, answer the
   question, and write the report path. State inline that this is
   **read-only — do not edit files, do not commit** (more important here than
   for `review-herdr`: a child reasoning about a plan is more likely to
   "helpfully" start implementing it). The report must be written as
   `{"recommendation", "risks": [...], "assumptions": [...], "open_questions": [...]}`
   — no free-form reasoning wall of text, no self-reported confidence.
   `assumptions`/`open_questions` are what make a thin or under-packaged
   brief detectable instead of silently confident.
   ```bash
   herdr agent prompt <name> "Read <brief-path>, answer the question there, and write your answer to <report-path> as {...}. Do not edit files or commit." --wait --timeout 120000
   ```
   This `--wait` only confirms the prompt was accepted and the agent settled
   into a state (submit-and-settle handshake) — it is not a completion check;
   step 6 is.

6. **Drive the wait/triage loop.**
   ```bash
   herdr agent wait <name> --until blocked --until idle --until done --timeout 180000
   ```
   - On `blocked`: read the pane
     (`herdr agent read <name> --source recent-unwrapped --lines 150`). The
     most likely cause here is a clarifying question about *your question* —
     answering it well is exactly the repair for an under-packaged brief.
   - On `idle`/`done`: confirm the report file exists before treating the
     consult as finished; if not, read the pane and prompt again.
   - **If `open_questions` comes back non-empty and material,** answer them
     and re-prompt rather than relaying immediately — but cap this at **two**
     re-prompts. This is meant to be a quick gut-check, not a long
     negotiation; if it's still unresolved after two rounds, relay what you
     have and flag the open question to your user instead.

7. **Read the report and relay it to your user.** Treat it as one independent
   opinion, not a verdict to apply automatically. If the child disagrees with
   the plan you had in mind, **surface the disagreement and the tradeoff
   explicitly** — don't silently switch to the child's plan.

## When NOT to use this

- The decision is already made or already implemented — there's a diff or PR
  to check instead, use `review-herdr`.
- The answer is discoverable by reading the code or docs yourself — don't use
  a consult to skip your own orientation work; an under-researched question
  yields confident noise, not a useful second opinion.
- You can't state the question in a paragraph — you don't understand the
  problem well enough yet; read more first.
- What you actually want is the **user's authorization**, not another agent's
  opinion — don't launder a decision the user should approve through a
  delegated agent; escalate to your user instead.
- A same-provider check is enough — use your host's own advisor/consult
  mechanism or a stronger-model escalation instead.
- The task also needs implementation, not just advice — use `ship-herdr`.
- Trivial decisions — the pane/brief/report overhead isn't worth it.
- You are not running inside Herdr (see Prerequisite).
