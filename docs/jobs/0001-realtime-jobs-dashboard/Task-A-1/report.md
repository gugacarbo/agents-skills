# Task-A-1 report: authenticated real-time jobs dashboard

## Scope delivered

- Added `scripts/job-dashboard/serve-jobs.sh` with detached and foreground
  lifecycle handling, authenticated health verification, per-project owner-only
  runtime metadata, duplicate reuse, explicit-port failure, and safe stale-PID
  cleanup.
- Added the Node 18 built-in HTTP/WebSocket server, immutable snapshot
  aggregation, malformed input retention/recovery, and read-only filesystem
  traversal under the configured jobs root.
- Added local vanilla browser assets with responsive plan/task detail, filters,
  warnings, connection state, and `textContent` rendering for registry/log
  values.
- Added real child-process, HTTP, cookie, WebSocket, malformed-data, live
  update, empty-root, multi-registry, occupied-port, injection, and stale-PID
  coverage to `dev/tests.sh` behind `SUPER_PLANNING_JOB_DASHBOARD_ONLY=1`.

## TDD evidence

### RED

Command:

```bash
rtk bash -lc 'SUPER_PLANNING_JOB_DASHBOARD_ONLY=1 bash skills/super-planning/dev/tests.sh'
```

Output before creating the runtime:

```text
FAIL: expected path to exist: /home/gustavo/Apps/agent-skills/skills/super-planning/scripts/job-dashboard/serve-jobs.sh
```

Expected reason: the focused integration suite requires the helper, server,
and local assets before it can launch its real dashboard process.

### GREEN

Command:

```bash
rtk bash -n skills/super-planning/scripts/job-dashboard/serve-jobs.sh
rtk node --check skills/super-planning/scripts/job-dashboard/server.cjs
rtk bash -lc 'SUPER_PLANNING_JOB_DASHBOARD_ONLY=1 bash skills/super-planning/dev/tests.sh'
```

Output:

```text
PASS: job dashboard
```

Both syntax checks exited `0`; the focused suite exited `0`.

## Focused assertions exercised

- Empty jobs roots return an authenticated zero-plan snapshot; foreground mode
  starts a real process that passes health verification and is safely stopped.
- The token bootstrap redirects to a token-free URL and supplies an HttpOnly
  cookie; unauthenticated snapshots return `403` without plan data.
- An authenticated same-origin raw RFC 6455 socket receives exactly an initial
  snapshot and one changed snapshot after a real registry appears.
- Multiple registries aggregate; a malformed registry retains its prior valid
  plan and warning, then removes that warning when recovered.
- JSONL malformed-line warnings retain valid events, preserve full event count,
  and cap `recentEvents` to 200.
- Cross-origin upgrades are rejected, the browser asset has no `innerHTML`, an
  explicit occupied port fails, duplicate start reuses the existing PID, and a
  stale PID is reported and cleared without signaling it.

## Deliberately deferred

Bootstrap/update/doctor manifest wiring, public route/documentation, package
build wiring, and final full-suite/spec closure are owned by Tasks B, C, and D.

## Review remediation (Task-A-1)

- Containment now resolves every discovered registry and every task `progress.log`
  and `report.md` through `realpath`, then rejects resolved paths outside the
  canonical jobs root. The focused test replaces a task directory with an
  external symlink and adds an external linked registry; neither external
  event, report content, nor plan is returned.
- `serve-jobs.sh` now serializes starts and stops with an atomic per-project
  `start.lock`. A second starter waits, rechecks the authenticated healthy
  instance, reuses it, and the lock is released after startup or shutdown.
- Server signal shutdown removes only metadata whose PID/instance ID belongs to
  that live server. Focused coverage sends both `SIGTERM` and `SIGINT` and
  verifies `server.pid`, `server-instance-id`, and `server-info.json` are gone.
