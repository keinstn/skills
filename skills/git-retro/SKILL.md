---
name: git-retro
description: Turn a period of GitHub activity into a personal development
  retrospective. Use when asked to reflect on recent work, summarize activity
  over a period, or turn coding history into a narrative (e.g. "最近の活動を
  振り返って", "turn my GitHub activity into a story", "四半期の振り返りを
  したい").
---

# Git Retro

Turn a period of GitHub activity into a grounded narrative of what the user
built and why — combine a deterministic data digest with questions that draw
out context only the user has. Requires `gh` (authenticated) and `jq`.

## Step 0: Determine scope

Ask (if not already given): the date range (e.g. "last month", "since
2026-05-01") and the GitHub user/org, if not inferable from `gh auth status`.

## Step 1: Gather activity

Run `scripts/gather.sh <user> <since> <until>` (dates as `YYYY-MM-DD`). It
prints a digest: repos created in range (with privacy/fork status, language,
description), README excerpts for each, and PRs opened against repos the
user does *not* own — the part a plain repo listing misses.

Read the digest as-is; don't re-derive it by hand with separate `gh` calls.

## Step 2: Present findings, then ask for the "why"

Show the user a grouped, dated summary distinguishing shipped
products/apps from tools/infra/research where the READMEs make that clear —
don't force a category that isn't there. Then ask what the digest can't
answer:

- What prompted each transition or new direction?
- Anything tried and abandoned? Why?
- Milestones (plan upgrades, new tools discovered, external contributions)
  that changed what was possible?

Do not guess at motivations. An unanswered gap stays a gap in the writeup,
not an invented explanation.

## Step 3: Synthesize

Combine the Step 1 digest with Step 2 context into a retrospective,
structured by period. Keep two layers separate: the technical narrative
(what changed, in what order, why) vs. personal reflection (how it felt) —
include the latter only if asked.

## Step 4: Optional output

Ask where this should go (blog draft, journal entry, or just the
conversation) — don't assume a destination.
