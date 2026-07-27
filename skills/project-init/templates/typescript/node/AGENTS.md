# TypeScript and Node conventions

## Runtime

- Target Node.js LTS.

## Package manager

- Use pnpm.

## Module system

- Use ESM with `"type": "module"` in `package.json`.

## Env contract

- Centralize, validate, and normalize `process.env`.

## Entry point

- Default to `src/index.ts`.

## Commands

```sh
pnpm run dev
pnpm run build
pnpm run start
pnpm run test
pnpm run lint
pnpm run format
pnpm run typecheck
pnpm run knip
```

## Project Structure

- Use `src/`, `tests/`, and `dist/` for source, tests, and output.
