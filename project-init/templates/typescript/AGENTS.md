# TypeScript Project

This is a TypeScript project. The exact runtime (Node, Deno, Bun) is chosen during project initialization.

## Runtime

- Node.js (LTS) / Bun / Deno — resolved by the selected derivative

## Package manager

- pnpm (mandatory)

## Module system

- ESM (`.ts` files, `import`/`export` syntax)

## Env contract

- Never read environment variables directly throughout the codebase. Centralize environment access in one module per app boundary (for example, `src/env.ts`).
- Parse and validate required variables at startup, fail fast when a required variable is missing or malformed, and expose a typed object to the rest of the application.
- Keep the base TypeScript template runtime-agnostic: do not hardcode `process.env`, `Bun.env`, or `Deno.env` here. The selected derivative may define the runtime-specific entry point for reading raw environment values.
- Prefer a schema-backed validator when the project grows or env usage becomes non-trivial. The optional `t3oss` tool is the default recommendation for that path.

## Scripts contract

- Every initialized TypeScript project must provide these scripts: `dev`, `build`, `test`, `lint`, `format`, `typecheck`, and `knip`.
- Add `prepare` when the project uses Husky so hooks install automatically after dependency installation.
- Runtime/framework-specific templates may add more scripts such as `start`, `preview`, or `test:watch`, but they should not remove the baseline scripts above.

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
