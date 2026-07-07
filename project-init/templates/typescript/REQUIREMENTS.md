# TypeScript Template — Requirements

> All packages are installed via CLI at their latest stable version. No pinned versions.

## Runtime

- Node.js (LTS) or Bun or Deno
- Package manager: pnpm (mandatory)

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
