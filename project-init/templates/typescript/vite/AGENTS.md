# TypeScript + Vite

This is a TypeScript project using Vite as the build tool and dev server.

## Conventions

- **Runtime**: Node.js 22+ (LTS)
- **Build tool**: Vite 6+
- **Package manager**: pnpm (mandatory)
- **Module system**: ESM (`.ts` files, `import`/`export` syntax)
- **Entry point**: `index.html` → `src/main.ts`
- **Testing**: Vitest (shares Vite config)
- **Linting/formatting**: Biome
- **Type checking**: `tsc --noEmit` or `vue-tsc` (Vue), `svelte-check` (Svelte)
- **Dead code removal**: Knip
- **Git hooks**: Husky (pre-commit: lint + typecheck; pre-push: test)

## Commands

```sh
pnpm dev          # vite
pnpm build        # vite build
pnpm preview      # vite preview
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
│   ├── main.ts
│   ├── style.css
│   └── ...
├── public/
│   └── ...
├── tests/
│   └── ...
├── dist/             # build output (gitignored)
├── index.html
├── AGENTS.md
├── REQUIREMENTS.md
├── package.json
├── tsconfig.json
├── vite.config.ts
└── README.md
```

## Setup (after scaffolding)

```sh
pnpm create vite . --template vanilla-ts   # or react-ts, vue-ts, svelte-ts
pnpm add -D biome knip husky
pnpm exec husky init
```
