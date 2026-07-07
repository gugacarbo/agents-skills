# Base Template — Requirements

> These requirements apply to every project scaffolded with `/project-init`.

## Tools

| Tool          | Purpose                                           |
| ------------- | ------------------------------------------------- |
| Git           | Version control                                   |
| EditorConfig  | Consistent editor settings                        |
| CASA Standard | Docs-check, ADRs, CI gate (optional, recommended) |

## Files Scaffolded

| File                 | Purpose                                                                          |
| -------------------- | -------------------------------------------------------------------------------- |
| `.editorconfig`      | Editor settings (spaces, LF)                                                     |
| `.gitignore`         | Common ignores (node, env, OS)                                                   |
| `.husky/pre-commit`  | Delegates to `scripts/pre-commit`                                                |
| `.husky/pre-push`    | Blocks push to main/master, runs changelog, knip, biome, build, typecheck, tests |
| `scripts/pre-commit` | CASA Standard docs-check gate                                                    |
| `AGENTS.md`          | Project conventions for agents                                                   |
