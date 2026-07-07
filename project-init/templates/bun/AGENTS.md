# Bun Project

This is a Bun project. Bun is the runtime, package manager, bundler, and test runner — all-in-one.

## Conventions

- **Runtime**: Bun (latest stable)
- **Package manager**: bun (built-in, mandatory)
- **Module system**: ESM (`.ts` / `.js` files, `import`/`export` syntax)
- **Entry point**: `src/index.ts` (or `src/index.js`)
- **Testing**: `bun test` (built-in)
- **Linting/formatting**: Biome
- **Type checking**: `bun run typecheck` (delegates to `tsc --noEmit`)
- **Dead code removal**: Knip
- **Git hooks**: Husky (pre-commit: lint + typecheck; pre-push: test)

## Commands

```sh
bun dev             # bun --watch src/index.ts
bun start           # bun src/index.ts
bun test            # bun test
bun test:watch      # bun test --watch
bun lint            # biome check
bun format          # biome check --write
bun typecheck       # tsc --noEmit
bun knip            # knip
bun build           # bun build src/index.ts --outdir dist
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
├── bun.lock
└── README.md
```

## Setup (after scaffolding)

```sh
bun init
bun add -D typescript @types/bun biome knip husky
bun exec husky init
```
