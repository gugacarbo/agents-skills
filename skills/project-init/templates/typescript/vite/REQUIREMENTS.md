# TypeScript and Vite requirements

## Core Dependencies

- The selected Vite generator owns Vite, TypeScript, and framework packages.

## Dev Dependencies

- Add `vitest`, `@biomejs/biome`, `knip`, and `husky` after generation.
- Use the selected framework's generated type-checking dependencies when applicable.

## CI/CD

- Run `{{typecheckCommand}}`, Vitest, Biome, Knip, and `vite build`.
