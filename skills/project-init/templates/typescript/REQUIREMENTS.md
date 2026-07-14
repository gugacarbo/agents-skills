# TypeScript Template — Requirements

> All packages are installed via CLI at their latest stable version. No pinned versions.

## Runtime

- Node.js (LTS) or Bun or Deno
- Package manager: pnpm (mandatory)

## Env contract

- Create a single environment module such as `src/env.ts` and keep raw environment reads there.
- Validate required variables before the app starts serving requests, jobs, or CLI work.
- Export a typed env object to the rest of the codebase instead of passing unvalidated strings around.
- For larger apps or stricter schemas, prefer adding `@t3-oss/env-core` through the optional tools flow.

## Scripts contract

- Required scripts after initialization: `dev`, `build`, `test`, `lint`, `format`, `typecheck`, `knip`.
- Add `prepare` when Husky is enabled so git hooks install on dependency setup.
- Derivatives may add runtime-specific scripts such as `start`, `preview`, or `test:watch`, but they should preserve the required baseline script names above.

## Core Dependencies

| Package    | Purpose             | Install                  |
| ---------- | ------------------- | ------------------------ |
| typescript | TypeScript compiler | `pnpm add -D typescript` |

## Dev Dependencies

| Package | Purpose                                   | Install              |
| ------- | ----------------------------------------- | -------------------- |
| vitest  | Test runner                               | `pnpm add -D vitest` |
| biome   | Linter + formatter (unified)              | `pnpm add -D biome`  |
| knip    | Dead code and unused dependency detection | `pnpm add -D knip`   |
| husky   | Git hooks (pre-commit, pre-push)          | `pnpm add -D husky`  |

## Install all at once

```sh
pnpm add -D typescript vitest biome knip husky
pnpm exec husky init
pnpm biome init
```

## Git Hooks (Husky)

- **pre-commit**: `pnpm lint && pnpm typecheck`
- **pre-push**: `pnpm test`

## Skills (opencode)

- `project-init` — this skill
- `commit-changes` — conventional commits workflow
- `super-planning` — planning multi-step tasks

## Project Structure Convention

```
<project-name>/
├── .agents/              # Custom skills, prompts, agents
├── src/
│   ├── index.ts          # Entry point
│   └── ...
├── tests/
│   └── ...
├── AGENTS.md             # Model guidance (from template)
├── REQUIREMENTS.md       # This file (from template)
├── package.json
├── tsconfig.json
└── README.md
```

## CI Requirements

- Type checking: `tsc --noEmit`
- Tests: `vitest run`
- Lint: `biome check`
- Dead code: `knip`
- All must pass on PR/merge
