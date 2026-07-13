# Skill authoring reference

Use this reference while writing or reviewing the skill body. The top-level
`SKILL.md` should route here, not repeat this material.

## Skill anatomy

```text
skill-name/
├── SKILL.md                 # metadata plus concise workflow
├── scripts/                 # deterministic or repetitive reusable tools
├── references/              # heavy documentation loaded on demand
└── assets/                  # templates and output assets
```

Every skill needs YAML frontmatter with `name` and `description`. The name uses
lowercase letters, numbers, and hyphens. Keep the description focused on when
the skill applies: concrete tasks, symptoms, contexts, and useful synonyms.
Do not summarize the process there; agents may follow the summary and skip the
body. Keep it under the platform limit and concise enough to scan.

## Progressive disclosure

Organize content in three levels:

1. Metadata: name and trigger description, always visible.
2. `SKILL.md`: the concise workflow loaded when the skill triggers.
3. Bundled references and tools: loaded or executed only when needed.

Keep frequently loaded skills especially lean. Move a long API reference,
large schema, or reusable implementation into a separate file and provide a
clear read-this-when pointer. Add a table of contents to references that are
long enough to require navigation.

## Skill Discovery Optimization

Discovery is a separate concern from workflow. Test the description with
realistic prompts that should trigger and near-miss prompts that should not.
Include casual wording, synonyms, symptoms, tool names, file types, and cases
where the user does not name the skill explicitly. Avoid trivial queries that
the model can solve without consulting a skill.

Use active, behavior-oriented names such as `creating-skills` or
`condition-based-waiting`. Do not use a vague category name when the skill's
core action can be named directly.

## Content patterns

Prefer imperative instructions and explain why a non-obvious rule matters.
Use one excellent, runnable example instead of several mediocre examples in
different languages. Use a table for reference material and a small flowchart
only when a decision or loop is genuinely non-obvious.

Make output contracts explicit when shape matters:

```markdown
## Output contract

Return these sections in this order:
1. Verdict
2. Evidence
3. Recommended action
```

Do not turn a skill into a story about one historical incident. Keep project
specific conventions in the project's instruction file, and automate purely
mechanical constraints with validation rather than prose.

## Lack of surprise

The skill's behavior should match its description and the user's apparent
intent. Do not include malware, exploit instructions, unauthorized access,
deception, or data-exfiltration guidance. A roleplay or stylistic request is
fine when it does not create a harmful operational capability.

## Review checklist

- Does the description answer “when should this be loaded?”
- Is the main file short enough to load without wasting context?
- Are heavy references and reusable tools separated?
- Is every mandatory output element structural rather than a buried reminder?
- Does each example generalize beyond the exact eval prompt?
- Are conditionals keyed to observable facts?
- Are the skill's limits and non-applicable cases clear?
