> **Process:** `super-planning` — generated from `super-plan.json` by the active super-planning helper.

# Task Brief: Task-A-1: Implement authenticated real-time job dashboard runtime

| Field | Value |
|-------|-------|
| ID | `Task-A-1` |
| Status | ⏳ pending |
| Profile | deep |
| Layer | core |
| Batch | A |
| Try Count | 1 |
| Dependencies | _None_ |

Create the independent Node 18 job dashboard helper, server, and dependency-free browser surface. Use real temporary jobs fixtures and sockets to prove the accepted lifecycle, authorization, snapshot, live-update, and malformed-input behavior.

### Acceptance Criteria

- [ ] Focused dashboard tests are observed RED while the helper is absent, then GREEN against a real local server process.
- [ ] serve-jobs.sh implements the accepted arguments, one-JSON stdout contract, authenticated health verification, owner-only runtime metadata, duplicate reuse, foreground mode, and safe idempotent stop.
- [ ] server.cjs uses Node built-ins only, produces the accepted snapshot envelope, reads no paths outside the jobs root, never mutates the jobs root, retains last valid data on malformed files, and broadcasts only changed snapshots.
- [ ] HTTP, cookie bootstrap, restrictive headers, WebSocket authentication/origin checks, responsive DOM UI, filters, literal text rendering, and connection state satisfy the accepted security and presentation contracts.
- [ ] The focused dashboard suite verifies startup, authentication, empty and multiple registries, update delivery, malformed registry/JSONL recovery, event cap, injection safety, occupied ports, stale PID safety, and clean shutdown.

### Requirements

- `REQ-001`
- `REQ-002`
- `REQ-003`
- `REQ-004`
- `REQ-005`

### Rules

- TDD required for this behavior-changing task.
- Read docs/context/testing-anti-patterns.md before creating fixtures or test-only helpers.
- Use real file fixtures, HTTP requests, WebSocket frames, and child processes; do not mock the dashboard server or filesystem contract.
- Keep stdout parseable; diagnostics and warnings go to stderr.
- Do not add packages, CDNs, mutation endpoints, or dashboard-only lifecycle states.
- Write RED and GREEN commands, output, and expected failure reason to the task report.

### Steps

**Step 1: Add failing integration coverage**

Add a focused dashboard-only test section using minimal temporary project, registry, progress log, and socket fixtures. Run it before implementing the helper and record the missing-runtime failure.

```sh
SUPER_PLANNING_JOB_DASHBOARD_ONLY=1 bash skills/super-planning/dev/tests.sh
```

**Expected result:** Fails because job-dashboard helper/server behavior is absent

<details>
<summary>Code Example</summary>

```
if [[ "${SUPER_PLANNING_JOB_DASHBOARD_ONLY:-}" = 1 ]]; then test_job_dashboard; fi
```

</details>

**Step 2: Implement lifecycle helper**

Create serve-jobs.sh with argument validation, canonical project/jobs roots, secure per-project state, launch/reuse, authenticated health check, optional opener warning, and PID instance proof for stop.

```sh
bash -n skills/super-planning/scripts/job-dashboard/serve-jobs.sh
```

**Expected result:** Shell syntax check exits 0

<details>
<summary>Code Example</summary>

```
serve-jobs.sh --project-dir <path> --base-dir <path> --refresh-ms 1000
```

</details>

**Step 3: Implement secure snapshot server**

Create server.cjs with built-in HTTP and RFC 6455 support, token/cookie authorization, headers, filesystem-signature scanning, snapshot cache/retention/warnings, and authenticated broadcasts.

```sh
node --check skills/super-planning/scripts/job-dashboard/server.cjs
```

**Expected result:** Node syntax check exits 0

<details>
<summary>Code Example</summary>

```
{ type: 'job-snapshot', version: 1, plans: [], warnings: [] }
```

</details>

**Step 4: Implement browser dashboard**

Add local CSS and JavaScript that render metrics, plan/task details, filters, warnings, timelines, and connection state using textContent rather than HTML injection.

```sh
SUPER_PLANNING_JOB_DASHBOARD_ONLY=1 bash skills/super-planning/dev/tests.sh
```

**Expected result:** All focused runtime and browser-security assertions pass

<details>
<summary>Code Example</summary>

```
node.textContent = value
```

</details>

**Step 5: Report TDD evidence**

Run the focused suite again after self-review, preserve exact results in report.md, and do not alter distribution helpers owned by later tasks.

```sh
SUPER_PLANNING_JOB_DASHBOARD_ONLY=1 bash skills/super-planning/dev/tests.sh
```

**Expected result:** GREEN evidence is complete and output is clean

### Files

**Created:**

- `skills/super-planning/scripts/job-dashboard/serve-jobs.sh`
- `skills/super-planning/scripts/job-dashboard/server.cjs`
- `skills/super-planning/scripts/job-dashboard/app.js`
- `skills/super-planning/scripts/job-dashboard/styles.css`

**Modified:**

- `skills/super-planning/dev/tests.sh`

---

