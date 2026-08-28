# Published template graph

The runtime resolves these files through manifests. This inventory keeps that dynamic graph visible to static package validation.

## Manifests

- [`base/template.json`](base/template.json)
- [`typescript/template.json`](typescript/template.json)
- [`typescript/node/template.json`](typescript/node/template.json)
- [`typescript/vite/template.json`](typescript/vite/template.json)
- [`typescript/tanstack-start/template.json`](typescript/tanstack-start/template.json)
- [`bun/template.json`](bun/template.json)

## Project requirement fragments

- [`base/REQUIREMENTS.md`](base/REQUIREMENTS.md)
- [`typescript/REQUIREMENTS.md`](typescript/REQUIREMENTS.md)
- [`typescript/node/REQUIREMENTS.md`](typescript/node/REQUIREMENTS.md)
- [`typescript/vite/REQUIREMENTS.md`](typescript/vite/REQUIREMENTS.md)
- [`typescript/tanstack-start/REQUIREMENTS.md`](typescript/tanstack-start/REQUIREMENTS.md)
- [`bun/REQUIREMENTS.md`](bun/REQUIREMENTS.md)

## Base and shared assets

- [`base/files/.editorconfig`](base/files/.editorconfig)
- [`base/files/.gitignore`](base/files/.gitignore)
- [`base/optional-tools/cspell/files/cspell.config.yaml`](base/optional-tools/cspell/files/cspell.config.yaml)
- [`_shared/tooling/files/biome.template.json`](_shared/tooling/files/biome.template.json)
- [`_shared/husky/files/.husky/pre-commit`](_shared/husky/files/.husky/pre-commit)
- [`_shared/husky/files/.husky/pre-push`](_shared/husky/files/.husky/pre-push)
- [`_shared/husky/files/scripts/lib/shared.sh`](_shared/husky/files/scripts/lib/shared.sh)
- [`_shared/husky/files/scripts/pre-commit`](_shared/husky/files/scripts/pre-commit)
- [`_shared/husky/files/scripts/pre-push`](_shared/husky/files/scripts/pre-push)

## Optional-tool assets (shared)

- [`_shared/optional-tools/ci-github-actions/files/.github/workflows/CI.yaml`](_shared/optional-tools/ci-github-actions/files/.github/workflows/CI.yaml)
- [`_shared/optional-tools/env/files/.env.example`](_shared/optional-tools/env/files/.env.example)
- [`_shared/optional-tools/secrets/files/scripts/gitleaks-check`](_shared/optional-tools/secrets/files/scripts/gitleaks-check)

## TypeScript assets

- [`typescript/files/knip.json`](typescript/files/knip.json)
- [`typescript/files/tsconfig.json`](typescript/files/tsconfig.json)
- [`typescript/files/src/index.ts`](typescript/files/src/index.ts)
- [`typescript/optional-tools/lint-staged/files/.lintstagedrc.js`](typescript/optional-tools/lint-staged/files/.lintstagedrc.js)
- [`typescript/node/optional-tools/docker/files/Dockerfile`](typescript/node/optional-tools/docker/files/Dockerfile)
- [`typescript/node/optional-tools/docker/files/.dockerignore`](typescript/node/optional-tools/docker/files/.dockerignore)
- [`typescript/vite/files/vitest.config.ts`](typescript/vite/files/vitest.config.ts)
- [`typescript/vite/optional-tools/docker/files/Dockerfile`](typescript/vite/optional-tools/docker/files/Dockerfile)
- [`typescript/vite/optional-tools/docker/files/.dockerignore`](typescript/vite/optional-tools/docker/files/.dockerignore)
- [`typescript/tanstack-start/files/knip.json`](typescript/tanstack-start/files/knip.json)

## Bun assets

- [`bun/optional-tools/docker/files/Dockerfile`](bun/optional-tools/docker/files/Dockerfile)
- [`bun/optional-tools/docker/files/.dockerignore`](bun/optional-tools/docker/files/.dockerignore)
