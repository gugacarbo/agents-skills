# Worker Prompt: Task-B-2

**Context:** Core task for auth-middleware. Task-B-1 (requireAuth) is complete. You're building the authorization middleware that composes with it.

**Registry:** Read your task entry in `docs/jobs/0001-auth-middleware/super-plan.json` — it is your requirements. Look for `Task-B-2`.

**Interfaces from earlier tasks:**

- `AuthUser` from `src/types/auth.ts` (Task-A-1)
- `requireAuth` from `src/middleware/auth.ts` (Task-B-1) — `requireRole` is used AFTER `requireAuth` in the middleware chain

**Ambiguity resolution:** `requireRole` is a higher-order function: `requireRole(...roles: string[])` returns `(req, res, next) => void`. If `req.user` is undefined (meaning `requireAuth` wasn't called first), return 401, not 403 — the problem is missing authentication, not insufficient permissions.

**Report file:** Write your full report to `docs/jobs/0001-auth-middleware/Task-B-2/report.md`. Return only a one-line status to me.
