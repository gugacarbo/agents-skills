# Phase 4.1: Set Up the Implementation Worktree

Run this optional internal phase only after Phase 4 records `worktree.enabled=true`. Complete it before Phase 5 changes the plan to `in_progress` or dispatches implementation.

Create or reuse an isolated workspace without fighting platform-managed Git state.

**Core principle:** Detect existing isolation, honor the approved decision, prefer native worktree tools, and use manual Git worktrees only as a fallback.

Announce when setup begins: "I'm using super-planning Phase 4.1 to set up the approved isolated workspace."

## Inputs from Phase 4

Read these from the approved plan handoff and `super-plan.json`:

- `worktree.enabled=true`;
- `branchStrategy.baseBranch`;
- `branchStrategy.featureBranch`;
- the intended worktree path or repository directory convention, when specified.

Do not ask for worktree consent again. If the recorded decision is missing or ambiguous, return to the required decision gate in [`04-decompose.md`](04-decompose.md).

## 1. Detect Existing Isolation

Run detection before creating or changing branches:

```bash
git_dir=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
git_common=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
superproject=$(git rev-parse --show-superproject-working-tree 2>/dev/null || true)
branch=$(git branch --show-current)
```

- If `git_dir != git_common` and `superproject` is empty, reuse the current linked worktree. Do not create a nested worktree.
- If `superproject` is non-empty, treat the checkout as a submodule rather than as worktree isolation.
- If the current linked worktree is detached, preserve externally managed state unless the recorded branch strategy requires a branch.

Report either the current branch or detached state and the absolute workspace path.

## 2. Choose the Creation Mechanism

Use mechanisms in this order:

1. Use a platform-native worktree or isolation tool when one is available.
2. Use `git worktree add` only when no native mechanism exists.

Native tools own directory placement, lifecycle, and cleanup. Do not create manual worktrees that the platform cannot track.

## 3. Create a Manual Worktree

### Select a directory

Use this priority:

1. explicit user or repository instruction;
2. the path already recorded in `super-plan.json`;
3. existing `.worktrees/` at the repository root;
4. existing `worktrees/` at the repository root;
5. `.worktrees/` at the repository root.

If both project-local directories exist, use `.worktrees/`.

### Verify project-local safety

Before creating a project-local worktree, verify that the selected container directory is ignored:

```bash
git check-ignore -q .worktrees 2>/dev/null || git check-ignore -q worktrees 2>/dev/null
```

If it is not ignored, add the selected directory to `.gitignore` before creating the worktree. Do not commit that change unless the user separately requested a commit.

### Create the workspace

Use `branchStrategy.featureBranch`; do not derive a second branch name.

```bash
path="$location/$branch_name"
git worktree add "$path" -b "$branch_name"
cd "$path"
```

If the branch already exists and is not checked out elsewhere, attach it without `-b`:

```bash
git worktree add "$path" "$branch_name"
```

If Git reports that the branch is already checked out, reuse its existing worktree or ask the user which workspace should own the branch. Never use `--force` to bypass worktree ownership.

If sandbox permissions block creation, report the failure. Continue in place only after the user explicitly changes the recorded worktree decision; otherwise stop before implementation.

## 4. Make the Planning Handoff Available

Before setup or dispatch, verify that the isolated workspace contains the paths recorded in `source.spec`, `source.plan`, and the active `super-plan.json` registry.

If platform-native isolation did not carry uncommitted planning artifacts, synchronize only the orchestrator-owned super-planning artifacts into the isolated workspace. Do not copy unrelated dirty files. Validate the registry again through the active helper after synchronization.

## 5. Set Up the Project

Read repository instructions and use the project's declared setup command. When no command is documented, infer conservatively from manifests:

| Manifest           | Setup                                                                        |
| ------------------ | ---------------------------------------------------------------------------- |
| `package.json`     | Use the package manager identified by the lockfile or `packageManager` field |
| `Cargo.toml`       | `cargo build`                                                                |
| `requirements.txt` | `python -m pip install -r requirements.txt`                                  |
| `pyproject.toml`   | Use the environment manager declared by the project                          |
| `go.mod`           | `go mod download`                                                            |

Do not replace a repository-specific command with a generic installer.

## 6. Verify the Baseline

Run the repository's documented validation command before implementation.

- If it passes, report the command and result.
- If it fails, report the pre-existing failures and ask whether to investigate or proceed.
- If no validation command exists, report that no baseline test was available.

Do not claim the workspace is ready while baseline failures are unresolved or unacknowledged.

## Persist the Result

Update `super-plan.json` through the active helper with the actual workspace result:

```text
worktree.enabled: true
worktree.path: <absolute path>
branchStrategy.baseBranch: <base branch>
branchStrategy.featureBranch: <feature branch or detached>
setup.command: <command or none, record in the plan handoff>
baseline.command: <command or none, record in the plan handoff>
baseline.status: passed|failed|not_available
```

When ready, finish with:

```text
Worktree ready at <absolute-path> on <branch>
Baseline: <command and result>
Ready for Phase 5 implementation of <feature>
```

## Red Flags

Never:

- run this phase without recorded user approval;
- create a nested worktree when already in a linked worktree;
- treat a submodule as worktree isolation;
- use manual `git worktree add` when the platform provides native isolation;
- create a project-local worktree in an unignored directory;
- force a branch that Git reports as checked out elsewhere;
- dispatch before planning artifacts and the registry are available in the isolated workspace;
- proceed past a failing baseline without making the failure visible;
- commit `.gitignore` or other setup changes without commit authorization.
