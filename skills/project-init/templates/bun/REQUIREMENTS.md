# Bun Template — Requirements

> All packages are installed via CLI at their latest stable version. No pinned versions.

## Runtime

- Bun (latest stable)
- Package manager: bun (built-in, mandatory)

## Core Dependencies

| Package    | Purpose              | Install                 |
| ---------- | -------------------- | ----------------------- |
| typescript | TypeScript compiler  | `bun add -D typescript` |
| @types/bun | Bun type definitions | `bun add -D @types/bun` |

## Dev Dependencies

| Package | Purpose                                   | Install            |
| ------- | ----------------------------------------- | ------------------ |
| biome   | Linter + formatter (unified)              | `bun add -D biome` |
| knip    | Dead code and unused dependency detection | `bun add -D knip`  |
| husky   | Git hooks (pre-commit, pre-push)          | `bun add -D husky` |

## Install all at once

```sh
bun init
bun add -D typescript @types/bun biome knip husky
bun exec husky init
```

## Built-in (Bun — no install needed)

| Tool        | Purpose                  |
| ----------- | ------------------------ |
| bun test    | Test runner              |
| bun build   | Bundler                  |
| bun --watch | Dev mode with hot reload |

## Git Hooks (Husky)

- **pre-commit**: `bun lint && bun typecheck`
- **pre-push**: `bun test`

## CI Requirements

- Type checking: `bun typecheck`
- Tests: `bun test`
- Lint: `biome check`
- Dead code: `bun knip`
- All must pass on PR/merge
