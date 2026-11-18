# Design

Inspect existing architecture and canonical primitives. Check moved callers,
imports, public contracts, dependency direction, ownership and behavior preservation.
Report boundary violations or competing mechanisms only with an intended repository
rule and concrete consequence, including ambiguity that causes incorrect reuse.
Prefer reuse, deletion or consolidation before new abstractions; avoid theoretical
purity and broad rewrites. Use the envelope's output contract.
