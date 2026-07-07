# TypeScript + Node

This is a TypeScript project targeting Node.js runtime.

## Runtime

- Node.js (LTS)

## Package manager

- pnpm (mandatory)

## Module system

- ESM (`"type": "module"` in package.json, `.ts` files, `import`/`export` syntax)

## Entry point

- `src/index.ts`

## Test runner

- Vitest

## Lint & Format

- Biome (linter + formatter, unified)

## Type checking

- `tsc --noEmit`

## Dead code

- Knip

## Git hooks

- Husky (pre-commit: lint + typecheck; pre-push: test)

## Commands

```sh
pnpm dev          # tsx watch src/index.ts
pnpm build        # tsc
pnpm start        # node dist/index.js
pnpm test         # vitest run
pnpm test:watch   # vitest
pnpm lint         # biome check
pnpm format       # biome check --write
pnpm typecheck    # tsc --noEmit
pnpm knip         # dead code detection
```

## Project Structure

```
<project-name>/
├── .agents/          # Custom skills, prompts, agents
├── src/
│   ├── index.ts
│   └── ...
├── tests/
│   └── ...
├── dist/             # build output (gitignored)
├── AGENTS.md
├── REQUIREMENTS.md
├── package.json
├── tsconfig.json
└── README.md
```

## Framework init

```sh
pnpm init
```

## Dependencies

See `REQUIREMENTS.md` for the full dependency table. Install all at once:

```sh
pnpm add -D typescript @types/node vitest biome tsx knip husky
pnpm exec husky init
```
