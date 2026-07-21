# TypeScript conventions

## Runtime

- The selected derivative owns the concrete runtime boundary.

## Package manager

- Use pnpm and commit `pnpm-lock.yaml`.

## Module system

- Use ESM and `import`/`export` syntax.

## Env contract

- Centralize raw environment reads in one module per application boundary.
- Validate required variables before serving requests, jobs, or CLI work.
- Export a typed environment object instead of passing unvalidated strings throughout the codebase.

## Scripts contract

- Provide `dev`, `build`, `test`, `lint`, `format`, `typecheck`, and `knip` scripts.
- Add `prepare` when Husky installs hooks after dependency setup.

## Test runner

- Use Vitest unless the selected runtime provides the project test runner.

## Lint & Format

- Use Biome from the `@biomejs/biome` package.

## Type checking

- Run `{{typecheckCommand}}` without emitting build artifacts.

## Dead code

- Use Knip with the generic project configuration from the overlay.
- Add project-specific workspaces and exceptions only when the repository actually needs them.

## Git hooks

- Husky delegates to repository scripts.
- Pre-commit runs lint and typecheck; pre-push runs tests.

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
