# TypeScript and Vite requirements

## Core Dependencies

- The selected Vite generator owns Vite, TypeScript, and framework packages.

## Overlay tooling

- Add only missing `vitest`, `@biomejs/biome`, `knip`, and `husky` packages after generation.
- Use the selected framework's generated type-checking dependencies when applicable.

## CI/CD

- Run `{{typecheckCommand}}`, Vitest, Biome, Knip, and `vite build`.
