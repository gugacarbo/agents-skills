# TypeScript and Vite conventions

## Runtime

- Use Node.js LTS for local tooling and the browser as the client runtime.

## Build tool

- Use Vite for development and production builds.

## Package manager

- Use pnpm.

## Env contract

- Read `import.meta.env` only through a centralized client environment module.
- Expose only intentionally public variables and validate them before application use.

## Entry point

- Follow the generated {{frameworkName}} entry point and keep application code under `src/`.

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

- Preserve generator-owned framework files, `index.html`, `public/`, and `src/`.
- Apply convention files only after the Vite generator finishes.
