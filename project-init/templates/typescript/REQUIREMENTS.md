# TypeScript Template — Requirements

## Runtime

- Node.js 22+ (LTS) or Bun 1.x or Deno 2.x
- Package manager: pnpm (mandatory)

## Core Dependencies

| Package     | Version | Purpose                  |
| ----------- | ------- | ------------------------ |
| typescript  | ^5.7    | TypeScript compiler      |
| @types/node | ^22     | Node.js type definitions |

## Dev Dependencies

| Package | Version | Purpose                        |
| ------- | ------- | ------------------------------ |
| vitest  | ^3      | Test runner                    |
| biome   | ^1.9    | Linter + formatter (unified)   |
| knip    | ^5      | Dead code and unused dependency detection |
| husky   | ^9      | Git hooks (pre-commit, pre-push) |

## Recommended Tools

| Tool    | Purpose                         |
| ------- | ------------------------------- |
| tsc CLI | Type checking (`tsc --noEmit`) |
| tsx     | Run TS files directly in dev    |

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
