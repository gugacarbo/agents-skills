# Models

Use exactly two profiles. Resolve once: user mapping → repository mapping → models
exposed by the harness. Optional skill convention (not native harness config):

```yaml
review_models:
  fast: <available model ID>
  strong: <available model ID>
```

Without mappings, choose exposed fast/economical and complex-reasoning models.
Never guess IDs/availability or silently replace an unavailable explicit mapping.
If controls or a suitable mapping are absent, disclose inherited/unknown execution
and use only an authorized fallback.

| Task                                              | Profile / preferred effort |
| ------------------------------------------------- | -------------------------- |
| General BRIEF                                     | fast / low                 |
| General STANDARD or Design, bounded reasoning     | fast / medium              |
| General or Design, complex cross-layer invariants | strong / high              |
| Risk or Adversarial FINAL_PASS                    | strong / high              |

Set actual supported dispatch parameters; prose cannot override models. Respect
schema constraints on history and overrides; supply a self-contained envelope when
history cannot be inherited. Unsupported effort uses a supported default with
disclosure, never invalid retries. Avoid maximal effort by default.

Record profile, requested model/effort and fallback. Claim verified execution only
when metadata confirms it. Escalation follows SKILL.md; missing evidence and zero
findings are not reasons to repeat a review with strong.
