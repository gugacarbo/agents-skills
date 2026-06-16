---
name: commit-changes
description: Create git commits from working tree changes with Conventional Commits messages. Use this whenever the user explicitly wants to commit changes, stage and commit, save code changes to git, or wants help naming, splitting, or scoping a commit. Treat an explicit commit request as approval to execute the commit flow without an extra confirmation prompt, but do not use this for git history questions, rebases, squashes, cherry-picks, reverts, or non-git uses of the word "commit."
compatibility: Requires git CLI and bash tool
---

# Commit Changes

Use this skill when the user clearly wants git commit work done, not when they only want git advice.

## Core Stance

- Treat an explicit commit request as permission to commit. Show the plan, then execute unless you hit a real risk or ambiguity.
- Split unrelated work into separate commits when the separation is clear and safe.
- Keep implementation and its tests together.
- Respect the user's scope when they name files or directories.
- When no path is named, infer the narrowest safe scope from the current conversation before considering the whole worktree.
- Do not discard, reset, or revert user changes to make the commit easier.
- Do not create sidecar files inside the user's repo unless the task itself requires them.

## Delegation Preference

- Prefer dispatching a subagent for the preparatory parts of this skill when that capability is available.
- When the platform allows it, prefer a model that is cheaper or weaker than the main agent for that subagent run.
- When the platform allows it, prefer `reasoning effort: low` by default and increase only to `medium` when the diff is ambiguous, the commit grouping is unclear, or hook failures need more careful analysis.
- Avoid `reasoning effort: high` by default for this skill unless the user explicitly asks for deeper analysis or the available options make that unavoidable.
- Good subagent tasks include inspecting the working tree, proposing commit groups, drafting Conventional Commit messages, and identifying likely `AGENTS.md` updates.
- If no subagent is available, no model or effort controls exist, or the task requires especially careful local git state handling, continue inline without blocking on delegation.
- Keep final staging, `git commit`, and post-commit verification sequential and preferably in the main agent so the write path stays easy to audit.

## Do Not Use

Do not load this skill for:

- `git log`, `git show`, history, blame, or branch-inspection questions
- rebases, squashes, cherry-picks, or reverts
- merge-conflict resolution without a commit request
- database transactions or other non-git meanings of "commit"
- purely educational questions like "what is Conventional Commits?"

## Workflow

### 1. Parse Intent and Scope

Extract four things from the user's request and recent conversation:

1. Whether they are explicitly asking to create a commit
2. Whether they scoped the commit to specific paths
3. Whether they opted into the entire worktree with scope phrases like `all`, `--all`, `everything`, `tudo`, or `worktree inteira`
4. Whether they opted out of AGENTS updates with phrases like `skip AGENTS.md`, `don't update AGENTS.md`, or `commit only`

Path examples:

- `commit src/auth/`
- `commit package.json README.md`
- `commit only src/routes/api.ts`

If the user names paths, commit only those paths. If a path does not exist or has no changes, stop and say so.

If the user does not name paths but the conversation history points to a specific execution, fix, test run, generated output, or task you just performed, treat that as the commit scope. Commit only files plausibly related to that execution, and leave unrelated worktree changes untouched. The whole worktree is only the default when the user explicitly asks for all changes or when inspection shows every changed file belongs to the same requested concern.

Treat `all`, `--all`, `everything`, `todos`, `tudo`, `worktree inteira`, and similar wording as an explicit request to consider every changed file in the worktree only when they are used as the commit scope. Casual phrases like `all tests pass` or `ta tudo certo, commit` are not whole-worktree requests. Even then, still split unrelated concerns into separate commits when the boundaries are clear.

### 2. Inspect the Working Tree

Always inspect the current state before composing a commit plan.

Run:

```bash
git status --short
git diff --stat HEAD
git diff HEAD -- <scope paths if provided>
```

Also check staged changes when needed:

```bash
git diff --cached -- <scope paths if provided>
```

When scope is inferred from conversation history, first list all changed files, then inspect only the candidate files related to that execution. Do not expand to unrelated files merely because they are present in `git status`.

Before going further, stop and escalate if you find:

- merge conflicts
- an in-progress rebase, cherry-pick, or merge that changes the expected flow
- no changes to commit in the requested scope

### 3. Decide Commit Groups

Group changes by logical concern, not by file count.

