# TypeScript + Vite

This is a TypeScript project using Vite as the build tool and dev server.

## Runtime

- Node.js (LTS)

## Build tool

- Vite (latest stable, installed via CLI)

## Package manager

- pnpm (mandatory)

## Module system

- ESM (`.ts` files, `import`/`export` syntax)

## Entry point

- `index.html` → `src/main.ts`

## Test runner

- Vitest (shares Vite config)

## Lint & Format

- Biome (linter + formatter, unified)

## Type checking

- `tsc --noEmit` (or `vue-tsc` for Vue, `svelte-check` for Svelte)

## Dead code

- Knip

## Git hooks

- Husky (pre-commit: lint + typecheck; pre-push: test)

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

## Framework init

During scaffolding, the agent must ask which framework to use (vanilla-ts, react-ts, vue-ts, svelte-ts) and use the corresponding Vite template:

```sh
pnpm create vite . --template <framework>
```

Available templates: `vanilla-ts`, `react-ts`, `vue-ts`, `svelte-ts`.

## Dependencies

See `REQUIREMENTS.md` for the full dependency table. After the Vite CLI scaffolds the project, install additional dev tools:

```sh
pnpm add -D biome knip husky
pnpm exec husky init
```
