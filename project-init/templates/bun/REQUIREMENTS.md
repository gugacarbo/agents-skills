# Bun Template — Requirements

## Runtime

- Bun (latest)
- Package manager: bun (built-in, mandatory)

## Core Dependencies

| Package    | Version | Purpose                  |
| ---------- | ------- | ------------------------ |
| typescript | ^5.7    | TypeScript compiler      |
| @types/bun | latest  | Bun type definitions     |

## Dev Dependencies

| Package | Version | Purpose                        |
| ------- | ------- | ------------------------------ |
| biome   | ^1.9    | Linter + formatter (unified)   |
| knip    | ^5      | Dead code and unused dependency detection |
| husky   | ^9      | Git hooks (pre-commit, pre-push) |

## Built-in (Bun — no install needed)

| Tool       | Purpose                    |
| ---------- | -------------------------- |
| bun test   | Test runner                |
| bun build  | Bundler                    |
| bun --watch| Dev mode with hot reload   |

## Git Hooks (Husky)

- **pre-commit**: `bun lint && bun typecheck`
- **pre-push**: `bun test`

## CI Requirements

- Type checking: `bun typecheck`
- Tests: `bun test`
- Lint: `biome check`
- Dead code: `bun knip`
- All must pass on PR/merge
