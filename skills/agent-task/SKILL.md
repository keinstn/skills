---
name: agent-task
description: Create a GitHub issue for an AI coding agent task. Use when asked to create an issue for an AI agent (e.g. "AI に依頼する issue を作って", "create an agent task issue", "open a task for the agent").
---

# Agent Task Issue

Create a GitHub issue formatted for AI coding agents. Follow the steps below.

## Step 0: Assess task scope

Before gathering information, determine if the task should be split into
multiple issues. Split into a parent + sub issue structure if **any** of
the following apply:

- **A. Dependencies exist** — completion of one task is a prerequisite for another
- **B. Independently mergeable** — each part can become a separate PR and reviewed/merged independently
- **E. Scale too large** — the task is too broad to fit in a single agent-task issue

If none apply, proceed directly to Step 1.

## Step 0a: Multi-issue structure

If splitting is needed, create a parent issue and sub issues as follows.

### Parent issue
- Title: concise description of the overall goal
- Body: overview, purpose, and background (no need for agent-task format)
- Labels: same inference rules as Step 3

### Sub issues
- Follow the agent-task format (Steps 1–3) for each sub issue
- Granularity: **one unit completable by a single agent**
- Link each sub issue to the parent issue
- Set `blockedBy` between sub issues where dependencies exist (criterion A applies)

---

## Step 1: Gather information

Collect the following from the user's description and current conversation context.
Ask clarifying questions for any missing required fields before proceeding.

| Field | Required | Description |
|---|---|---|
| Summary | yes | What is being built and why. Include background and motivation. |
| Scope | yes | What's in and explicitly what's out. The "out" prevents over-engineering. |
| Implementation notes | yes | Key files, patterns to follow, technical constraints. Name specific files if known. |
| Acceptance criteria | yes | Testable checklist. Tie each item to a command the agent can run to self-verify. |
| References | no | Related issues, PRs, documentation, or file paths. |

## Step 2: Format the issue body

Generate the body using this exact structure:

```
## Summary

<summary>

## Scope

In:
- <what's included>

Out (do NOT):
- Do NOT <what's excluded>

## Implementation notes

- <files and patterns>

## Acceptance criteria

- [ ] <criterion>
- [ ] All tests pass (`<test command>`)

## References

<references if any, omit section if none>
```

## Step 3: Create the issue

- Title: a concise, action-oriented description of the task
- Body: the formatted content from Step 2
- Labels: infer appropriate labels from the issue content (e.g. `bug`, `enhancement`, `documentation`, `refactoring`, `testing`). Apply best-effort — skip labels that may not exist in the repository. Do NOT add `ai-ready`. If the user explicitly specifies labels, use those instead.
- Use the GitHub MCP server if available; fall back to `gh issue create` otherwise
