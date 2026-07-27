# TanStack Start requirements

## Core Dependencies

- The generator owns React, TanStack Start, TanStack Router, Vite, and SSR integration packages.

## Overlay tooling

- The generator owns its selected Biome toolchain.
- Preserve the generator-owned `biome.json` and lint script.
- Migrate the generator-owned Biome schema with the installed Biome version.
- Add only missing `vitest`, `knip`, and `husky` packages after generation.
- Preserve the generator's reviewed `esbuild` and `lightningcss` build approvals.

## Generated code

- Exclude `src/routeTree.gen.ts` from edits and dead-code enforcement.

## CI/CD

- Run TypeScript, Vitest, Biome, Knip, and the TanStack Start production build.
