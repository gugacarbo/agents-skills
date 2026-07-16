# Codex watchdog adapter

Materialize `codex-watchdogs.json` and prompts under `.code-toolbox/watchdogs/`.
For every enabled role, use the Codex automation capability to create or update
a heartbeat targeting the current thread. Do not use a cron for `status`.

`continuation` follows the normal task lifecycle and pauses on a human block.
`status` reports evidenced state only; it may interrupt active work but must not
edit files, change lifecycle state, dispatch work, or create automations.
Store role-specific host identifiers only in
`.code-toolbox/continuations/<plan-id>.json`; disable all roles at terminal
plan states.
