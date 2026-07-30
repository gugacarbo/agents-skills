# scripts KNOWLEDGE BASE

**Generated:** 2026-06-11 09:55:28 -0300
**Commit:** 1e1ebb6

## OVERVIEW

`src` contains the real command implementations behind `skills.sh`. Production scripts are POSIX `sh`; root-level tests use `bun:test` with TypeScript integration/smoke cases that exercise local installs, remote bootstrap tarballs, prompts, and git allowlist behavior.

## WHERE TO LOOK

| Task                      | Location                                                | Notes                                                                                    |
| ------------------------- | ------------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| Install destination rules | `src/install.sh`                                        | Handles `--path`, `--global`, cwd named `skills`, global fallback, and prompts.          |
| Clone/merge install mode  | `install.sh`                                            | `--init` clones repo; non-empty destinations merge without overwriting.                  |
| README copy option        | `install.sh`                                            | `--instructions` preserves existing target README.                                       |
| Update comparison         | `update.sh`                                             | Downloads archive, compares remote files to local target, then prompts before overwrite. |
| Curl bootstrap coverage   | `src/tests/bootstrap.test.ts`                           | Pipes root `skills.sh` into `sh -s -- install/update`.                                   |
| Prompt edge cases         | `src/tests/install.test.ts`, `src/tests/update.test.ts` | Use `AGENTS_SKILLS_PROMPT_INPUT` with stdin redirected.                                  |

## CONVENTIONS

- Runtime scripts use `#!/usr/bin/env sh` plus `set -eu`; avoid Bash arrays, `[[ ]]`, and process substitution there.
- Tests use `bun:test` and the shared helpers in `src/tests/helpers.ts`.
- Fixtures should use `makeTempDir`; fake skills need a `SKILL.md`.
- Remote behavior is tested with local `file://` git repos or tar archives.
- Confirmation tests should cover both interactive decline/accept and `--yes`.
- Subprocess helpers default `AGENTS_SKILLS_PROMPT_INPUT` to `/dev/null`; prompt cases must provide an explicit fixture file so tests never read the developer's `/dev/tty`.
- Bootstrap tests must guard against loops when a command is missing from the downloaded archive.
- The watcher test prepends a fast fake `sleep` to `PATH` and writes subprocess output to files; piping output can keep the test alive until an inherited child closes the pipe.
- Run root integration tests via `bun test src/tests/<name>.test.ts`; run the complete suite via `bun run test`.

## ANTI-PATTERNS

- Do not rely on stdin for prompts in scripts reachable through `curl | sh`.
- Do not overwrite user files in `--init` non-empty destinations.
- Do not remove local extra files during `update`; current behavior copies remote files over the target without pruning extras.
- Do not add production-only behavior without a matching test script case.
- Do not assume a root `install.sh` exists; stale references should be cleaned when touched.

## COMMANDS

```sh
bun test src/tests/install.test.ts
bun test src/tests/update.test.ts
bun test src/tests/bootstrap.test.ts
bun test src/tests/gitignore.test.ts
bun test src/tests/orchestrator.test.ts
rtk sh -n skills.sh src/install.sh src/update.sh
```
