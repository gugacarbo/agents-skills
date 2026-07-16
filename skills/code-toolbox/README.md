# code-toolbox

`code-toolbox` coordinates non-trivial work through independent subagents. It uses accepted ADRs/specs as the technical source of truth, GitHub issues for delivery planning and review when an issue is supplied, and PRs for implementation evidence.

## Invocation

| Command | Meaning |
| --- | --- |
| `/code-toolbox` | Resume the earliest unmet phase in repository mode. |
| `/code-toolbox issue create` | After investigation/spec gate, create one delivery issue at `stage:spec-approval` + `needs-human`. |
| `/code-toolbox issue #42 [phase]` | Resume or start an existing delivery/bug issue. |
| `/code-toolbox batch #42 #43 --from plan` | Run issue trails in parallel from one phase. |
| `/code-toolbox plan` | Start the repository-only plan phase and continue. |
| `/code-toolbox tool doctor --github --issue 42` | Validate GitHub readiness for an issue flow. |

The canonical flow is:

`Pre-issue investigation/spec gate → Spec approval → Needs plan → Needs plan review → Approved → In progress → Needs task review → PR approval → optional integration → Closed`

A named phase continues forward but cannot bypass its prerequisites. A batch never creates issues; it operates only on existing delivery/bug issues.

## Sources and evidence

Accepted ADRs/specs define intended behavior. Code/tests show current behavior. In issue mode, the issue contains append-only plan, review, task-evidence, and closure comments while exactly one detailed stage label identifies the next gate. Every plan task has an ID and closure maps it to commit/PR, review, and DoD evidence.

Specs are conditional: create or update one only for a contract, observable behavior, or durable architectural decision. Otherwise record the concrete no-spec rationale and obtain human source-set approval before planning.

Issue execution is worktree-only. `/code-toolbox issue create` is the sole issue-creation route and is available only after the spec gate prepares an ADR/spec or explicit no-spec rationale; it is incompatible with repository `direct` mode. `direct` creates no issue and uses no labels or GitHub comments. Repository mode keeps one versioned Markdown delivery record with append-only plan, independent plan review, task evidence, code reviews, and DoD closure—not a local progress registry. Rejected reviews, `BLOCKED`, and audit failures are recorded there with a stop/resume instruction, never as GitHub state. For parallel issue tasks, task branches are assembled and independently re-reviewed before the issue PR. After that PR is approved, merge/integration is suggested as an explicit optional final action; it is never automatic.

See [SKILL.md](SKILL.md) for gates, agent roles, and the full workflow.
