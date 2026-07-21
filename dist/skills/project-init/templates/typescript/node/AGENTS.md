# TypeScript and Node conventions

## Runtime

- Target the current Node.js LTS release.

## Package manager

- Use pnpm.

## Module system

- Use ESM with `"type": "module"` in `package.json`.

## Env contract

- Read `process.env` only in a centralized module such as `src/env.ts`.
- Validate and normalize values before exporting them to application code.

## Entry point

- Use `src/index.ts` as the default application or CLI entry point.

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

- Keep source under `src/`, tests under `tests/`, and compiled output under `dist/`.