- Default wildcard binding derives an advertised non-loopback LAN address when
  available, non-wildcard bindings advertise their actual host, IPv6 URLs are
  bracketed, and health probes target the selected binding (or its appropriate
  loopback counterpart for wildcard listeners).
- The snapshot now includes aggregate task/requirement lifecycle counts and
  requirement completion. The UI renders aggregate lifecycle sections, task
  and requirement completion, all lifecycle filter choices, requirement task
  coverage, explicit last-event detail, and the last successful update time.
- The cross-origin WebSocket regression sends a valid dashboard token with an
  evil `Origin` and confirms the upgrade is still rejected. CSP now uses only
  `connect-src 'self'`, without the arbitrary `ws:` source.
- JSONL recovery is covered end-to-end: malformed input warns while retaining
  valid events, then a valid rewrite removes the warning.

### Review-remediation GREEN evidence

```bash
rtk bash -n skills/super-planning/dev/tests.sh
rtk bash -n skills/super-planning/scripts/job-dashboard/serve-jobs.sh
rtk node --check skills/super-planning/scripts/job-dashboard/server.cjs
rtk node --check skills/super-planning/scripts/job-dashboard/app.js
rtk bash -lc 'SUPER_PLANNING_JOB_DASHBOARD_ONLY=1 bash skills/super-planning/dev/tests.sh'
rtk git diff --check
```

Observed output:

```text
PASS: job dashboard
```

All listed commands exited `0`.

## Runtime-state hardening remediation (Task-A-1)

- The Node child now closes the helper's `start.lock` descriptor before exec.
  A killed helper can therefore never leave the live dashboard process holding
  the lifecycle lock; concurrent starts remain serialized by the persistent
  lock inode.
- Runtime state files are rejected when they are symlinks. Token, instance,
  PID, metadata, and server-log writes use owner-only temporary files followed
  by atomic replacement, which replaces a racing symlink rather than following
  it. The server applies the same checks to its own metadata and log writes.
- The focused integration coverage kills a helper while its Node server is
  alive and blocked in its first health probe, then proves `--stop` acquires
  the lock and terminates that server. It also points `server-instance-id` at a
  sentinel inside `docs/jobs` and proves startup rejects it without changing
  the sentinel.

### Runtime-state hardening GREEN evidence

```bash
rtk bash -n skills/super-planning/scripts/job-dashboard/serve-jobs.sh
rtk bash -n skills/super-planning/dev/tests.sh
rtk node --check skills/super-planning/scripts/job-dashboard/server.cjs
rtk bash -lc 'SUPER_PLANNING_JOB_DASHBOARD_ONLY=1 bash skills/super-planning/dev/tests.sh'
rtk git diff --check
```

Observed result: `PASS: job dashboard`; all commands exited `0`.

## Lock-staleness remediation (Task-A-1)

- Replaced the crash-prone `mkdir` lock directory with a persistent regular
  `start.lock` file protected by an exclusive `flock` on an open descriptor.
  The kernel releases that descriptor lock on `SIGKILL` or process crash, so a
  stale metadata file can never block a later start or stop, while two live
  lifecycle commands still serialize on the same inode.
- The file records the lock-holder PID, operation, and acquisition time. It is
  retained after release intentionally: unlinking a lock file after unlocking
  can split contenders across different inodes and permit concurrent starts.
- The focused regression creates lock metadata while holding `flock`, kills the
  owner with `SIGKILL`, then verifies a real dashboard start and subsequent
  stop both succeed and refresh the owner metadata.

### Lock-staleness GREEN evidence

```bash
rtk bash -n skills/super-planning/scripts/job-dashboard/serve-jobs.sh
rtk bash -n skills/super-planning/dev/tests.sh
rtk bash -lc 'SUPER_PLANNING_JOB_DASHBOARD_ONLY=1 bash skills/super-planning/dev/tests.sh'
rtk git diff --check
```

Observed output:

```text
PASS: job dashboard
```

All listed commands exited `0`.

## Final containment remediation (Task-A-1)

