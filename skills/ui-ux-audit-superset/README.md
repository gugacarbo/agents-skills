# ui-ux-audit-superset — standalone UI/UX audit superset

A portable Agent Skill for comprehensive UI/UX auditing of web applications.

This edition is designed as a **standalone superset** of the useful review coverage found in:

- Microsoft `frontend-design-review`;
- Vercel `web-design-guidelines`;

and adds:

- WCAG 2.2 AA depth;
- task/flow-based usability analysis;
- information architecture;
- form/error recovery;
- responsive and input-method matrices;
- systematic state testing;
- root-cause de-duplication;
- severity + confidence;
- full audit reporting;
- explicit verification gaps;
- remediation/retest workflow.

It does **not** need either upstream skill installed at runtime.

## Structure

```text
ui-ux-audit-superset/
├── SKILL.md
├── README.md
├── SOURCES.md
└── references/
    ├── accessibility-wcag22.md
    ├── code-review-rules.md
    ├── content-i18n.md
    ├── coverage-matrix.md
    ├── design-system.md
    ├── forms-inputs.md
    ├── interaction-states.md
    ├── performance-web-quality.md
    ├── report-template.md
    ├── responsive-layout.md
    ├── severity-confidence.md
    ├── trust-safety-ui.md
    ├── usability-ia.md
    └── visual-design.md
```

## Install

A common cross-agent layout is:

```text
.agents/
└── skills/
    └── ui-ux-audit-superset/
```

Copy the complete folder there.

Agent-specific folders may also be supported by your client.

## Recommended prompt

```text
Use ui-ux-audit-superset to perform a full audit of this application.

Open and interact with the running application; do not rely only on source review.
Audit desktop and mobile, keyboard/focus, WCAG 2.2 AA, forms, states,
responsive behavior, design-system consistency, content, interaction quality,
and relevant source-level web-interface rules.

Do not modify code in this pass.
Produce the complete prioritized report defined by the skill.
```

## Evaluation

The bundled development harness is intentionally excluded from published builds.

```bash
bun test skills/ui-ux-audit-superset/tests/tests.test.ts
python3 skills/skill-master/scripts/quick_validate.py skills/ui-ux-audit-superset

# Isolated paired runs; output is written under evals/results/ (ignored).
bun skills/ui-ux-audit-superset/evals/run-evals.mjs \
  --configuration without_skill --evals 1,2,4 \
  --output skills/ui-ux-audit-superset/evals/results/iteration-1
bun skills/ui-ux-audit-superset/evals/run-evals.mjs \
  --configuration with_skill --evals 1,2,4 \
  --output skills/ui-ux-audit-superset/evals/results/iteration-1

# Rebuild benchmark.json and a local review page after inspection/regrading.
bun skills/ui-ux-audit-superset/evals/run-evals.mjs \
  --configuration with_skill --evals 1,2,4 \
  --output skills/ui-ux-audit-superset/evals/results/iteration-1 \
  --aggregate-only
python3 skills/skill-master/eval-viewer/generate_review.py \
  skills/ui-ux-audit-superset/evals/results/iteration-1 \
  --skill-name ui-ux-audit-superset \
  --benchmark skills/ui-ux-audit-superset/evals/results/iteration-1/benchmark.json \
  --static skills/ui-ux-audit-superset/evals/results/iteration-1/review.html
```

The runner reads `evals/trigger-evals.json` as a future trigger-eval catalog and lives in `evals/run-evals.mjs`. It isolates `HOME`/`CLAUDE_CONFIG_DIR`, snapshots every workspace, grades deterministic expectations, and records benchmark data. The full run transcripts contain model output and are intentionally not committed. Eval 3 is a remediation discipline scenario and intentionally permits edits; audit evals deny Write/Edit tools.

## Remediation prompt

```text
Use the existing ui-ux-audit-superset report as the source of truth.
Fix Blocker and Critical findings first, then systemic Major findings.
Prefer shared component/token fixes over route-specific patches.
Re-test every affected flow and mark each finding with its verification status.
```
