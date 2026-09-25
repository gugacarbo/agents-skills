---
name: creating-pr
description: >
  Use this skill whenever an agent needs to prepare, create, or open a Pull Request.
  It defines a safe workflow for isolating the intended work, protecting unrelated
  WIP, validating the implementation, reviewing the complete diff, and publishing
  a clean and reviewable PR.
---

# Creating Pull Requests

Create focused PRs without disturbing unrelated work. Never publish unrelated
changes; use a dedicated branch, validate the implementation, review the complete
diff, and inspect the remote PR and CI after creation.

## 1. Inspect repository and task

Before changing Git state, inspect:

```bash
git status --short --branch
git branch --show-current
git worktree list
git remote -v
```

Identify the actual default/base branch; do not assume `main`. When GitHub CLI is
available, also run:

```bash
gh repo view --json defaultBranchRef
gh pr status
```

Read applicable repository guidance: `AGENTS.md`, `CONTRIBUTING.md`, `README.md`,
`.github/`, repository-local skills, planning/specification documents, and
relevant issue or PR discussions. These instructions take precedence over this
skill's examples.

Establish the intended scope from the request, issue, specification, plan, or
acceptance criteria. A PR should normally contain one coherent change. Leave out
unrelated refactors, formatting, dependency upgrades, generated changes, cleanup,
and incidental fixes unless required; suggest a separate issue or PR for them.

## 2. Protect WIP and choose where to work

Treat unknown modifications as important WIP. Never automatically run:

```bash
git reset --hard
git clean -fd
git clean -fdx
git checkout -- .
git restore .
git stash
```

Do not discard, overwrite, commit, move, or include unrelated work. Prefer
reversible operations and inspect unexpected files before acting.

- **Task branch, no unrelated WIP:** continue in the current worktree if the
  branch clearly belongs to this task and all changes are in scope.
- **Shared/base branch, clean worktree:** do not implement on `main`, `master`,
  `develop`, or another shared branch. Create a task branch from the current base:

  ```bash
  git fetch origin
  git switch <base>
  git pull --ff-only
  git switch -c <branch>
  ```

- **Unrelated WIP or uncertain ownership:** leave the current worktree untouched;
  fetch and create an isolated worktree from `origin/<base>`:

  ```bash
  git fetch origin
  git worktree add ../<repo>-<task> -b <branch> origin/<base>
  ```

  Do the task there. When uncertain whether the current worktree is safe, prefer
  isolation.

Use the repository's branch naming convention. Otherwise choose a descriptive,
task-specific name (for example, `feat/remote-browser-sync`, `fix/multi-chat-activity`,
`refactor/process-manager`, `docs/creating-pr-skill`); avoid vague names such as
`changes`, `fix`, `test`, `temp`, or `wip`.

Inspect `git status --short`, `git diff`, and `git diff --stat` periodically.
Investigate unexpected lockfiles, generated files, snapshots, migrations, IDE or
environment files, debug artifacts, build outputs, and formatting churn. Do not
remove them blindly.

## 3. Validate the implementation

Use commands defined by repository guidance, package scripts, task runners, and CI;
do not guess. Run meaningful checks during development and all relevant checks
before publishing (such as tests, lint, typecheck, build, format, integration, or
end-to-end checks). Never claim a check passed unless it ran successfully. If a
relevant check cannot run, disclose that in the PR.

## 4. Review exactly what the PR contains

This review is mandatory. Refresh the remote base, then inspect the full range and
all commits:

```bash
git fetch origin
git diff --stat origin/<base>...HEAD
git diff --name-status origin/<base>...HEAD
git diff origin/<base>...HEAD
git log --oneline origin/<base>..HEAD
```

Also inspect uncommitted work when present:

```bash
git diff
git diff --cached
```

The diff, not memory of edited files, defines the PR. Verify that every changed
file and commit belongs to the task. Investigate unexpected files, commits, large
diffs, formatting churn, lockfiles, generated outputs, snapshots, migrations, and
dependency changes. Confirm such changes are required, intentional, produced by
the right tooling, and expected to be committed. A surprisingly large diff is a
reason to stop and investigate.

