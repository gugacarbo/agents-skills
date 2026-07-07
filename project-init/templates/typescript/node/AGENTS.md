# TypeScript + Node

This is a TypeScript project targeting Node.js runtime.

## Conventions

- **Runtime**: Node.js 22+ (LTS)
- **Package manager**: pnpm (mandatory)
- **Module system**: ESM (`"type": "module"` in package.json, `.ts` files, `import`/`export` syntax)
- **Entry point**: `src/index.ts`
- **Testing**: Vitest
- **Linting/formatting**: Biome
- **Type checking**: `tsc --noEmit`
- **Dead code removal**: Knip
- **Git hooks**: Husky (pre-commit: lint + typecheck; pre-push: test)

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

## Setup (after scaffolding)

```sh
pnpm init
pnpm add -D typescript @types/node vitest biome tsx knip husky
pnpm exec husky init
```

