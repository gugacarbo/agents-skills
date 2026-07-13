# TypeScript Project

This is a TypeScript project. The exact runtime (Node, Deno, Bun) is chosen during project initialization.

## Runtime

- Node.js (LTS) / Bun / Deno — resolved by the selected derivative

## Package manager

- pnpm (mandatory)

## Module system

- ESM (`.ts` files, `import`/`export` syntax)

## Env contract

- Never read environment variables directly throughout the codebase. Centralize environment access in one module per app boundary (for example, `src/env.ts`).
- Parse and validate required variables at startup, fail fast when a required variable is missing or malformed, and expose a typed object to the rest of the application.
- Keep the base TypeScript template runtime-agnostic: do not hardcode `process.env`, `Bun.env`, or `Deno.env` here. The selected derivative may define the runtime-specific entry point for reading raw environment values.
- Prefer a schema-backed validator when the project grows or env usage becomes non-trivial. The optional `t3oss` tool is the default recommendation for that path.

## Scripts contract

- Every initialized TypeScript project must provide these scripts: `dev`, `build`, `test`, `lint`, `format`, `typecheck`, and `knip`.
- Add `prepare` when the project uses Husky so hooks install automatically after dependency installation.
- Runtime/framework-specific templates may add more scripts such as `start`, `preview`, or `test:watch`, but they should not remove the baseline scripts above.

## Test runner

- Vitest

## Lint & Format

- Biome (linter + formatter, unified, mandatory)

## Type checking

- `tsc --noEmit`

## Dead code

- Knip

## Git hooks

- Husky (pre-commit: lint + typecheck; pre-push: test)

## Commands (once initialized)

```sh
pnpm dev          # development server/watch mode
pnpm build        # production build
pnpm test         # vitest run
pnpm lint         # biome check
pnpm format       # biome check --write
pnpm typecheck    # tsc --noEmit
pnpm knip         # dead code detection
pnpm prepare      # husky install (runs automatically on pnpm install)
```

## Stack

| Concern         | Tool                     |
| --------------- | ------------------------ |
| Runtime         | Node (LTS) / Bun / Deno  |
| Language        | TypeScript (strict mode) |
| Package manager | pnpm                     |
| Testing         | Vitest                   |
| Linting         | Biome                    |
| Formatting      | Biome                    |
| Dead code       | Knip                     |
| Git hooks       | Husky                    |
| CI              | GitHub Actions           |

## Optional Tools

During scaffolding, the agent must use a question tool such as `request_user_input` to ask the user which of these optional tools to include. Only add the selected ones to the setup instructions.

The `Install` column uses `<pm>` as a placeholder for the resolved package manager (e.g., `pnpm`, `bun`, `npm`). The agent must substitute `<pm>` with the package manager resolved from the template cascade before printing setup instructions. The `-w` flag is pnpm-specific; for other package managers, omit it or use the equivalent.

Deeper template layers may override a tool from this table by reusing the same value in the `Tool` column and changing its description and/or install command. Tools omitted by deeper layers remain inherited.

| Tool        | Type    | Purpose                                   | Install                     |
| ----------- | ------- | ----------------------------------------- | --------------------------- |
| turbo       | global  | Monorepo orchestration (Turborepo)        | `<pm> add -w -D turbo`      |
| lint-staged | dev     | Run linters only on staged files          | `pnpm add -D lint-staged`   |
| test-staged | dev     | Run tests only on staged/changed files    | `<pm> add -D test-staged`   |
| t3oss       | runtime | Type-safe environment variable management | `<pm> add @t3-oss/env-core` |

When `lint-staged` is selected, add `pnpm lint-staged` before the `exec` line in `scripts/pre-commit`.
When `test-staged` is selected, add `pnpm test-staged` before the `exec` line in `scripts/pre-commit`.

When `lint-staged` is selected for a TypeScript project, also add these scripts to `package.json`:

```jsonc
"format:md": "pnpx prettier --write \"**/*.{md,mdx}\" --log-level=warn --no-error-on-unmatched-pattern --cache",
"lint-staged": "lint-staged"
```

And scaffold `.lintstagedrc.js` from the template file in this directory.
