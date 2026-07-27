# TypeScript and Vite requirements

## Core Dependencies

- The Vite generator owns Vite, TypeScript, and framework packages.

## Overlay tooling

- Add only missing `vitest`, `@biomejs/biome`, `knip`, and `husky`.
- Keep framework type-checking dependencies.
- For React, replace Oxlint with Biome only with exact field approval.
- Allow the reviewed `esbuild` lifecycle script.

## CI/CD

- Run `pnpm run typecheck`, Vitest, Biome, Knip, and `vite build`.
