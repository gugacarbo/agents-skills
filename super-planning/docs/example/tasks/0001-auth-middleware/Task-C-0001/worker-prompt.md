# Worker Prompt: Task-C-0001

**Context:** Final integration task for auth-middleware. All middlewares (requireAuth, requireRole) and types are complete. You're wiring them into the existing routes and writing integration tests.

**Registry:** Read your task entry in `docs/tasks/0001-auth-middleware/super-plan.json` — it is your requirements. Look for `Task-C-0001`.

**Interfaces from earlier tasks:**

- `requireAuth`, `requireRole` from `src/middleware/auth.ts` (Tasks B-0001, B-0002)
- `AuthUser` from `src/types/auth.ts` (Task-A-0001)

**Ambiguity resolution:** Do NOT modify the logic inside existing route handlers — only add middlewares to the route definitions. For integration tests, use `supertest` and generate real JWT tokens with `jsonwebtoken.sign`. Use a test-only `JWT_SECRET` (e.g., `'integration-test-secret'`) set via `process.env` before the test suite runs.

**Report file:** Write your full report to `docs/tasks/0001-auth-middleware/Task-C-0001/report.md`. Return only a one-line status to me.
