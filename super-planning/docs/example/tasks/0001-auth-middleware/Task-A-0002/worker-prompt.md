# Worker Prompt: Task-A-0002

**Context:** Foundation task for auth-middleware. Task-A-0001 (types) is already complete — import from `src/types/auth.ts`.

**Registry:** Read your task entry in `docs/tasks/0001-auth-middleware/super-plan.json` — it is your requirements. Look for `Task-A-0002`.

**Interfaces from earlier tasks:** `JwtPayload`, `AuthUser`, `AuthOptions` are defined in `src/types/auth.ts`. Use `JwtPayload` as the return type of `verifyToken`.

**Ambiguity resolution:** The `verifyToken` function should catch `TokenExpiredError` and `JsonWebTokenError` from `jsonwebtoken` and re-throw as a generic `Error` with message `'Invalid or expired token'`. This prevents leaking implementation details to callers.

**Report file:** Write your full report to `docs/tasks/0001-auth-middleware/Task-A-0002/report.md`. Return only a one-line status to me.
