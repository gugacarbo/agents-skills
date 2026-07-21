# TanStack Start requirements

## Core Dependencies

- The generator owns React, TanStack Start, TanStack Router, Vite, and SSR integration packages.

## Dev Dependencies

- Add `vitest`, `@biomejs/biome`, `knip`, and `husky` after generation.

## Generated code

- Exclude `src/routeTree.gen.ts` from edits and dead-code enforcement.

## CI/CD

- Run TypeScript, Vitest, Biome, Knip, and the TanStack Start production build.