Inspect relevant changed files for residue such as `TODO`, `FIXME`, `HACK`, `XXX`,
`console.log`, `debugger`, temporary comments, commented-out code, local paths,
localhost-only assumptions, and temporary feature flags. These are signals to
inspect, not automatic deletion instructions.

Never publish API keys, passwords, tokens, cookies, session identifiers, private
keys, certificates, or `.env` secrets. Use the repository's secret scanner when
available. If a secret entered Git history, deleting it from the current file is
not enough; surface the issue before publishing.

Check that the branch contains no commits from another task, agent, old branch, or
experimental work. Do not rewrite commits authored by others unless necessary,
safe, and explicitly appropriate.

Before publishing, fetch again and check whether the base changed materially. Do
not automatically rebase shared branches or rewrite history. Rebasing may be
appropriate on a private task branch when safe; after conflict resolution or
history changes, rerun relevant validation and review the PR diff again. Never
force-push by default. If rewriting a private branch genuinely requires a force
push, use `git push --force-with-lease`, not `git push --force`.

Immediately before pushing, confirm repository state, commits, changed-file list,
stat, and complete diff using the commands above. Passing tests does not prove the
PR is clean: verify both that the implementation works and that the PR contains
only the intended work.

## 5. Push and create the PR

Push only the dedicated task branch:

```bash
git push -u origin <branch>
```

Prefer GitHub CLI when available:

```bash
gh pr create
```

Use the repository's PR template. Otherwise, structure the description around
these sections, omitting any that add no useful information:

```markdown
## Summary

- What changed

## Why

Why the change is needed.

## Implementation

- Important implementation details

## Validation

- Tests/checks actually executed

## Review notes

Anything reviewers should pay special attention to.

Closes #123
```

Never claim unperformed validation.

Use a concise title that describes the actual change and follows repository
conventions (for example, `fix: isolate activity state between concurrent chats`,
`feat: add remote browser synchronization`, or `docs: add PR creation workflow`).
Avoid vague titles such as `Fix`, `Changes`, `Updates`, or `Various improvements`.

Use a closing keyword (`Closes #123`, `Fixes #123`, `Resolves #123`) only if merging
the PR should close that issue; otherwise say `Related to #123` or `Part of #123`.
Use a draft when the PR is intentionally incomplete or early review is desired. A
draft is not permission to publish unrelated or unsafe changes.

## 6. Verify the remote PR and CI

Creation is not completion. When available, inspect:

```bash
gh pr view
gh pr diff
gh pr checks
```

Verify title, description, base/head branches, changed files, commits, complete
remote diff, unexpected files or diff size, and CI status. The remote PR diff is
the final source of truth.

If CI fails, inspect the failing job and determine whether the PR caused it. Fix
the underlying problem when appropriate, rerun relevant validation, push the
correction, and verify the PR again. Do not repeatedly rerun a failure without
understanding it.

## 7. Worktree cleanup

Keep an isolated worktree while its work may still be needed. Once the PR is
merged, abandoned, or the worktree is confirmed unnecessary, it may be removed:

```bash
git worktree remove ../<worktree>
git worktree prune
```

Never remove a worktree with uncommitted changes without explicit approval.

## Completion checklist

The PR is complete when all applicable items are true:

- [ ] Repository state, base branch, existing worktrees, and WIP were inspected.
- [ ] Unrelated work remains untouched; the dedicated branch contains one coherent task scope.
- [ ] A separate worktree was used when appropriate; local instructions were followed.
- [ ] Relevant validation passed, or failures and unavailable checks are disclosed truthfully.
- [ ] Complete `origin/<base>...HEAD` diff, changed-file list, commits, and sensitive-data/residue checks were reviewed.
- [ ] Unexpected dependency, generated, migration, snapshot, or formatting changes were investigated.
- [ ] The branch was pushed safely; PR description, base/head, and remote diff were verified.
- [ ] CI was checked when available, and failures were handled as above.

A PR URL alone is not sufficient: the intended changes must be isolated, unrelated
WIP protected, the diff reviewed, validation reported honestly, and the remote PR
and CI checked.
