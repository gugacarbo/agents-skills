# Parallel Waves

Read this only when a wave passed every condition in `SKILL.md` section 3.
Sequential units never need it.

## Setup

- Freeze the integration head: every unit in the wave starts from the same
  integration `HEAD`, and the integration branch does not move while the wave
  runs.
- Choose the integration order before dispatch (plan order). Never integrate
  in completion order.
- For each unit, the controller creates:
  - branch `<integration-branch>-unit-<id>`;
  - linked worktree at `<integration-worktree>.units/<id>`, a sibling of the
    integration worktree, never nested inside it.
- Record `worktree: <path>` for each wave unit in the recovery state.
- Dispatch all implementers of the wave before waiting on any of them. Each
  brief names its own worktree, branch, and expected write set.

## Per-unit completion

Each unit goes through `SKILL.md` section 5 (evidence check, review when its
risk requires it, correction rounds) inside its own worktree before it is
integrated.

## Integration

For each completed unit, in the predetermined order:

1. cherry-pick its commits oldest-first into the integration branch;
2. re-run that unit's focused validation in the integration worktree — units
   were validated in isolation, and combinations are where they break;
3. on success, remove the unit's worktree. Keep its branch until the run ends,
   as a resume reference.

## Conflict fallback

If a cherry-pick has a material conflict, or the post-integration validation
fails because of the combination:

1. abort that unit's cherry-pick (or revert its integrated commits);
2. treat it as evidence that the independence assumption failed;
3. keep already integrated successful units;
4. resume the unit's original implementer to redo it sequentially from the
   current integration head, in the integration worktree, with the conflict as
   context;
5. validate it, and review it again only if its review policy requires it;
6. disable parallel waves for the rest of the run.

Do not build a stale-result protocol, source-to-integration mapping ledger, or
automatic conflict resolver.

## Cleanup

Unit worktrees are internal artifacts of the wave: remove each one after its
unit is integrated or abandoned. The integration worktree and the user's
worktree are never removed without an explicit request.
