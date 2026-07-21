# Base project conventions

## General

- Use English for code, comments, and durable project documentation.
- Keep the README current with setup, usage, validation, and contribution guidance.
- Prefer the smallest change that satisfies the project contract.

## Code Style

- Use spaces, LF line endings, no trailing whitespace, and one final newline.
- Follow repository-local formatter and linter configuration when present.

## Git

- Use Conventional Commits.
- Use descriptive branches such as `feature/<name>`, `fix/<name>`, and `chore/<name>`.
- Never commit secrets or `.env` files.

## CI/CD

- Run the project's lint, typecheck, test, and build scripts on pull requests when they exist.
- Keep CI commands aligned with the package scripts used locally.

## Agent Behavior

- Inspect existing files before changing them.
- Request explicit approval before overwriting user-authored files or performing irreversible actions.
- Report focused verification and any checks that could not run.

## Project Structure

- Keep reusable agent skills under `.agents/skills/` when the project needs repository-scoped workflows.
- Keep generated artifacts out of source directories and version control unless the project explicitly tracks them.

## Skills

- `commit-changes` for Conventional Commit workflows.
- `code-flow` for multi-step repository deliveries.
