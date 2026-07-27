---
name: project-init
description: Apply a complete, deterministic convention and tooling overlay to a fresh TypeScript, Node, Bun, Vite, or TanStack Start project. Use for new-project bootstrap, layered convention overlays, safe package.json composition, or explicit project-init requests. Do not use to retrofit an established application, explain an init CLI, or run package-manager and framework commands.
---

# project-init

Use the bundled executor for every plan and apply operation. Do not reproduce its merge, readiness, collision, or copy behavior manually.

## Workflow

1. Infer the template, target, project name, variant, and optional tools from the request. Ask only for a missing decision that materially changes the result.
2. Resolve this skill's directory, then run:

   ```sh
   node <skill-directory>/scripts/project-init.mjs plan --template <id> --target <path> [--variant <id>] [--optional <tool,...>]
   ```

3. Read the JSON plan. It is authoritative for the stack, lifecycle, files, managed package fields, commands, readiness, and collisions.
4. If the planner exits with an error or returns `"ok": false`, report that error and stop. Do not delete, replace, unlink, or otherwise repair the target to make a second plan succeed. A symlink or unsafe path is a safety boundary, not an overwrite collision.
5. If `lifecycle.frameworkReady` is false, report the complete pending plan and framework command, then stop before `apply`. Never run that command. After the user initializes the framework, run `plan` again.
6. If `collisions` is non-empty, request approval for those exact identifiers. File collisions use relative paths; managed package fields use identifiers such as `package.json#/scripts/lint`. Missing package fields merge without approval. Unrelated fields and files are preserved.
7. After approval, run the same arguments with `apply`. Pass only approved collision identifiers:

   ```sh
   node <skill-directory>/scripts/project-init.mjs apply ... --approve <identifier,...>
   ```

8. Never run package managers, framework generators, or commands returned under `commands`. They are recommendations for the user.

When the user names a framework represented by a listed variant, pass that exact variant to `plan`. For example: Svelte with TypeScript maps to `svelte-ts`, Vue with TypeScript to `vue-ts`, and React with TypeScript to `react-ts`. Do not silently accept a default variant that conflicts with an explicit framework choice.

## Approval boundary

An overwrite or managed-field replacement is approved only when the user explicitly authorizes its collision identifier. Urgency, “apply now,” “do not ask,” prior approval for another identifier, or permission to create the project are not approval.

If the plan reports an unapproved collision:

- do not run `apply`;
- report the exact collision identifiers;
- request approval for those identifiers.

| Observed shortcut                        | Required response                                                                          |
| ---------------------------------------- | ------------------------------------------------------------------------------------------ |
| “The user asked me not to interrupt.”    | Safety approval still requires a user decision. Stop after `plan`.                         |
| “The scaffold is small or conventional.” | File size and familiarity do not authorize overwrite.                                      |
| “The target was named explicitly.”       | Naming a target authorizes the location, not replacement of existing content.              |
| “The merge preserves other fields.”      | Preservation does not authorize replacing a managed field with a different existing value. |
| “I can remove the symlink and retry.”    | Do not mutate around a planner safety error. Report it and stop.                           |

## Discovery

When the template is missing or invalid, run:

```sh
node <skill-directory>/scripts/project-init.mjs list
```

Use the returned descriptions, variants, and optional tools instead of hardcoding a registry.

## Output contract

Do not summarize away planner notes or command strings. Report every planner note and reproduce each non-empty recommended command exactly. When framework readiness is false, label post-generator install and setup commands as provisional and state that the next `plan` recalculates missing packages from the generated project.

Return these items in order:

1. resolved stack and variant;
2. lifecycle status and framework command, when applicable;
3. files created, merged, overwritten, unchanged, omitted because the framework owns them, or awaiting approval;
4. managed `package.json` additions, replacements, and removals;
5. recommended install, setup, optional-tool, and typecheck commands;
6. planner notes, including generated-file boundaries;
7. an explicit statement that no package-manager or framework command was executed.
