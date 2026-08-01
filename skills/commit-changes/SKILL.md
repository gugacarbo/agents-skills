---
name: commit-changes
description: Create Git commits from working-tree changes with Conventional Commits messages. Use when the user explicitly asks to commit, stage and commit, save changes to Git, commit named paths, or help split, scope, or name commits. Do not use for history inspection, rebases, squashes, cherry-picks, reverts, conflict resolution without a commit request, or non-Git meanings of commit.
compatibility: Requires git CLI and bash tool
---

# Commit Changes

Create reviewable commits without absorbing, rewriting, or discarding unrelated
user work.

## Contract

- An explicit commit request authorizes the commit. Show the plan, then execute
  without a redundant confirmation unless a stop condition applies.
- Inspect before staging. Preserve all changes outside the resolved scope.
- Group by logical concern; keep implementation with its tests.
- Stage named files, not broad globs. Use `git add .` only when the user clearly
  requested the entire worktree and every changed file belongs in the plan.
- Never discard, reset, revert, or overwrite user changes to simplify a commit.

## 1. Resolve scope

Apply the first matching rule:

1. Named paths: use only those paths.
2. Explicit whole-worktree wording such as `all`, `--all`, `everything`,
   `todos`, `tudo`, or `worktree inteira`: consider every changed file.
3. A recent implementation or fix in the conversation: use only files related
   to that work.
4. No usable scope: consider the whole worktree.

Casual phrases such as “all tests pass” or “está tudo certo, commit” do not
select the whole worktree.

If a named path is missing or unchanged, stop and report it. Do not expand the
scope to find something else to commit.

## 2. Inspect repository state

Run the focused variants of:

```bash
git status --short
git diff --stat HEAD
git diff HEAD -- <scope>
git diff --cached -- <scope>
```

List all changed files first when scope came from the conversation, then inspect
only plausible candidates.

Stop without changing the index when any of these is true:

- merge conflicts or a merge, rebase, or cherry-pick is in progress;
- the resolved scope has no changes;
- staged files do not match the requested or inferred commit group.

Apply an index gate before presenting the plan: let `S` be all staged paths and
`G` the planned group. If `S - G` is not empty, report the conflict and stop;
run neither `git add` nor `git commit`. A path-limited commit is still forbidden
when it would leave external work staged. Preserve the index exactly and ask
how the user wants to proceed.

## 3. Form commit groups

Keep together:

- implementation and its tests;
- a fix and the small refactor required by it;
- inseparable implementation and usage documentation.

Split clean file-boundary concerns such as unrelated features, docs-only work,
styling, or behavior-neutral refactors.

Do not choose semantic hunks for the user. When unrelated concerns share a file
and separate commits require partial staging, stop even if the user asks you to
decide. Offer either user-driven `git add -p` or one honest combined commit.

## 4. Keep AGENTS.md useful

Read the nearest relevant `AGENTS.md`. Update it with the related commit only
when the diff changes durable agent guidance, such as commands, environment
variables, workflows, important modules, routes, or generated-code locations.
Preserve its structure and markers. If nothing durable changed, record
`AGENTS: none` in the plan.

## 5. Write messages

Use:

```text
<type>(<scope>): <imperative subject>
```

Choose the smallest honest type:

| Type | Meaning |
| --- | --- |
| `feat` | new behavior |
| `fix` | bug fix |
| `refactor` | structure without behavior change |
| `docs` | documentation only |
| `test` | tests without product-code changes |
| `style` | formatting or visual styling without logic change |
| `chore` | maintenance, configuration, or dependencies |
| `perf` | measurable performance improvement |
| `build` | build, CI, release, or packaging |

Use an area such as `auth`, `api`, `ui`, `deps`, or `ci` as scope only when it
adds clarity. Keep the subject short, imperative, and without a trailing period.
Add a body only to explain a material reason or constraint.

## 6. Plan, execute, verify

Present each group before writing:

```text
Commit 1/N
Files: <paths>
Message: <Conventional Commit>
AGENTS: <paths or none>
```

Pause only for a real stop condition: ambiguous grouping, conflicting staging,
semantic partial staging, or a fix that requires an unjustified product choice.

Execute groups strictly one at a time:

```bash
git add <group paths>
git commit -m "<message>"
git show --stat --oneline HEAD
git status --short
```

Refresh status before staging the next group. Respect an existing staged group
only when it exactly matches the plan.

## Failures

If a hook fails, read the error, fix deterministic issues such as formatting,
import order, or obvious unused code, run the smallest relevant verification,
and retry. Pause when the fix needs a product, API, or non-obvious refactor
decision.

Do not use `--no-verify` unless the user explicitly asks to bypass hooks for
that commit and acknowledges the implications. Never bypass hooks merely to
finish the task.

If Git identity is missing, stop. Never invent or configure `user.name` or
`user.email`, even when asked to choose reasonable values. Request the real
values and suggest repository-local configuration:

```bash
git config user.name <name>
git config user.email <email>
```

## Completion report

Report each commit hash and subject, validations or hook results, and any
changed or staged files intentionally left untouched.
