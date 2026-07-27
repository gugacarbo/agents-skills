# TypeScript and Vite conventions

## Runtime

- Use Node.js LTS for tooling and the browser at runtime.

## Build tool

- Use Vite for development and production builds.

## Package manager

- Use pnpm.

## Env contract

- Centralize and validate `import.meta.env`.
- Expose only intentional public variables.

## Entry point

- Follow the generated {{frameworkName}} entry point under `src/`.

## Type checking

- Run `{{typecheckCommand}}`.

## Commands

```sh
pnpm run dev
pnpm run build
pnpm run preview
pnpm run test
pnpm run lint
pnpm run format
pnpm run typecheck
pnpm run knip
```

## Project Structure

- Preserve generator-owned files and apply the overlay after generation.
