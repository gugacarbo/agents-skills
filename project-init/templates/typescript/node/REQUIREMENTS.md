# TypeScript + Node — Requirements

## Runtime

- Node.js 22+ (LTS)
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
| tsx     | ^4      | Run TS files directly (dev)    |
| knip    | ^5      | Dead code and unused dependency detection |
| husky   | ^9      | Git hooks (pre-commit, pre-push) |

## Git Hooks (Husky)

- **pre-commit**: `pnpm lint && pnpm typecheck`
- **pre-push**: `pnpm test`

## CI Requirements

- Type checking: `tsc --noEmit`
- Tests: `vitest run`
- Lint: `biome check`
- Dead code: `knip`
- All must pass on PR/merge
