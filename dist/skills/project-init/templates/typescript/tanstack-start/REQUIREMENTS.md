# TanStack Start requirements

## Core Dependencies

- The generator owns React, TanStack Start, Router, Vite, and SSR packages.

## Overlay tooling

- Preserve the generated Biome config and lint script, then migrate its schema.
- Add only missing `vitest`, `knip`, and `husky`.
- Preserve reviewed `esbuild` and `lightningcss` approvals.

## Generated code

- Exclude `src/routeTree.gen.ts` from edits and dead-code enforcement.

## CI/CD

- Run TypeScript, Vitest, Biome, Knip, and the TanStack Start production build.
