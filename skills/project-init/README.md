# project-init

`project-init` applies deterministic convention overlays for fresh projects and recommends framework/package-manager commands without executing them.

## Examples

```text
$project-init base-only
$project-init typescript
$project-init typescript/node
$project-init typescript/vite
$project-init typescript/tanstack-start
$project-init bun
```

## Architecture

- [`SKILL.md`](SKILL.md) is the agent workflow and output contract.
- [`scripts/project-init.mjs`](scripts/project-init.mjs) owns discovery, inheritance, planning, collision detection, and application.
- [`templates/README.md`](templates/README.md) defines the manifest and authoring contract.
- `templates/**/template.json` is the machine-readable source of truth.
- Layer `AGENTS.md` and `REQUIREMENTS.md` files contain only project-facing document sections.
- `evals/` contains paired behavioral scenarios and the reproducible [Codex runner](evals/run-evals.mjs).
- [`templates/FILES.md`](templates/FILES.md) exposes the dynamic manifest graph to static package validation.

Use `plan` before `apply`. Framework and package-manager commands are always returned as recommendations, never executed by the skill.
