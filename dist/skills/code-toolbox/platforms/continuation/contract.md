# Portable watchdog adapter contract

Every provider defines named `continuation` and `status` roles, a JSON config
template materialized below `.code-toolbox/watchdogs/`, independent prompts,
and local host metadata. Core phases select only a provider and profile.

`continuation` resumes safe unfinished lifecycle work. `status` is read-only.
Adapters create, update, pause, and disable roles idempotently and never write
host IDs, credentials, or transcripts to versioned plan data.
