# code-toolbox

`code-toolbox` coordinates non-trivial work through independent subagents. It uses accepted ADRs/specs as the technical source of truth, GitHub issues for delivery planning and review when an issue is supplied, and PRs for implementation evidence.

## Invocation

| Command | Meaning |
| --- | --- |
| `/code-toolbox` | Resume the earliest unmet phase in repository mode. |
| `/code-toolbox issue #42 [phase]` | Resume or start an existing delivery/bug issue. |
| `/code-toolbox batch #42 #43 --from plan` | Run issue trails in parallel from one phase. |
| `/code-toolbox plan` | Start the repository-only plan phase and continue. |
| `/code-toolbox tool doctor --github --issue 42` | Validate GitHub readiness for an issue flow. |

The canonical flow is:

`Pre-issue investigation/spec gate → Spec approval → Needs plan → Needs plan review → Approved → In progress → Needs task review → Closed`

A named phase continues forward but cannot bypass its prerequisites. A batch never creates issues; it operates only on existing delivery/bug issues.

## Sources and evidence

Accepted ADRs/specs define intended behavior. Code/tests show current behavior. In issue mode, the issue contains append-only plan, review, task-evidence, and closure comments while exactly one detailed stage label identifies the next gate. Every plan task has an ID and closure maps it to commit/PR, review, and DoD evidence.

Specs are conditional: create or update one only for a contract, observable behavior, or durable architectural decision. Otherwise record why a spec is not required.

See [SKILL.md](SKILL.md) for gates, agent roles, and the full workflow.
