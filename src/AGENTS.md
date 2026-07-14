# scripts KNOWLEDGE BASE

**Generated:** 2026-06-11 09:55:28 -0300
**Commit:** 1e1ebb6

## OVERVIEW

`src` contains the real command implementations behind `skills.sh`. Production scripts are POSIX `sh`; root-level tests are Bash integration/smoke scripts that exercise local installs, remote bootstrap tarballs, prompts, and git allowlist behavior.

## WHERE TO LOOK

| Task                      | Location                              | Notes                                                                                    |
| ------------------------- | ------------------------------------- | ---------------------------------------------------------------------------------------- |
| Install destination rules | `src/install.sh`                      | Handles `--path`, `--global`, cwd named `skills`, repo-local fallback, and prompts.      |
| Clone/merge install mode  | `install.sh`                          | `--init` clones repo; non-empty destinations merge without overwriting.                  |
| README copy option        | `install.sh`                          | `--instructions` preserves existing target README.                                       |
| Update comparison         | `update.sh`                           | Downloads archive, compares remote files to local target, then prompts before overwrite. |
| Curl bootstrap coverage   | `src/tests/bootstrap.sh`                  | Pipes root `skills.sh` into `sh -s -- install/update`.                                   |
| Prompt edge cases         | `src/tests/install.sh`, `src/tests/update.sh` | Use `AGENTS_SKILLS_PROMPT_INPUT` with stdin redirected.                                  |

## CONVENTIONS

- Runtime scripts use `#!/usr/bin/env sh` plus `set -eu`; avoid Bash arrays, `[[ ]]`, and process substitution there.
- Tests use Bash and local helpers: `fail`, `assert_*`, `run_capture`, `test_*`, `main`.
- Fixtures should live in `mktemp -d`; fake skills need a `SKILL.md`.
- Remote behavior is tested with local `file://` git repos or tar archives.
- Confirmation tests should cover both interactive decline/accept and `--yes`.
- Bootstrap tests must guard against loops when a command is missing from the downloaded archive.
- Run tests via `bash src/tests/<name>.sh` or the loop from root; executable bits are not consistent.

## ANTI-PATTERNS

- Do not rely on stdin for prompts in scripts reachable through `curl | sh`.
- Do not overwrite user files in `--init` non-empty destinations.
- Do not remove local extra files during `update`; current behavior copies remote files over the target without pruning extras.
- Do not add production-only behavior without a matching test script case.
- Do not assume a root `install.sh` exists; stale references should be cleaned when touched.

## COMMANDS

```sh
rtk bash src/tests/install.sh
rtk bash src/tests/update.sh
rtk bash src/tests/bootstrap.sh
rtk bash src/tests/gitignore.sh
rtk bash src/tests/orchestrator.sh
rtk sh -n skills.sh src/install.sh src/update.sh
```
