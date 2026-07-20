---
name: worktree
description: Create a git worktree in a directory adjacent to the current repo before starting implementation. Use when asked to start implementation in a worktree (e.g. "worktree を作って実装して", "create a worktree", "start in a worktree").
---

# Worktree Setup

Create a git worktree in a directory adjacent to the current repository, then continue implementation there.

## Step 1: Determine the branch name

Derive a short, descriptive branch name from the task:
- Format: `<type>/<short-description>` (e.g. `feat/add-login`, `fix/null-pointer`)
- If the user has already specified a branch name, use it as-is
- If uncertain, ask the user before proceeding

## Step 2: Create the worktree

Run the following command from the repository root:

```
git worktree add ../<repo-name>-<branch-slug> -b <branch-name>
```

Where:
- `<repo-name>` is the name of the current repository directory (e.g. `$(basename $PWD)`)
- `<branch-slug>` is the branch name with `/` replaced by `-` (e.g. `feat-add-login`)
- `<branch-name>` is the full branch name (e.g. `feat/add-login`)

Example: if the repo is `myapp` and the branch is `feat/add-login`, run:
```
git worktree add ../myapp-feat-add-login -b feat/add-login
```

## Step 3: Switch working directory

After creating the worktree, all subsequent file reads, edits, and shell commands must be performed inside the new worktree directory. Do not modify files in the original directory.

## Step 4: Implement

Proceed with the implementation task in the worktree directory.

## Notes

- The worktree branches from the current local HEAD by default
- To branch from `origin/main` instead, add `origin/main` as the base: `git worktree add ../... -b <branch> origin/main`
- When done, the user can remove the worktree with `git worktree remove ../<worktree-dir>`
