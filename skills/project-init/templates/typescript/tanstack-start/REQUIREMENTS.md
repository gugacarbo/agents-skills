# TanStack Start requirements

## Core Dependencies

- The generator owns React, TanStack Start, TanStack Router, Vite, and SSR integration packages.

## Overlay tooling

- The generator owns its selected Biome toolchain.
- Add only missing `vitest`, `@biomejs/biome`, `knip`, and `husky` packages after generation.

## Generated code

- Exclude `src/routeTree.gen.ts` from edits and dead-code enforcement.

## CI/CD

- Run TypeScript, Vitest, Biome, Knip, and the TanStack Start production build.