Good reasons to keep changes together:

- feature code plus tests for that feature
- a bug fix plus the small refactor required to make the fix work
- implementation plus the docs that are inseparable to use it

Good reasons to split:

- unrelated features
- docs-only work mixed with runtime code
- refactor-only changes mixed with behavior changes
- styling changes mixed with API or data changes

Prefer file-boundary splits. If unrelated work is mixed inside the same file and would require hunk staging or semantic judgment, stop and tell the user exactly why the split is unsafe.
If the groups are already cleanly separated by file paths, keep them as separate commits rather than collapsing them for convenience.

Use this pattern:

```text
src/auth/login.ts           + tests/auth/login.test.ts   -> one auth commit
src/ui/button.css                                      -> separate UI commit
README.md                                               -> separate docs commit
```

### 4. Build the Commit Message

Use Conventional Commits:

```text
<type>(<scope>): <subject>

[optional body]
```

Choose the smallest honest type:

| Type | Use for |
| --- | --- |
| `feat` | new user-facing or developer-facing behavior |
| `fix` | bug fixes |
| `refactor` | structure changes without behavior change |
| `docs` | documentation-only changes |
| `test` | tests added or updated without product code changes |
| `style` | formatting or styling with no logic change |
| `chore` | maintenance, config, tooling, dependencies |
| `perf` | measurable performance improvements |
| `build` | CI, build, release, packaging changes |

Scope should usually come from the touched area, for example `auth`, `api`, `ui`, `deps`, or `ci`. Use no scope only when a scope would be fake or less clear than the unsuffixed message.

Subject rules:

- imperative mood: `add`, `fix`, `update`, `remove`
- describe what changed, not the entire implementation story
- no trailing period
- keep it short enough to scan comfortably

Add a body only when it helps explain why the change exists, why it was split this way, or what important constraint it handles.

Good examples:

```text
feat(auth): add token refresh flow
fix(api): handle missing user avatar
docs: update local setup steps
chore(deps): upgrade vitest
```

Bad examples:

```text
fix: stuff
feat(auth): Added new things
update files
```

### 5. Check AGENTS.md Impact

By default, keep AGENTS documentation in sync when the diff changes how future agents should work. Skip this only when the user explicitly asks to skip it.

Look for changes that usually belong in AGENTS:

- new commands in `package.json`, `Makefile`, or scripts
- new feature folders or important new modules
- new conventions, heuristics, or standard workflows
- new env vars or operational setup rules
- new routes, generated-code locations, or reference patterns

Target the nearest relevant `AGENTS.md`, not always the repo root.

When editing AGENTS files:

1. Read the file first
2. Update only the generated section that matches the change
3. Preserve markers and structure
4. Update the timestamp if the file uses one
5. Stage the AGENTS change with the related commit when practical

If a new feature-level `AGENTS.md` is clearly needed and there is no local one, use `feature-agents-md` if available. Otherwise create the smallest useful file rather than inventing a large policy document.

If the diff does not teach future agents anything new, explicitly note that no AGENTS update is needed and continue.

### 6. Present the Execution Plan

Before committing, show a concise plan. Do not ask for a redundant yes/no confirmation unless there is real risk.

Use a format like:

```text
## Commits to Execute (2)

### Commit 1/2
Files: src/auth/login.ts, tests/auth/login.test.ts
Message: feat(auth): add token refresh flow
AGENTS: none

### Commit 2/2
Files: README.md
Message: docs: update token refresh setup
AGENTS: update root Commands table
```

Only pause instead of executing when:

- the grouping is ambiguous
- the user's requested scope conflicts with the current staged state
- the split requires `git add -p` or another risky partial-staging choice
- a required fix would change behavior in a way you cannot justify confidently

### 7. Execute the Plan

For each planned commit:

1. Stage only the files for that commit
2. Include AGENTS updates in the same commit when they belong with it
3. Create the commit
4. Verify the commit landed as expected before moving to the next one
5. Refresh `git status --short` before staging the next group

Typical commands:

```bash
git add <files>
git commit -m "<type>(<scope>): <subject>"
git show --stat --oneline HEAD~0
```

If the commit needs a body:

```bash
git commit -m "<type>(<scope>): <subject>" -m "<body>"
```