- Runtime-state resolution now rejects a `.super-planning` symlink whose
  canonical `job-dashboard` directory escapes the canonical project directory,
  before creating state or metadata.
- The selected jobs root is canonically resolved and checked in both start and
  stop modes. Consequently, `--stop --base-dir <project>/.super-planning`
  rejects the state-contained jobs root before it can write under that root.
- `--stop` returns `not_running` without creating `.super-planning` or the
  dashboard state directory when no runtime state already exists.

### Final-containment GREEN evidence

```bash
rtk bash -n skills/super-planning/scripts/job-dashboard/serve-jobs.sh
rtk bash -n skills/super-planning/dev/tests.sh
rtk bash -lc 'SUPER_PLANNING_JOB_DASHBOARD_ONLY=1 bash skills/super-planning/dev/tests.sh'
rtk git diff --check
```

Observed output:

```text
PASS: job dashboard
```

All commands exited `0`. The focused suite now proves rejection without an
outside write for a symlinked `.super-planning`, rejection for a stop-mode jobs
root that contains runtime state, and `not_running` without state-directory
creation.

## Final review remediation (Task-A-1)

- Each plan card now derives warnings from its own `registryPath` and plan
  directory, then displays a clear `Warning: N issue(s)` indicator only for
  warnings tied to that plan. The focused DOM regression uses two registries
  and verifies that a registry warning plus a task-progress warning count only
  on the matching card.
- Duplicate startup now reads the active instance's recorded `host`,
  `urlHost`, and `port` from `server-info.json` for its authenticated health
  probe and returned URL. A later invocation using `--host 127.0.0.2` safely
  reuses the active `127.0.0.1` server without clearing its metadata or
  launching a second process.

### Final-review GREEN evidence

```bash
rtk bash -n skills/super-planning/scripts/job-dashboard/serve-jobs.sh
rtk bash -n skills/super-planning/dev/tests.sh
rtk node --check skills/super-planning/scripts/job-dashboard/app.js
rtk bash -lc 'SUPER_PLANNING_JOB_DASHBOARD_ONLY=1 bash skills/super-planning/dev/tests.sh'
rtk git diff --check
```

Observed output:

```text
PASS: job dashboard
```

All listed commands exited `0`.

## Contract remediation (Task-A-1)

- Plan-card warning matching now accepts the server's canonical jobs-root
  relative warning paths (for example,
  `0001-dashboard/super-plan.json`) while still using the project-relative
  registry path rendered in the snapshot. Task-progress warnings use the
  matching task-id path segment, so they stay attached to the correct plan.
- The JSONL reader treats every physical blank or whitespace-only entry as a
  malformed line, except the synthetic final split item produced by one normal
  terminal newline. Valid events remain available and the warning clears after
  a valid rewrite.
- `server-info.json` now stores the canonical `baseDir` used by the live
  server. A healthy duplicate start returns that active value in `base_dir`,
  even if the later invocation requests a different `--base-dir`.

### Contract-remediation RED/GREEN evidence

RED command:

```bash
rtk bash -lc 'SUPER_PLANNING_JOB_DASHBOARD_ONLY=1 bash skills/super-planning/dev/tests.sh'
```

Observed failure before the runtime fix:

```text
FAIL: blank JSONL line did not preserve valid events with a warning
```

GREEN commands:

```bash
rtk bash -n skills/super-planning/dev/tests.sh
rtk bash -n skills/super-planning/scripts/job-dashboard/serve-jobs.sh
rtk node --check skills/super-planning/scripts/job-dashboard/server.cjs
rtk node --check skills/super-planning/scripts/job-dashboard/app.js
rtk bash -lc 'SUPER_PLANNING_JOB_DASHBOARD_ONLY=1 bash skills/super-planning/dev/tests.sh'
rtk git diff --check
```

