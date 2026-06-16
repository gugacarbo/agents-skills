# skill-creator KNOWLEDGE BASE

**Generated:** 2026-06-11 09:55:28 -0300
**Commit:** 1e1ebb6

## OVERVIEW

`skill-creator` is a local skill for drafting, evaluating, benchmarking, and improving Codex/Claude skills. It is more complex than the tracked `commit-changes` skill and contains Python tooling, agent prompt templates, references, assets, and an HTML eval viewer.

## STRUCTURE

```
skill-creator/
├── SKILL.md                 # workflow for creating/improving skills
├── agents/                  # analyzer/comparator/grader prompts
├── references/schemas.md    # eval schema reference
├── scripts/                 # Python eval, benchmark, packaging, validation helpers
├── eval-viewer/             # report generator and viewer HTML
└── assets/                  # bundled review UI asset
```

## WHERE TO LOOK

| Task | Location | Notes |
| --- | --- | --- |
| Main workflow | `SKILL.md` | Explains capture, drafting, eval loop, and description improvement. |
| Parse skill metadata | `scripts/utils.py` | `parse_skill_md()` handles YAML frontmatter. |
| Trigger evals | `scripts/run_eval.py` | Spawns `claude -p`, creates temporary `.claude/commands` files, removes `CLAUDECODE`. |
| Benchmark aggregation | `scripts/aggregate_benchmark.py` | Summarizes repeated eval runs. |
| Report generation | `scripts/generate_report.py`, `eval-viewer/generate_review.py` | Produces human-reviewable output. |
| Eval schema | `references/schemas.md` | Read before changing eval JSON shape. |

## CONVENTIONS

- Keep `SKILL.md` focused on progressive disclosure; move large schemas/examples to `references/`.
- Python helpers assume repo-relative imports such as `from scripts.utils import parse_skill_md`.
- Eval workspaces are created as siblings to the target skill, organized by iteration and eval case.
- With-skill and baseline runs should be launched together so timing/results are comparable.
- Capture subagent timing immediately when notifications arrive; it is not persisted elsewhere.
- Generated `__pycache__` files may exist locally; do not treat them as source.

## ANTI-PATTERNS

- Do not use `/skill-test`; this skill has its own eval flow.
- Do not create all eval output directories upfront; create them as runs happen.
- Do not silently change eval schema shape without updating `references/schemas.md`.
- Do not make trigger evals depend on interactive Claude sessions; they use `claude -p` subprocesses.
- Do not broadly unignore this directory without deciding which generated/cache files belong in git.

## COMMANDS

```sh
rtk python3 skill-creator/scripts/quick_validate.py <skill-path>
rtk python3 skill-creator/scripts/run_eval.py --help
rtk python3 skill-creator/eval-viewer/generate_review.py --help
```
