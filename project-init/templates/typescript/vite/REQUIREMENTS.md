# TypeScript + Vite — Requirements

## Runtime

- Node.js 22+ (LTS)
- Package manager: pnpm (mandatory)

## Core Dependencies

| Package    | Version | Purpose                    |
| ---------- | ------- | -------------------------- |
| typescript | ^5.7    | TypeScript compiler        |
| vite       | ^6      | Build tool + dev server    |

## Dev Dependencies

| Package | Version | Purpose                               |
| ------- | ------- | ------------------------------------- |
| vitest  | ^3      | Test runner (shares Vite config)      |
| biome   | ^1.9    | Linter + formatter (unified)          |
| knip    | ^5      | Dead code and unused dependency detection |
| husky   | ^9      | Git hooks (pre-commit, pre-push)      |

## Framework Plugins (optional)

| Package                       | Purpose        |
| ----------------------------- | -------------- |
| @vitejs/plugin-react          | React support  |
| @vitejs/plugin-vue            | Vue support    |
| @sveltejs/vite-plugin-svelte  | Svelte support |

## Git Hooks (Husky)

- **pre-commit**: `pnpm lint && pnpm typecheck`
- **pre-push**: `pnpm test`

## CI Requirements

- Type checking: `tsc --noEmit`
- Tests: `vitest run`
- Lint: `biome check`
- Dead code: `knip`
- Build: `vite build`
- All must pass on PR/merge
