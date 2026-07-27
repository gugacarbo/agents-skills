# TypeScript and Vite requirements

## Core Dependencies

- The selected Vite generator owns Vite, TypeScript, and framework packages.

## Overlay tooling

- Add only missing `vitest`, `@biomejs/biome`, `knip`, and `husky` packages after generation.
- Use the selected framework's generated type-checking dependencies when applicable.
- When the React generator supplies `oxlint`, replace its script with Biome and remove the now-unused package only after exact field approval.
- Allow the reviewed `esbuild` lifecycle script when pnpm installs missing tooling.

## CI/CD

- Run `pnpm run typecheck`, Vitest, Biome, Knip, and `vite build`.
