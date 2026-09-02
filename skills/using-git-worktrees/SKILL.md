---
name: using-git-worktrees
description: Use when needed isolation from current workspace - ensures an isolated workspace exists via native tools or git worktree fallback
---

# Using Git Worktrees

## Overview

Ensure work happens in an isolated workspace. Prefer your platform's native worktree tools. Fall back to manual git worktrees only when no native tool is available.

**Core principle:** Detect existing isolation first. Then use native tools. Then fall back to git. Never fight the harness.

**Announce at start:** "I'm using the **using-git-worktrees** skill to set up an isolated workspace."

## Step 0: Detect Existing Isolation

**Before creating anything, check if you are already in an isolated workspace.**

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
BRANCH=$(git branch --show-current)
```

**Submodule guard:** `GIT_DIR != GIT_COMMON` is also true inside git submodules. Before concluding "already in a worktree," verify you are not in a submodule:

```bash
# If this returns a path, you're in a submodule, not a worktree — treat as normal repo
git rev-parse --show-superproject-working-tree 2>/dev/null
```

**If `GIT_DIR != GIT_COMMON` (and not a submodule):** You are already in a linked worktree. Skip to Step 2 (Project Setup). Do NOT create another worktree.

Report with branch state:

- On a branch: "Already in isolated workspace at `<path>` on branch `<name>`."
- Detached HEAD: "Already in isolated workspace at `<path>` (detached HEAD, externally managed). Branch creation needed at finish time."

**If `GIT_DIR == GIT_COMMON` (or in a submodule):** You are in a normal repo checkout.

Has the user already indicated their worktree preference in your instructions? If not, ask for consent before creating a worktree:

> "Would you like me to set up an isolated worktree? It protects your current branch from changes."

Honor any existing declared preference without asking. If the user declines consent, work in place and skip to Step 2.

### Isolation Boundary

Once the user chooses to create an isolated worktree, the original worktree becomes read-only for the rest of the task. Record its state before creating anything:

```bash
ORIGINAL_WORKTREE=$(git rev-parse --show-toplevel)
ORIGINAL_BRANCH=$(git branch --show-current)
ORIGINAL_HEAD=$(git rev-parse HEAD)
ORIGINAL_STATUS=$(git status --porcelain=v1 --untracked-files=all)
```

From this point forward:

- Do not edit, create, or delete files inside the original worktree.
- Do not stage, commit, stash, switch, checkout, reset, merge, or rebase in the original worktree or on its current branch.
- Creating the new worktree and its new branch may update Git's shared worktree metadata, but must not move the original worktree's `HEAD`, change its current branch, index, or files.
- Put the new worktree outside the original worktree directory. Do not add a project-local worktree directory to `.gitignore` as part of this flow.
- Run all setup, tests, and implementation commands only after entering and verifying the new worktree.

If isolation cannot be created while preserving this boundary, stop and report the blocker. Do not fall back to working in the original worktree unless the user gives new, explicit permission to abandon isolation.

## Step 1: Create Isolated Workspace

**You have two mechanisms. Try them in this order.**

### 1a. Native Worktree Tools (preferred)

The user has asked for an isolated workspace (Step 0 consent). Do you already have a way to create a worktree? It might be a tool with a name like `EnterWorktree`, `WorktreeCreate`, a `/worktree` command, or a `--worktree` flag. If its contract preserves the isolation boundary above, use it and then perform the post-creation verification below.

Native tools handle directory placement, branch creation, and cleanup automatically. Using `git worktree add` when you have a native tool creates phantom state your harness can't see or manage.

Only proceed to Step 1b if you have no compatible native worktree tool available.

### 1b. Git Worktree Fallback

**Only use this if Step 1a does not apply** — you have no native worktree tool available. Create a worktree manually using git.

#### Directory Selection

The destination must be outside `ORIGINAL_WORKTREE` so creating it cannot add files beneath the original checkout.

1. **Check your instructions for a declared external worktree directory preference.** If the user has already specified one, use it without asking.

2. **If there is no compatible preference**, use a sibling directory outside the project root:
   ```bash
   PROJECT_NAME=$(basename "$ORIGINAL_WORKTREE")
   LOCATION="$(dirname "$ORIGINAL_WORKTREE")/.worktrees-$PROJECT_NAME"
   ```

If the user's requested location is inside the original worktree, explain the conflict and ask for an external location. Do not modify `.gitignore` to make the location usable.

#### Create the Worktree

```bash
# Determine path based on chosen location
WORKTREE_PATH="$LOCATION/$BRANCH_NAME"

