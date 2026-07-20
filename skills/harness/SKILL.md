---
name: harness
description: Set up a project's dev tooling (gitignore, lint/format config, task runner, CI, Claude Code hooks, tests) for whatever language it uses. Use when asked to bootstrap dev tooling for a new or existing project (e.g. "harness を整備して", "set up the dev harness").
---

# Dev Harness

Set up the common tooling pillars below for **whatever language/stack the current
project uses** — don't assume a specific stack just because a past run used one.
Detect the stack first, adapt each pillar's specifics to it, and skip any pillar
that doesn't fit this project (say why) rather than forcing a bad fit. Not all
pillars apply to every project — a personal script needs a `.gitignore`, not CI
and a running-app MCP server.

## Step 0: Detect the stack and scope

- Find the project's manifest/lockfile(s) to identify language(s) and package
  manager(s): `pubspec.yaml`+`.fvmrc` (Flutter/fvm), `pyproject.toml`+`uv.lock`
  (Python/uv), `package.json`+lockfile (Node — check which:
  `pnpm-lock.yaml`/`yarn.lock`/`package-lock.json`), `Cargo.toml` (Rust), `go.mod`
  (Go), etc. If none exist yet, the project itself hasn't been scaffolded —
  do that first (`cargo init`, `flutter create`, ...); harness pillars assume
  there's already something to attach tooling to.
- If a sibling/reference project with an existing harness might exist, ask the
  user ("is there a project I should mirror the pattern from?") and read its
  actual current files rather than assuming — conventions drift.
- Check what's already present (existing `.gitignore`, CI, hooks) so you add/fix
  gaps, not duplicate or clobber.
- Confirm scope with the user if the repo has multiple sub-projects (e.g. `app/` +
  backend) — gitignore/CI often need per-directory splits.
- Before implementing, state which pillars you'll apply and which you're
  skipping (and why) — a short list, not a full plan-mode writeup — so the user
  can redirect before work starts.

## Common pillars

Apply the ones that fit (not all do). For each, apply the **principle**, then look
up the **stack-specific instantiation** (WebSearch/WebFetch) rather than trusting
memory — tool versions and MCP servers change fast.

1. **`.gitattributes`** — normalize line endings (`* text=auto eol=lf`); mark this
   stack's codegen output as `linguist-generated=true -diff`, but only for codegen
   this project actually uses (don't copy a template's dead rules).
2. **`.gitignore`** — build artifacts, caches, local env/secret files, editor
   cruft for this stack. Split root vs. subdirectory if the repo has sub-projects
   (a stack-specific one inside the sub-project, a minimal root one for
   cross-cutting concerns like `.DS_Store`).
3. **Lint/format config** — the settings the hook, task runner, and CI all depend
   on (the linter/formatter config for this stack, plus `.editorconfig`).
   Establish it — or confirm the scaffold's default is sane — *before* wiring
   anything that invokes it, otherwise those pillars run against nothing.
4. **Task runner** — recipes for install, lint, format, test, run, and an
   aggregate `check`, using the ecosystem's idiomatic runner and the project's
   *real* commands (never invent a command that isn't this stack's idiom).
5. **Claude Code PostToolUse format hook** (`.claude/hooks/format-on-edit.sh` +
   `.claude/settings.json`) — format the edited file by extension with this
   stack's formatter; keep it silent/best-effort (always exit 0). Don't
   reimplement what the formatter already does — verify any workaround against the
   project's actual config before adding it.
6. **Running-app / language MCP server** (`.mcp.json`) — *only if it fits*: an
   official language server (e.g. `dart mcp-server`) where one exists, and/or
   something that inspects a running instance (a browser MCP for a web frontend,
   `marionette_mcp` for Flutter). Skip entirely for a library/CLI with nothing to
   inspect. Research what currently exists for this stack; don't force a past
   project's choice onto a different one. If wiring it up requires a global host
   install (`dart pub global activate ...`, `npm i -g ...`), confirm with the
   user first — it changes their machine, not just this repo — and record the
   one-time command in the setup doc (pillar 9) regardless.
7. **CI** (the project's CI platform, path-filtered per sub-project) — the stack's
   standard setup step, reading the pinned version from the project's own pin file
   rather than hardcoding one that drifts from local dev. Enable dependency/SDK
   caching unless there's a reason not to.
8. **Tests** — confirm the test runner actually runs and passes on a trivial case;
   add a test helper mirroring this project's conventions only once a real case
   justifies it (don't scaffold empty dirs or unused parameters).
9. **Setup doc** — a minimal `CLAUDE.md`/`README` covering one-time host setup
   (SDK/version manager, any globally-activated tools the harness assumes) so a
   fresh clone is usable. Setup only — not a product/architecture doc.

## Execution

- **Default to doing the work inline.** The pillars are a handful of small config
  files, and the hard part is per-file judgment (is this rule dead? does this hook
  workaround apply here?), not mechanical bulk — so there's little to delegate.
  Just write them.
- **Delegate only when it actually pays off**: many independent files where
  parallel wall-clock speed is worth the overhead. Then, and only then, decompose
  into non-overlapping file-ownership contracts and fan out (`implementer`
  subagents, or the `lead` skill) — never for a 3-file harness.
- Verify each pillar with the stack's actual lint/test commands, and exercise what
  you can (run a task-runner recipe, trigger the hook) — not just "file exists".
- **Scale delivery weight to the ask, same as implementation.** A substantial,
  standalone harness setup goes through the `ship` skill (worktree → implement →
  verify → review → commit/push/PR). A small addition to work already in flight
  (an open branch/PR, a mid-feature worktree) just gets committed there — don't
  spin up a new worktree+PR for one file. Either way, "set up the harness" alone
  doesn't authorize pushing and opening a PR — per the standing rule on
  consequential actions, confirm before push/PR unless the request already
  covers it (e.g. the user said "ship it," or you're adding to an already-open PR).
- When it does go through `ship`, its review step matters here: harness changes
  touch shell/CI/config surfaces that are easy to get subtly wrong (infinite
  loops in hook scripts, missing CI caching, wrong dependency section, dead
  config carried over from a reference project) — scale review effort to the
  diff, a couple of files is a quick pass, a large multi-sub-project harness
  warrants high effort.
- After a PR is open, the first CI run is the real test of the CI pillar —
  confirm it goes green (or fix and push), don't assume it passes.

## Do NOT

- Force a pillar that doesn't fit (no MCP server exists for this stack, or CI is
  inappropriate for a personal script) — skip it and say why, don't fabricate a
  fit.
- Copy a reference project's file verbatim without checking it's still accurate
  for *this* project's actual config (e.g. a hook tuned to another project's
  `page_width` setting is dead code here if this project sets none).
- Expand the setup doc (pillar 9) into a product or architecture doc — keep it to
  one-time setup.
