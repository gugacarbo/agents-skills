# skill-master KNOWLEDGE BASE

**Generated:** 2026-06-11 09:55:28 -0300
**Commit:** 1e1ebb6

## OVERVIEW

`skill-master` is a local skill for drafting, evaluating, benchmarking, and improving Codex/Claude skills. It is more complex than the tracked `commit-changes` skill and contains Python tooling, agent prompt templates, references, and an HTML eval viewer.

## STRUCTURE

```
skill-master/
├── SKILL.md                 # workflow for creating/improving skills
├── dev/tests.test.ts        # focused integration checks for the unified workflow
├── agents/                  # analyzer/comparator/grader prompts
├── references/              # authoring, testing, discipline, and eval schemas
├── scripts/                 # Python eval, benchmark, packaging, validation helpers
├── eval-viewer/             # prompt-approval + result-review viewer HTML and generators
```

## WHERE TO LOOK

| Task                  | Location                                                       | Notes                                                                                 |
| --------------------- | -------------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| Main workflow         | `SKILL.md`                                                     | Explains capture, drafting, eval loop, and description improvement.                   |
| Parse skill metadata  | `scripts/utils.py`                                             | `parse_skill_md()` handles YAML frontmatter.                                          |
| Trigger evals         | `scripts/run_eval.py`                                          | Spawns `claude -p`, creates temporary `.claude/commands` files, removes `CLAUDECODE`. |
| Benchmark aggregation | `scripts/aggregate_benchmark.py`                               | Summarizes repeated eval runs.                                                        |
| Prompt approval UI    | `eval-viewer/generate_prompt_review.py`                        | Lets the user approve or edit draft eval prompts before execution.                    |
| Report generation     | `scripts/generate_report.py`, `eval-viewer/generate_review.py` | Produces human-reviewable output.                                                     |
| Eval schema           | `references/schemas.md`                                        | Read before changing eval JSON shape.                                                 |
| Integration checks    | `dev/tests.test.ts`                                            | Verifies routing references and extended eval metadata.                               |

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
rtk python3 skills/skill-master/scripts/quick_validate.py <skill-path>
rtk python3 skills/skill-master/eval-viewer/generate_prompt_review.py --help
rtk python3 skills/skill-master/scripts/run_eval.py --help
rtk python3 skills/skill-master/eval-viewer/generate_review.py --help
bun test skills/skill-master/dev/tests.test.ts
```