mkdir -p "$LOCATION"
git worktree add "$WORKTREE_PATH" -b "$BRANCH_NAME" "$ORIGINAL_HEAD"
cd "$WORKTREE_PATH"
```

If `git worktree add` fails, report the failure and stop. Do not run setup or implementation in the original worktree.

### Post-Creation Verification

Before setup or implementation, verify both the new location and the original state:

```bash
NEW_WORKTREE=$(git rev-parse --show-toplevel)
case "$NEW_WORKTREE/" in
  "$ORIGINAL_WORKTREE"/*) false ;;
esac
test "$(git branch --show-current)" = "$BRANCH_NAME"
test "$(git -C "$ORIGINAL_WORKTREE" branch --show-current)" = "$ORIGINAL_BRANCH"
test "$(git -C "$ORIGINAL_WORKTREE" rev-parse HEAD)" = "$ORIGINAL_HEAD"
test "$(git -C "$ORIGINAL_WORKTREE" status --porcelain=v1 --untracked-files=all)" = "$ORIGINAL_STATUS"
```

If any check fails, stop and report the difference. Do not repair, reset, or clean the original worktree automatically.

## Step 2: Project Setup

Auto-detect and run appropriate setup:

```bash
# Node.js
if [ -f package.json ]; then npm install; fi

# Rust
if [ -f Cargo.toml ]; then cargo build; fi

# Python
if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
if [ -f pyproject.toml ]; then poetry install; fi

# Go
if [ -f go.mod ]; then go mod download; fi
```

## Step 3: Verify Clean Baseline

Run tests to ensure workspace starts clean:

```bash
# Use project-appropriate command
npm test / cargo test / pytest / go test ./...
```

**If tests fail:** Report failures, ask whether to proceed or investigate.

**If tests pass:** Report ready.

### Report

```
Worktree ready at <full-path>
Tests passing (<N> tests, 0 failures)
Ready to implement <feature-name>
```

## Quick Reference

| Situation                              | Action                                                 |
| -------------------------------------- | ------------------------------------------------------ |
| Already in linked worktree             | Skip creation (Step 0)                                 |
| In a submodule                         | Treat as normal repo (Step 0 guard)                    |
| Native worktree tool available         | Use it (Step 1a)                                       |
| No native tool                         | Git worktree fallback (Step 1b)                        |
| Worktree creation approved             | Original worktree becomes read-only                    |
| No external location specified         | Use a sibling directory outside the project            |
| Requested location is inside original  | Ask for an external location; do not edit `.gitignore` |
| Worktree creation fails                | Stop; do not work in place                             |
| Original state changed during creation | Stop and report; do not repair automatically           |
| Tests fail during baseline             | Report failures + ask                                  |
| No package.json/Cargo.toml             | Skip dependency install                                |

## Common Rationalizations

| Excuse                                                              | Reality                                                                                                                                                                  |
| ------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| "I'm obviously not in a worktree — no need to check"                | Run Step 0. Harness-created isolation and submodules both fool eyeballing; the detection commands settle it.                                                             |
| "`git worktree add` is quicker than hunting for a native tool"      | A native tool (e.g. `EnterWorktree`) owns placement, branching, and cleanup. Bypassing it is the #1 mistake — it creates phantom state your harness can't see or manage. |
| "Adding `.worktrees` to `.gitignore` is harmless setup"             | It mutates the checkout and may require a commit on the branch that isolation is meant to protect. Use an external directory.                                            |
| "The sandbox blocked creation, so working in place is close enough" | The user chose isolation. Stop and report instead of silently abandoning it.                                                                                             |
| "The original changes were pre-existing, so a reset is safe"        | Preserve the recorded state exactly. Never repair or clean the user's original worktree automatically.                                                                   |
| "The workspace is fresh — baseline tests can wait"                  | A dirty baseline makes every later failure ambiguous. Run the tests now; proceeding past failures is your human partner's call.                                          |
