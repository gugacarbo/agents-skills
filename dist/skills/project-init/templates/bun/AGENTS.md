# Bun conventions

## Runtime

- Use stable Bun.

## Package manager

- Use Bun and commit `bun.lock`.

## Module system

- Use ESM for TypeScript and JavaScript modules.

## Env contract

- Centralize and validate `Bun.env` before startup.

## Entry point

- Default to `src/index.ts`.

## Test runner

- Use Bun's built-in test runner.

## Lint & Format

- Use Biome from the `@biomejs/biome` package.

## Type checking

- Run `bun run typecheck` and delegate to `tsc --noEmit`.

## Dead code

- Use Knip with the generic overlay configuration.

## Git hooks

- Husky delegates to Bun-aware repository scripts.

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

- Use `src/`, `tests/`, and `dist/` for source, tests, and output.