Respect intentional staging when it already expresses the grouping cleanly. Do not blindly `git add .` unless the user explicitly requested all worktree changes and the diff makes that the correct scope.
Execute multi-commit plans strictly sequentially. Never overlap `git add` or `git commit` commands, never background them, and never prepare the next commit until the previous one is fully complete and verified.
Even when earlier analysis was delegated, keep this final write path in the main agent unless the user explicitly wants a different execution model.

### 8. Handle Hook Failures Carefully

If a hook or commit-time check fails:

1. Read the error
2. Fix deterministic issues directly
3. Re-run the smallest relevant verification
4. Retry the commit

Safe auto-fix examples:

- formatting
- import order
- unused imports or variables when the fix is obvious
- straightforward type annotations or missing exports

Pause and ask the user when the failure implies a product decision, API contract choice, or a non-obvious refactor.

Never solve hook failures by discarding changes with commands like:

- `git checkout -- ...`
- `git reset --hard`
- any other destructive revert of user work

## Edge Cases

### Path-Scoped Requests

- If the path exists but has no changes, stop with `No changes found in "<path>".`
- If the path is valid, keep both analysis and staging inside that scope
- If the user names multiple paths, commit only those paths

### Conversation-Scoped Requests

- If the user says only `commit`, `commit this`, `commit the fix`, `commita isso`, or similar after a specific implementation or command run, infer the scope from that recent work instead of committing the whole worktree
- If unrelated modified files exist outside that inferred scope, mention they were left untouched
- If the recent execution touched mixed concerns and the correct scope is not clear from file boundaries, pause and explain the ambiguity

### Whole-Worktree Requests

- If the user uses `all`, `--all`, `everything`, `todos`, `tudo`, `worktree inteira`, or similar as the commit scope, consider every changed file in the worktree
- `--all` authorizes considering every changed file, but it does not authorize destructive cleanup or collapsing unrelated work into one commit

### Mixed Staged and Unstaged State

- If staged files already represent a clean commit boundary, prefer respecting that grouping
- If staged and unstaged changes are interleaved in the same file and the correct split is unclear, pause and explain the ambiguity

### Large or Noisy Diffs

If the request would produce a very large commit, call that out and suggest the split you intend to make. The goal is to help the user land reviewable commits, not to maximize automation at the expense of clarity.

## Examples

### Example 1: Straightforward scoped commit

User: `commit only src/api/user.ts tests/api/user.test.ts`

Response plan:

```text
## Commits to Execute (1)

### Commit 1/1
Files: src/api/user.ts, tests/api/user.test.ts
Message: fix(api): handle missing user avatar
AGENTS: none
```

Then execute the commit without asking an extra confirmation question.

### Example 2: Split unrelated work

User: `commit my changes`

Diff contains auth work, button styling, and README edits, and the recent conversation was about all of those changes.

Response plan:

```text
## Commits to Execute (3)

### Commit 1/3
Files: src/auth/*, tests/auth/*
Message: feat(auth): add token refresh flow

### Commit 2/3
Files: src/ui/button.css
Message: style(ui): adjust button hover states

### Commit 3/3
Files: README.md
Message: docs: update auth setup guide
```

### Example 3: Conversation-scoped commit

User: `commit`

Recent conversation was an execution that updated only `commit-changes/SKILL.md`. The worktree also contains unrelated local edits in `skill-creator/`.

Response plan:

```text
## Commits to Execute (1)

### Commit 1/1
Files: commit-changes/SKILL.md
Message: docs(commit-changes): narrow default commit scope
AGENTS: none

Left untouched: skill-creator/
```

### Example 4: Ambiguous mixed file

User: `commit my changes`

One file contains both a bug fix and an unrelated cleanup that would need hunk staging.

Do not pretend the split is obvious. Explain that the file mixes concerns and suggest either:

- committing it as one honest commit, or
- using `git add -p` with user guidance if they want separate history

### Example 5: AGENTS update needed

User: `commit payments feature`

Diff adds `src/features/payments/` and a new `pnpm payments:report` script.

Plan should mention both the feature commit and the AGENTS updates that keep future agents aware of the new command and feature area.

## Success Criteria

The skill is doing its job when it helps the agent:

- commit the right files
- choose clear commit boundaries
- write a strong Conventional Commit message
- keep AGENTS documentation aligned when warranted
- avoid destructive git behavior under pressure
