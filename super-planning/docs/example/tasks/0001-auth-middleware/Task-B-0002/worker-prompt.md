# Worker Prompt: Task-B-0002

**Context:** Core task for auth-middleware. Task-B-0001 (requireAuth) is complete. You're building the authorization middleware that composes with it.

**Registry:** Read your task entry in `docs/tasks/0001-auth-middleware/super-plan.json` — it is your requirements. Look for `Task-B-0002`.

**Interfaces from earlier tasks:**
- `AuthUser` from `src/types/auth.ts` (Task-A-0001)
- `requireAuth` from `src/middleware/auth.ts` (Task-B-0001) — `requireRole` is used AFTER `requireAuth` in the middleware chain

**Ambiguity resolution:** `requireRole` is a higher-order function: `requireRole(...roles: string[])` returns `(req, res, next) => void`. If `req.user` is undefined (meaning `requireAuth` wasn't called first), return 401, not 403 — the problem is missing authentication, not insufficient permissions.

**Report file:** Write your full report to `docs/tasks/0001-auth-middleware/Task-B-0002/report.md`. Return only a one-line status to me.
