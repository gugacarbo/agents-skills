# Usage enhancement

Add a public `summarize_usage(events)` function in `src/usage.py`. Each event must be a mapping. Ignore an event before inspecting its `units` when `user` is missing or blank. For retained events, require `user` to be a nonblank string and `units` to be an integer >= 0; booleans do not count as integers. Return totals keyed by the exact user string, preserving first-seen order. Reject malformed retained events with `ValueError`. Add focused public tests. Do not add dependencies.

Acceptance: `python3 -m unittest discover -v` passes; empty input returns `{}`; repeated users are summed; invalid retained events raise `ValueError`.
