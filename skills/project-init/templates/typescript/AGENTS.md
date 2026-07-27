# TypeScript conventions

## Runtime

- The selected derivative defines the runtime.

## Package manager

- Use pnpm and commit `pnpm-lock.yaml`.

## Module system

- Use ESM and `import`/`export` syntax.

## Env contract

- Centralize and validate environment reads before startup.
- Export typed values to application code.

## Scripts contract

- Provide `dev`, `build`, `test`, `lint`, `format`, `typecheck`, and `knip` scripts.
- Use `prepare` for Husky.

## Test runner

- Use Vitest unless the runtime owns testing.

## Lint & Format

- Use Biome from the `@biomejs/biome` package.

## Type checking

- Run `{{typecheckCommand}}` without emitting build artifacts.

## Dead code

- Use Knip; add exceptions only when required.

## Git hooks

- Husky delegates to repository scripts: pre-commit checks code; pre-push runs tests.

## Commands

```sh
pnpm run dev
pnpm run build
pnpm run test
pnpm run lint
pnpm run format
pnpm run typecheck
pnpm run knip
```
