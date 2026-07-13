# project-init

`/project-init` scaffolds layered convention files for a new project and then recommends the next CLI commands without running them.

## Entry points

```text
/project-init
/project-init base-only
/project-init typescript
/project-init typescript/node
/project-init typescript/vite
/project-init bun
```

## Source of truth

- [`SKILL.md`](SKILL.md): minimal router for the skill
- [`templates/README.md`](templates/README.md): authoritative workflow, cascade rules, and template authoring standard
- [`templates/`](templates/): actual layered template content

If behavior changes, update `templates/README.md` and the affected template files first. Keep `SKILL.md` and this `README.md` as thin entry documents.
