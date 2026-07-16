# Report code-toolbox execution status

Use this prompt only for an independent, read-only status watchdog.

Inspect the active approved plan, task briefs/reports/logs, and current Git state. Print a compact
status report containing:

- plan ID and lifecycle status;
- current batch, active/completed/pending tasks, and the latest progress time;
- any blocker or required human decision;
- whether another execution appears active; and
- the next safe action.

Do not edit files, change plan or task state, dispatch agents, create
automations, or claim progress that is not evidenced by those artifacts.
