---
name: herdr-core
description: "Use herdr-core (CLI: hc) when the user mentions hc/herdr-core, or asks to consult, delegate to, or coordinate agents of another provider (pi with GPT/Gemini, codex, …), other terminals/agents in this workspace, or agents on another machine. Not for ordinary in-session subagents (use your host's native subagent tool) or background shell commands."
---

<!-- Body copied from https://github.com/herdrdev/herdr-core/blob/master/skills/herdr-core/SKILL.md (2026-11-25); description narrowed so it does not displace native subagents. -->

This skill is for herdr-core, whose command is `hc`. It is not `herdr`,
the older terminal multiplexer: that has its own `herdr` command and skill.
Use `hc` here, never `herdr`.

If `$HC_TERMINAL_ID` is set, you're running inside herdr-core: use hc.
If not, ask the user once this session whether to use hc for this work.

Before using hc, run `hc --skill` and follow it.
For the Herdr window (spaces, tabs, layouts, mods, what's shown),
run `herdr-app --skill`.
