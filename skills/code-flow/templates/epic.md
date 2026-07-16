<!-- Tracking artifact only. Do not add stage:* or needs-human labels to this Epic. -->

# Epic: <initiative title>

## Why now

<Problem, opportunity, and the user or business impact.>

## Outcome and success measures

- **Outcome:** <observable result when the initiative is complete>
- **Success measures:** <metric, target, and measurement method>

## Scope

- **In:** <capabilities or delivery outcomes included>
- **Out:** <explicit exclusions>
- **Constraints:** <time, compatibility, access, security, or product constraints>

## Child delivery issues

| Child | Delivery outcome | Owner | Depends on | Status |
| --- | --- | --- | --- | --- |
| #<n> | <one independently closable user-story outcome> | <team/person> | <#n or none> | <link/status> |

Each child must be a delivery/bug issue, using `templates/user-story.md`.
GitHub may link it as a subissue of this Epic. Apply `stage:*` labels and the
code-flow source, plan, execution, and review flow only to its children;
keep implementation-only steps as task IDs in the child's plan.

## Cross-cutting decisions and risks

| Item | Decision or risk | Owner | Resolution / review point |
| --- | --- | --- | --- |
| <id> | <decision, dependency, or risk> | <team/person> | <link, date, or condition> |

## Completion

The Epic is complete when every in-scope child is closed or explicitly removed
by a recorded product decision, its success measures are evaluated, and any
cross-cutting decisions have a durable record.
