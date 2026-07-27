---
name: project-init
description: Apply deterministic conventions and tooling to a fresh TypeScript, Node, Bun, Vite, or TanStack Start project. Use for new-project bootstrap, safe package.json composition, or explicit project-init requests. Do not use for established apps or to run framework or package-manager commands.
---

# project-init

Use the bundled executor. Its plan is authoritative for lifecycle, files, package fields, commands, readiness, and collisions.

## Workflow

1. Infer the template, target, project name, variant, and optional tools. Ask only when a missing choice changes the result.
2. Run:

   ```sh
   node <skill-directory>/scripts/project-init.mjs plan --template <id> --target <path> [--variant <id>] [--optional <tool,...>]
   ```

3. On an error or `"ok": false`, report it and stop. Never mutate the target to bypass a path or symlink error.
4. If `lifecycle.frameworkReady` is false, report the plan and framework command, then stop. After the user initializes the framework, run `plan` again.
5. If `collisions` is non-empty, request approval for those exact identifiers. Files use relative paths; package fields use identifiers such as `package.json#/scripts/lint`.
6. Apply only after readiness and collision approval, using the same arguments and only the approved identifiers:

   ```sh
   node <skill-directory>/scripts/project-init.mjs apply ... --approve <identifier,...>
   ```

7. Never run package managers, framework generators, or recommended commands.

Use the exact named variant: `svelte-ts`, `vue-ts`, or `react-ts`. Do not accept a conflicting default.

## Safety

An overwrite is approved only when the user authorizes its exact collision identifier. “Apply now,” permission to create the project, or approval for another identifier is not enough.

| Shortcut                       | Required response                                       |
| ------------------------------ | ------------------------------------------------------- |
| Skip review or questions       | Stop after `plan` and request exact collision approval. |
| Treat a small scaffold as safe | Existing content still requires approval.               |
| Remove a symlink and retry     | Report the safety error without mutating the target.    |

For missing or invalid templates, discover the registry instead of hardcoding it:

```sh
node <skill-directory>/scripts/project-init.mjs list
```

## Output contract

Report:

1. stack, variant, lifecycle, and framework command;
2. created, merged, overwritten, unchanged, omitted, and blocked files;
3. managed `package.json` additions, replacements, and removals;
4. every non-empty recommended command, exactly as returned;
5. every planner note and generated-file boundary;
6. confirmation that no package-manager or framework command ran.

Before framework initialization, label install and setup commands provisional; the next plan recalculates them.

Development metadata: [template manifest graph](templates/FILES.md) and [eval runner](evals/run-evals.mjs).
