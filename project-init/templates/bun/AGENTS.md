# Bun Project

This is a Bun project. Bun is the runtime, package manager, bundler, and test runner — all-in-one.

## Runtime

- Bun (latest stable)

## Package manager

- bun (built-in, mandatory)

## Module system

- ESM (`.ts` / `.js` files, `import`/`export` syntax)

## Entry point

- `src/index.ts` (or `src/index.js`)

## Test runner

- `bun test` (built-in)

## Lint & Format

- Biome (linter + formatter, unified)

## Type checking

- `bun run typecheck` (delegates to `tsc --noEmit`)

## Dead code

- Knip

## Git hooks

- Husky (pre-commit: lint + typecheck; pre-push: test)

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

## Framework init

```sh
bun init
```

## Dependencies

See `REQUIREMENTS.md` for the full dependency table. Install all at once:

```sh
bun add -D typescript @types/bun biome knip husky
bun exec husky init
```

## Optional Tools

During scaffolding, the agent must use a question tool to ask the user which of these optional tools to include. Only add the selected ones to the setup instructions.

| Tool        | Type    | Purpose                                   | Install                    |
| ----------- | ------- | ----------------------------------------- | -------------------------- |
| turbo       | global  | Monorepo orchestration (Turborepo)        | `bun add -d -w turbo`      |
| lint-staged | dev     | Run linters only on staged files          | `bun add -D lint-staged`   |
| test-staged | dev     | Run tests only on staged/changed files    | `bun add -D test-staged`   |
| t3oss       | runtime | Type-safe environment variable management | `bun add @t3-oss/env-core` |
