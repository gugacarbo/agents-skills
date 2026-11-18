# General

BRIEF: check mechanical edits, callers, imports and accidental behavior changes;
broaden only on a concrete risk signal.

STANDARD: trace explicit requirements to executable behavior; mark material gaps
as partial, missing or unverifiable. Model state, input and transitions; try a
reachable counterexample, including boundaries, ordering and derived state.
Check whether removing/inverting the changed behavior would fail its regression
test; identify realistic bugs hidden by mocks or weak assertions.

Flag distinct specialist risks to the controller. Do not invent requirements.
Use the envelope's output contract.
