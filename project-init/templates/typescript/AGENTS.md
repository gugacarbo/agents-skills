# TypeScript Project

This is a TypeScript project. The exact runtime (Node, Deno, Bun) is chosen during project initialization.

## Runtime

- Node.js (LTS) / Bun / Deno — resolved by the selected derivative

## Package manager

- pnpm (mandatory)

## Module system

- ESM (`.ts` files, `import`/`export` syntax)

## Test runner

- Vitest

## Lint & Format

- Biome (linter + formatter, unified, mandatory)

## Type checking

- `tsc --noEmit`

## Dead code

- Knip

## Git hooks

- Husky (pre-commit: lint + typecheck; pre-push: test)

## Commands (once initialized)

```sh
pnpm dev          # development server/watch mode
pnpm build        # production build
pnpm test         # vitest run
pnpm lint         # biome check
pnpm format       # biome check --write
pnpm typecheck    # tsc --noEmit
pnpm knip         # dead code detection
pnpm prepare      # husky install (runs automatically on pnpm install)
```

## Stack

| Concern         | Tool                     |
| --------------- | ------------------------ |
| Runtime         | Node (LTS) / Bun / Deno  |
| Language        | TypeScript (strict mode) |
| Package manager | pnpm                     |
| Testing         | Vitest                   |
| Linting         | Biome                    |
| Formatting      | Biome                    |
| Dead code       | Knip                     |
| Git hooks       | Husky                    |
| CI              | GitHub Actions           |
