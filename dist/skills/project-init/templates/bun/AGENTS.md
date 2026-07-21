# Bun conventions

## Runtime

- Use the current stable Bun runtime.

## Package manager

- Use Bun and commit `bun.lock`.

## Module system

- Use ESM for TypeScript and JavaScript modules.

## Env contract

- Read `Bun.env` only through a centralized environment module.
- Validate required variables before application startup.

## Entry point

- Use `src/index.ts` unless the initialized project defines another explicit entry point.

## Test runner

- Use Bun's built-in test runner.

## Lint & Format

- Use Biome from the `@biomejs/biome` package.

## Type checking

- Run `bun run typecheck` and delegate to `tsc --noEmit`.

## Dead code

- Use Knip with the generic overlay configuration.

## Git hooks

- Husky delegates to scripts that invoke Bun through the resolved package-manager contract.

## Commands

```sh
bun run dev
bun run build
bun test
bun run lint
bun run format
bun run typecheck
bun run knip
```

## Project Structure

- Keep source under `src/`, tests under `tests/`, and build output under `dist/`.
