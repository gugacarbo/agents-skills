# TypeScript + Node — Requirements

> All packages are installed via CLI at their latest stable version. No pinned versions.

## Runtime

- Node.js (LTS)
- Package manager: pnpm (mandatory)

## Core Dependencies

| Package     | Purpose                  | Install                   |
| ----------- | ------------------------ | ------------------------- |
| typescript  | TypeScript compiler      | `pnpm add -D typescript`  |
| @types/node | Node.js type definitions | `pnpm add -D @types/node` |

## Dev Dependencies

| Package | Purpose                                   | Install              |
| ------- | ----------------------------------------- | -------------------- |
| vitest  | Test runner                               | `pnpm add -D vitest` |
| biome   | Linter + formatter (unified)              | `pnpm add -D biome`  |
| tsx     | Run TS files directly (dev)               | `pnpm add -D tsx`    |
| knip    | Dead code and unused dependency detection | `pnpm add -D knip`   |
| husky   | Git hooks (pre-commit, pre-push)          | `pnpm add -D husky`  |

## Install all at once

```sh
pnpm add -D typescript @types/node vitest biome tsx knip husky
pnpm exec husky init
```

## Git Hooks (Husky)

- **pre-commit**: `pnpm lint && pnpm typecheck`
- **pre-push**: `pnpm test`

## CI Requirements

- Type checking: `tsc --noEmit`
- Tests: `vitest run`
- Lint: `biome check`
- Dead code: `knip`
- All must pass on PR/merge
