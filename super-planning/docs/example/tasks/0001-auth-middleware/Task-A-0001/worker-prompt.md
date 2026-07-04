# Worker Prompt: Task-A-0001

**Context:** This is the first foundation task for the auth-middleware feature. You're defining the TypeScript types that all other tasks will depend on.

**Registry:** Read your task entry in `docs/tasks/0001-auth-middleware/super-plan.json` — it is your requirements. Look for `Task-A-0001`.

**Interfaces from earlier tasks:** None — this is the first task.

**Ambiguity resolution:** The `AuthOptions` interface should have optional `secret` and `algorithms` fields. Default `secret` to `process.env.JWT_SECRET || 'test-secret'` and `algorithms` to `['HS256']` in the consumer (verifyToken), not in the type itself.

**Report file:** Write your full report to `docs/tasks/0001-auth-middleware/Task-A-0001/report.md`. Return only a one-line status to me.
