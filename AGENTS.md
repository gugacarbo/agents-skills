# PROJECT KNOWLEDGE BASE

**Generated:** 2026-07-13 12:00:00 -0300
**Commit:** (pending)

## OVERVIEW

This repo is a small skills bundle plus a public `skills.sh` orchestrator for installing and updating skills from `gugacarbo/agents-skills`. Runtime code is shell-first: root orchestration in POSIX `sh`, command implementations in `.scripts/`, and standalone Bash integration tests.

## STRUCTURE

```
.
├── skills.sh              # public entrypoint; also supports curl | sh bootstrap
├── .scripts/              # install/update command implementations and tests
└── skills/                # source of every installable skill
    ├── commit-changes/    # conventional-commit workflow and flowchart
    ├── find-docs/         # documentation retrieval skill
    ├── init-deep/         # hierarchical AGENTS.md generator
    ├── project-init/      # layered convention templates
    ├── skill-master/      # skill authoring and evaluation tooling
    ├── super-planning/    # planning/orchestration skill
    │   ├── docs/          # workflows, decision flow, examples
    │   ├── scripts/       # super-plan.sh and task helpers
    │   ├── phases/        # phase guidance (01–08)
    │   ├── prompts/       # worker and implementer prompts
    │   ├── templates/     # plan and tasks templates
    │   └── dev/           # tests and auxiliary scripts
    └── task-completion-notifier/ # completion notification runtime and tests
```

## WHERE TO LOOK

| Task                          | Location                                    | Notes                                                            |
| ----------------------------- | ------------------------------------------- | ---------------------------------------------------------------- |
| Add a public command          | `skills.sh` + `.scripts/<command>.sh`       | Root script delegates by command name.                           |
| Change generated skill output | `.scripts/build.sh` + `dist/skills/`        | The output is versioned and is the install source.               |
| Change live publishing        | `.scripts/dev.sh`                           | Prompts for a target, rebuilds, then publishes on source changes. |
| Change install behavior       | `.scripts/install.sh`                       | Tests live in `.scripts/tests/install.sh`.                       |
| Change update behavior        | `.scripts/update.sh`                        | Tests live in `.scripts/tests/update.sh` and bootstrap coverage. |
| Validate curl bootstrap       | `.scripts/tests/bootstrap.sh`               | Uses local tarballs and `sh -s -- <command>`.                    |
| Validate git allowlist        | `.gitignore`, `.scripts/tests/gitignore.sh` | The repo ignores everything by default.                          |
| Work on commit skill content  | `skills/commit-changes/SKILL.md`            | Conventional-commit workflow skill.                              |
| Work on commit flowchart      | `skills/commit-changes/README.md`           | Mermaid flowchart for commit decision flow.                      |
| Work on planning skill content | `skills/super-planning/`                  | Phase docs, prompts, templates, and orchestration helpers.       |
| Work on planning reference     | `skills/super-planning/docs/`             | Workflows, decision flow, file structure, and examples.          |
| Work on planning scripts       | `skills/super-planning/scripts/`          | super-plan.sh, bootstrap.sh, doctor.sh, log-task.sh, render-progress-ledger.sh, summarize-all-tasks.sh. |
| Test planning scripts          | `skills/super-planning/dev/tests.sh`      | Integration tests for super-plan.sh, render-progress-ledger.sh, log-task.sh, summarize-all-tasks.sh. |
| Work on planning dev tooling   | `skills/super-planning/dev/`              | Tests and auxiliary scripts for the super-planning skill. |
| Work on init-deep skill       | `skills/init-deep/SKILL.md`                 | Unified skill with --light flag for telegraphic mode.            |
| Work on documentation retrieval | `skills/find-docs/SKILL.md`              | Current library and service documentation lookup workflow.       |
| Work on skill authoring       | `skills/skill-master/`                      | Authoring, evaluation, and discipline references plus dev tests. |
| Work on completion notifier  | `skills/task-completion-notifier/`          | Python runtime (`notify.py`, `session-state.py`, `hook-dispatch.py`), installer, templates, and runtime tests. |
| Work on documentation lookup guidance | `skills/super-planning/prompts/find-docs.md` | Phase 3 lookup workflow for new or version-sensitive libraries. |

## CONVENTIONS

- Prefix shell commands with `rtk` in this workspace.
- Keep runtime scripts POSIX-compatible: `#!/usr/bin/env sh` and `set -eu`.
- Keep tests as Bash scripts: `#!/usr/bin/env bash` and `set -euo pipefail`.
- Run tests through `bash`; do not assume every file under `.scripts/tests/` is executable.
- Public commands should be reachable as `./skills.sh <command>` and through `curl .../skills.sh | sh -s -- <command>`.
- Default remote is `gugacarbo/agents-skills` on `main`; keep env overrides working: `AGENTS_SKILLS_OWNER`, `AGENTS_SKILLS_REPO`, `AGENTS_SKILLS_REF`, `AGENTS_SKILLS_REPO_URL`, `AGENTS_SKILLS_ARCHIVE_URL`.
- Installable skills are direct children of `skills/` containing `SKILL.md`; `build.sh` copies them to versioned `dist/skills/`, which the installer reads.
- `.gitignore` is allowlist-only. New files are ignored unless explicitly unignored.

## ANTI-PATTERNS (THIS PROJECT)

- Do not add a root `install.sh`; `skills.sh install` is the public path.
- Do not make global install skip confirmation just because `--yes` was passed.
- Do not read prompts only from stdin; `curl | sh` requires prompt reads from `/dev/tty` or the test seam `AGENTS_SKILLS_PROMPT_INPUT`.
- Do not use `git add .` casually here; ignored local skill directories and unrelated skill edits may exist.
- Do not convert runtime scripts to Bash unless POSIX portability is intentionally dropped.
- Treat `rm -rf` as cleanup-only and keep it bound to temp dirs or fixtures.

## COMMANDS

```sh
rtk bash .scripts/tests/install.sh
rtk bash .scripts/tests/update.sh
rtk bash .scripts/tests/bootstrap.sh
rtk bash .scripts/tests/build.sh
rtk bash .scripts/tests/dev.sh
rtk bash .scripts/tests/gitignore.sh
rtk bash .scripts/tests/orchestrator.sh
rtk bash skills/super-planning/dev/tests.sh
rtk sh -n skills.sh .scripts/build.sh .scripts/dev.sh .scripts/install.sh .scripts/update.sh
```

Full local test loop:

```sh
rtk bash -lc 'for test_script in .scripts/tests/*.sh; do bash "$test_script"; done'
```
