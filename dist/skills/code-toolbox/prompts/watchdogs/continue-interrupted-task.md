# Continue an interrupted code-toolbox task

Use this prompt only for a thread-bound continuation heartbeat.

1. Read the approved plan, relevant task briefs, reports and logs, and the current Git state.
2. If the plan is `completed` or `cancelled`, disable this continuation
   watchdog and report the terminal state.
3. If the plan or next task needs a human decision, report the exact blocker,
   pause this watchdog, and do not modify task state or source files.
4. If a task is already actively running, do not start a duplicate wave.
5. Otherwise, resume the next safe action through the normal
   code-toolbox lifecycle. Respect dependencies, the recorded worktree
   choice, review gates, and completed-task records.

Never redispatch a completed task or bypass a required review gate.
