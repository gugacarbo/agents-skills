---
name: init-deep
description: Generate hierarchical AGENTS.md documentation across the codebase. Use whenever the user wants to initialize, regenerate, or update AGENTS.md files. Supports two modes: default (complete) generates AGENTS.md for every directory with a full template; --light uses selective scoring and telegraphic style. Invoked as /init-deep or /init-deep --light.
user-invocable: true
argument-hint: "[project path] [--light] [--max-depth=N] [--create-new]"
effort: high
---

# /init-deep

Generate hierarchical AGENTS.md files. Two modes:

- **Default (complete)** — AGENTS.md in every directory, full template with Key Files, Subdirectories, For AI Agents, Dependencies. Use for comprehensive documentation across the whole codebase.
- **`--light`** — Scoring-based selection (only dirs with score > 8), telegraphic 30-80 line templates. Use for minimal, essential-only documentation.

## Usage

```
/init-deep                              # Full mode: all directories, verbose template
/init-deep --light                      # Light mode: selective directories, telegraphic template
/init-deep --light --max-depth=2        # Light mode, limit depth
/init-deep --create-new                 # Full mode: regenerate from scratch
/init-deep --light --create-new         # Light mode: regenerate from scratch
```

## Mode Comparison

| Aspect                | Default (full)                                     | --light                                                                     |
| --------------------- | -------------------------------------------------- | --------------------------------------------------------------------------- |
| **Where**             | Every directory                                    | Only score > 8 (see Scoring Matrix)                                         |
| **Template size**     | Full (Key Files, Subdirs, AI Agents, Dependencies) | Telegraphic (OVERVIEW, WHERE TO LOOK, CONVENTIONS, ANTI-PATTERNS, COMMANDS) |
| **Root target**       | ~100-200 lines                                     | 50-150 lines                                                                |
| **Subdir target**     | ~50-100 lines                                      | 30-80 lines                                                                 |
| **Parent references** | `<!-- Parent: ../AGENTS.md -->`                    | None                                                                        |
| **Key content**       | Everything is documented                           | Only non-obvious, project-specific info                                     |
| **Best for**          | New projects, team onboarding                      | Mature codebases, personal projects                                         |

## Common Workflow (both modes)

### Phase 1: Discovery + Analysis (parallel)

1. **Explore agents** — launch concurrent explore agents for structure, entry points, conventions, anti-patterns, build/CI, test patterns
2. **Bash analysis** — directory depth, file distribution, code hotspots, existing AGENTS.md
3. **Read existing** — extract current AGENTS.md content, conventions, manual sections
4. **LSP codemap** — if available, get entry points and symbol density

For `--light` mode, also compute the **Scoring Matrix** (see separate section below).

### Phase 2: Decide locations

- **Default**: use every directory with content (skip empty dirs, generated-only dirs, config-only dirs — see Empty Directory Handling)
- **`--light`**: apply Scoring Matrix, only create where score > 8

### Phase 3: Generate (root first, subdirs in parallel)

Generate root AGENTS.md first, then spawn parallel agents for subdirectories.

### Phase 4: Review

Deduplicate, trim to limits, verify telegraphic style (light) or completeness (full).

## Default Mode: Deep Init

### AGENTS.md Template (full)

```markdown
<!-- Parent: {relative_path_to_parent}/AGENTS.md -->
<!-- Generated: {timestamp} | Updated: {timestamp} -->

# {Directory Name}

## Purpose

{One-paragraph description}

## Key Files

| File      | Description                  |
| --------- | ---------------------------- |
| `file.ts` | Brief description of purpose |

## Subdirectories

| Directory | Purpose                                   |
| --------- | ----------------------------------------- |
| `subdir/` | What it contains (see `subdir/AGENTS.md`) |

## For AI Agents

### Working In This Directory

{Special instructions for AI agents modifying files here}

### Testing Requirements

{How to test changes in this directory}

### Common Patterns

{Code patterns or conventions used here}

## Dependencies

### Internal

{References to other parts of the codebase this depends on}

### External

{Key external packages/libraries used}

<!-- MANUAL: Any manually added notes below this line are preserved on regeneration -->
```

### Hierarchy

Every AGENTS.md (except root) includes a `<!-- Parent: -->` tag:

```
/AGENTS.md                          ← Root (no parent tag)
├── src/AGENTS.md                   ← <!-- Parent: ../AGENTS.md -->
│   ├── src/components/AGENTS.md    ← <!-- Parent: ../AGENTS.md -->
│   └── src/utils/AGENTS.md         ← <!-- Parent: ../AGENTS.md -->
└── docs/AGENTS.md                  ← <!-- Parent: ../AGENTS.md -->
```

### Empty Directory Handling (Default Mode)

| Condition                                  | Action                                            |
| ------------------------------------------ | ------------------------------------------------- |
| No files, no subdirectories                | **Skip**                                          |
| No files, has subdirectories               | Minimal AGENTS.md with subdirectory listing only  |
| Has only generated files (*.min.js, *.map) | Skip or minimal AGENTS.md                         |
| Has only config files                      | Create AGENTS.md describing configuration purpose |

### Parallelization Rules

1. **Same-level directories**: Process in parallel
2. **Different levels**: Sequential (parent first)
3. **Large directories**: Spawn dedicated agent per directory
4. **Small directories**: Batch multiple into one agent

### Update Mode (existing AGENTS.md)

1. Detect existing files first
2. Read and parse existing content
3. Analyze current directory state
4. Compare and merge (update auto-generated, preserve `<!-- MANUAL -->` sections)

---

## Light Mode: Scoring-Based Documentation

### Scoring Matrix

| Factor               | Weight | High Threshold           | Source                      |
| -------------------- | ------ | ------------------------ | --------------------------- |
| File count           | 3x     | >20                      | bash                        |
| Subdir count         | 2x     | >5                       | bash                        |
| Code ratio           | 2x     | >70%                     | bash                        |
| Unique patterns      | 1x     | Has own config           | explore                     |
| Module boundary      | 2x     | Has index.ts/**init**.py | bash                        |
| Symbol density       | 2x     | >30 symbols              | lsp_workspace_symbols count |
| Reference centrality | 3x     | >20 refs                 | lsp_find_references count   |

### Decision Rules (Light Mode)

| Score        | Action                    |
| ------------ | ------------------------- |
| **Root (.)** | ALWAYS create             |
| **>15**      | Create AGENTS.md          |
| **8-15**     | Create if distinct domain |
| **<8**       | Skip (parent covers)      |

### AGENTS.md Template (Light Mode)

```markdown
# PROJECT KNOWLEDGE BASE

**Generated:** {TIMESTAMP}
**Commit:** {SHORT_SHA}

## OVERVIEW

{1-2 sentences: what + core stack}

## STRUCTURE

{Tree with non-obvious purposes only}

## WHERE TO LOOK

| Task | Location | Notes |

## CONVENTIONS

{ONLY deviations from standard}

## ANTI-PATTERNS (THIS PROJECT)

{Explicitly forbidden here}

## COMMANDS

{dev/test/build}
```

---

## Anti-Patterns (both modes)

- Sequential execution → MUST parallel where possible
- Ignoring existing → ALWAYS read first, even with --create-new
- Over-documenting (light) → not every dir needs AGENTS.md
- Redundancy → child never repeats parent
- Generic content → remove anything applying to ALL projects
- Static agent count → vary by project size/depth
- Generic boilerplate → every file must have accurate descriptions
- Broken parent references (full mode) → validate after generation