All listed commands exited `0`. The focused suite exercises actual
BASE_DIR-relative registry and progress-log warnings, an inserted blank JSONL
line, warning recovery, and a healthy duplicate invocation with a different
requested jobs root.

## Final contract edge-case remediation (Task-A-1)

- A zero-byte `progress.log` is now a valid zero-event log: it clears any
  prior cached progress and emits no warning. Physical blank records remain
  malformed JSONL and still preserve valid events with a warning.
- Startup rejects a canonical `--base-dir` that contains the project's
  `.super-planning/job-dashboard` runtime directory before creating that
  directory or any runtime metadata.

### Focused GREEN evidence

```bash
rtk bash -n skills/super-planning/dev/tests.sh
rtk bash -n skills/super-planning/scripts/job-dashboard/serve-jobs.sh
rtk node --check skills/super-planning/scripts/job-dashboard/server.cjs
rtk bash -lc 'SUPER_PLANNING_JOB_DASHBOARD_ONLY=1 bash skills/super-planning/dev/tests.sh'
rtk git diff --check
```

The focused suite verifies a physical blank JSONL record still warns, a
subsequent zero-byte log returns zero events without a warning, and a nested
jobs-root invocation leaves `job-dashboard/` absent after rejection.

All listed commands exited `0`.

## Pre-PID helper-crash remediation (Task-A-1)

- Startup now hands the already-held `start.lock` descriptor to Node. The
  helper closes only its own descriptor copy after spawn; Node keeps the lock
  until the live process has atomically published its own PID, instance ID,
  server info, and log entry.
- `server.pid` is therefore never derived from the helper's background PID.
  The existing `pid_matches_instance` proof still validates the live Node
  command line and instance ID before lifecycle actions signal a process.
- The focused real-process regression pauses Node immediately before metadata
  publication, kills its helper with `SIGKILL`, then starts a successor. The
  successor remains blocked by the inherited lock, is released only after the
  child publishes metadata, and returns that exact child PID; the final stop
  proves no orphan remains.

### Pre-PID helper-crash GREEN evidence

```bash
rtk bash -n skills/super-planning/scripts/job-dashboard/serve-jobs.sh
rtk bash -n skills/super-planning/dev/tests.sh
rtk node --check skills/super-planning/scripts/job-dashboard/server.cjs
rtk bash -lc 'SUPER_PLANNING_JOB_DASHBOARD_ONLY=1 bash skills/super-planning/dev/tests.sh'
rtk git diff --check
```

Observed result: `PASS: job dashboard`; all listed commands exited `0`.

## PID proof and post-handoff cleanup remediation (Task-A-1)

- `--stop` now requires `server-instance-id` to be exactly a 64-character
  lowercase hexadecimal ID before it can match a PID command line. Missing or
  malformed proof therefore fails closed: no process is signalled, only stale
  PID/instance/info metadata is removed, and the result is `stale_pid`.
- Child-start failure cleanup now reacquires the lifecycle lock after the
  helper has handed it to the child. It removes each PID, instance, and info
  file only when that file independently proves it belongs to the original
  launch, so a successor's published metadata cannot be erased.
- The focused suite starts real dashboards for both absent and invalid
  instance-proof cases and verifies that their PIDs remain live, lifecycle
  metadata is cleared, and the session token remains. It also forces a real
  occupied-port child failure, pauses only its post-handoff cleanup, starts a
  successor, then proves the original cleanup leaves the successor PID and
  coherent metadata intact.

### PID-proof and cleanup-race GREEN evidence

```bash
rtk bash -n skills/super-planning/scripts/job-dashboard/serve-jobs.sh
rtk bash -n skills/super-planning/dev/tests.sh
rtk node --check skills/super-planning/scripts/job-dashboard/server.cjs
rtk bash -lc 'SUPER_PLANNING_JOB_DASHBOARD_ONLY=1 bash skills/super-planning/dev/tests.sh'
rtk git diff --check
```

Observed result: `PASS: job dashboard`; all listed commands exited `0`.
