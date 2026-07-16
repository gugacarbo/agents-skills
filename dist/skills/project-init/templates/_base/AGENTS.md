# Project Conventions (Base)

These conventions apply to every project scaffolded with `/project-init`.

## Setup (first thing after scaffolding)

If `casa-standard` was selected from the optional tools below, run the install step. Otherwise skip it.

## General

- **Language**: Prefer English for code, comments, and documentation.
- **Version control**: Git with Conventional Commits (`feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`).
- **README**: Every project must have a `README.md` with setup instructions, usage, and contribution guidelines.
- **License**: Include a `LICENSE` file (MIT unless specified otherwise).

## Code Style

- **Indentation**: Spaces (2 or 4, consistent per project).
- **Line endings**: LF (`\n`).
- **Trailing whitespace**: Trim on save.
- **Final newline**: Every file ends with a single newline.

## Git

- **Branch naming**: `feature/<name>`, `fix/<name>`, `chore/<name>`.
- **Commit messages**: Follow Conventional Commits.
- **No secrets**: Never commit `.env` files, API keys, or credentials.
- **`.gitignore`**: Keep it updated with language/framework-specific ignores.

## CI/CD

- Prefer GitHub Actions for CI.
- Run lint, typecheck, and tests on every PR.
- Keep the CI pipeline fast (< 5 min when possible).

## Agent Behavior

- **Ask, don't assume**: Always use a question tool (`request_user_input`, ask, question, ask user, etc.) when you need confirmation or a decision from the user. Never proceed with ambiguous or irreversible actions without explicit approval.

## Optional Tools

During scaffolding, the agent must use a question tool such as `request_user_input` to ask the user which of these optional tools to include. Only add the selected ones to the setup instructions.

The `Install` column uses `<pm>` as a placeholder for the resolved package manager (e.g., `pnpm`, `bun`, `npm`). The agent must substitute `<pm>` with the package manager resolved from the template cascade before printing setup instructions. The `-w` flag is pnpm-specific; for other package managers, omit it or use the equivalent.

Deeper template layers may override a tool from this table by reusing the same value in the `Tool` column and changing its description and/or install command. Tools omitted by deeper layers remain inherited.

| Tool          | Type    | Purpose                                   | Install                     |
| ------------- | ------- | ----------------------------------------- | --------------------------- |
| casa-standard | repo    | Docs-check, ADRs, CI gate (recommended)   | (see setup instructions)    |
| turbo         | global  | Monorepo orchestration (Turborepo)        | `<pm> add -w -D turbo`      |
| lint-staged   | dev     | Run linters only on staged files          | `<pm> add -D lint-staged`   |
| test-staged   | dev     | Run tests only on staged/changed files    | `<pm> add -D test-staged`   |
| t3oss         | runtime | Type-safe environment variable management | `<pm> add @t3-oss/env-core` |

When `casa-standard` is selected, include these setup instructions:

```sh
curl -fsSL https://raw.githubusercontent.com/atplus-digital/casa-standard/main/install.sh | sh -s -- . --repo-id <project-name>
```

This installs the docs-check validator, templates, AGENTS.md router, and CI gate. It is additive and idempotent — safe to re-run.

To validate the repo locally:

```sh
python3 scripts/docs-check
```

When `lint-staged` is selected, add `pnpm lint-staged` before the `exec` line in `scripts/pre-commit`.
When `test-staged` is selected, add `pnpm test-staged` before the `exec` line in `scripts/pre-commit`.

## Project Structure

- **`.agents/`** — folder for custom skills, prompts, and agent definitions used by opencode.

## Skills (opencode)

These are recommended skills for the project. Install them separately if not already present:

- `commit-changes` — conventional commits workflow
- `code-flow` — planning multi-step tasks
