# Worker Prompt: Task-B-0001

**Context:** Core task for auth-middleware. Tasks A-0001 (types) and A-0002 (verifyToken) are complete. You're building the first middleware that uses them.

**Registry:** Read your task entry in `docs/tasks/0001-auth-middleware/super-plan.json` — it is your requirements. Look for `Task-B-0001`.

**Interfaces from earlier tasks:**
- `JwtPayload`, `AuthUser` from `src/types/auth.ts` (Task-A-0001)
- `verifyToken` from `src/middleware/auth.ts` (Task-A-0002) — import and use it, do NOT reimplement

**Ambiguity resolution:** When logging token verification errors, use `req.log?.error(err, 'Token verification failed')` with optional chaining since `pino` may not be attached to every request in tests. The response to the client must always be the generic `{ error: "Invalid or expired token" }` — never include the actual error message.

**Report file:** Write your full report to `docs/tasks/0001-auth-middleware/Task-B-0001/report.md`. Return only a one-line status to me.
