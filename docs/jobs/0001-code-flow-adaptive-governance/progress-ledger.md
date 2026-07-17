> **Process:** `super-planning` — this ledger is generated from `super-plan.json` by the active super-planning helper.
> Follow `super-planning/SKILL.md` and the active phase instructions when interpreting or updating this work.

# Progress Ledger: code-flow-adaptive-governance

> **Plan:** `0001-code-flow-adaptive-governance`
> **Registry:** `docs/jobs/0001-code-flow-adaptive-governance/super-plan.json`
> **Generated:** 2026-07-17T00:28:01Z
> **Regenerated on every `super-plan.json` write via the active `render-progress-ledger.sh` helper path**

## Summary

| Status | Count |
|--------|-------|
| pending | 0 |
| in_progress | 0 |
| ready_for_review | 0 |
| reviewing | 0 |
| needs_fix | 0 |
| blocked | 0 |
| completed | 0 |
| cancelled | 0 |
| **Total** | **0** |

## Agent Profiles

| Profile | Model | Agent | Effort |
|---------|-------|--------|--------|
| generalExecutor | default | default | default |
| deepExecutor | default | default | default |
| taskReviewer | default | default | default |
| investigator | default | default | default |
| specReviewer | default | default | default |
| finalAuditor | default | default | default |

## Tasks

| Task ID | Title | Profile | Batch | Layer | Status | Dependencies |
|---------|-------|---------|-------|-------|--------|-------------|
| — | no tasks defined yet | — | — | — | [PEND] pending | — |

## Timeline

| Timestamp | Task | Event | Try | Message |
|-----------|------|-------|-----|---------|
| — | — | no task events logged yet | — | — |

## Requirements Coverage

| Requirement | Status | Covered By |
|-------------|--------|------------|
| — | no requirements defined yet | — |

## Registry Parameters

Every parameter from `super-plan.json` is preserved below. This section is generated directly from the registry so the ledger remains a complete, auditable representation of the plan configuration and task data.

<details>
<summary>Complete <code>super-plan.json</code></summary>

````json
{
  "$schema": "https://raw.githubusercontent.com/gugacarbo/agents-skills/main/skills/super-planning/interfaces/super-plan.schema.json",
  "createdAt": "2026-07-17T00:28:01.821363+00:00",
  "planId": "0001-code-flow-adaptive-governance",
  "featureName": "code-flow-adaptive-governance",
  "status": "pending",
  "source": {
    "spec": "docs/specs/0001-code-flow-adaptive-governance.md",
    "plan": "docs/code-flow-changes-plan.md"
  },
  "goal": "",
  "architectureSummary": "",
  "techStack": [],
  "executionMode": "subagent-driven",
  "reviewCadence": "per_task",
  "agents": {
    "generalExecutor": {
      "model": "",
      "agent": "",
      "effort": ""
    },
    "deepExecutor": {
      "model": "",
      "agent": "",
      "effort": ""
    },
    "taskReviewer": {
      "model": "",
      "agent": "",
      "effort": ""
    },
    "investigator": {
      "model": "",
      "agent": "",
      "effort": ""
    },
    "specReviewer": {
      "model": "",
      "agent": "",
      "effort": ""
    },
    "finalAuditor": {
      "model": "",
      "agent": "",
      "effort": ""
    }
  },
  "branchStrategy": {
    "baseBranch": "main",
    "featureBranch": "main"
  },
  "worktree": {
    "enabled": false,
    "path": ""
  },
  "globalConstraints": [],
  "fileStructure": [],
  "requirementsChecklist": [],
  "taskDirectory": "docs/jobs/0001-code-flow-adaptive-governance",
  "rules": [],
  "continuation": {
    "enabled": false,
    "provider": "codex",
    "watchdogProfile": "default",
    "status": "disabled"
  },
  "tasks": []
}
````

</details>
