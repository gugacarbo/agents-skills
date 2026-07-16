# code-flow

`code-flow` coordinates non-trivial delivery through independent roles, GitHub
issues, approval gates, and PR evidence.

## Invocation

| Command | Meaning |
| --- | --- |
| `/code-flow` | Resume the earliest unmet repository phase. |
| `/code-flow issue create` | Run Phases 0–2, then create a delivery issue with an ADR/spec proposal awaiting approval. |
| `/code-flow issue #42 [phase]` | Resume an eligible delivery or bug issue. |
| `/code-flow batch #42 #43 --from plan` | Run existing eligible issues from one phase. |
| `/code-flow plan` | Start repository-only planning. |

The flow is: context → brainstorm and human design approval → proposal in issue
→ human ADR/spec approval → plan → independent review → human plan approval →
execution → independent delivery review → PR approval → optional integration.

Use the repository's current template or canonical example before any bundled
template. For initiatives, create a tracking-only [Epic](templates/01-epic.md)
only after the user selects it; each [user-story](templates/02-user-story.md)
child has its own delivery flow.

Phase 2 puts the proposed ADR/spec—or a no-spec rationale—inside the GitHub
issue for approval. It materializes the formal ADR/spec only after that
approval. A plan-reviewer verdict is also insufficient by itself: the user
approves the exact plan snapshot before execution.

`direct` stores equivalent evidence in a versioned delivery record and never
creates GitHub state. See [SKILL.md](SKILL.md) for the complete rules.
