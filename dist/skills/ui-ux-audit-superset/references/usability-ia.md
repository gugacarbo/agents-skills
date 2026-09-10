# Usability and Information Architecture

Use this module to review task completion, clarity, navigation, information architecture, efficiency, feedback, error recovery, and cognitive load.

## 1. Start from the user's task

For each important surface, identify:

- What is the user trying to accomplish?
- What information do they need before acting?
- What is the primary action?
- What happens after the action?
- How does the user cancel, go back, or recover?
- What knowledge is the UI assuming?

A screen should make the next useful action understandable without requiring users to reverse-engineer the interface.

## 2. Task efficiency

Inspect:
- unnecessary steps;
- repeated data entry;
- avoidable confirmation screens;
- buried frequent actions;
- repeated context switching;
- redundant navigation;
- excessive modal chains;
- repeated settings that could use sensible defaults.

A “three interactions or fewer” target may be a useful warning signal for simple tasks, but it is not a universal rule. Judge interaction count against task complexity and risk.

## 3. Action hierarchy

Prefer:
- one obvious primary action for the current task;
- at most a small number of competing high-emphasis actions;
- secondary actions visually quieter;
- rare/advanced actions progressively disclosed;
- destructive actions separated from routine actions.

Flag:
- multiple buttons that all appear primary;
- a primary action hidden in overflow while low-value actions are prominent;
- disabled primary controls without explanation;
- icons whose meaning requires guessing.

## 4. Visibility of system status

Users should be able to tell:
- whether input was accepted;
- whether work is saving;
- whether processing is still happening;
- whether an action succeeded;
- whether an error occurred;
- whether displayed data is stale or current when that distinction matters.

Avoid ambiguous inactivity.

## 5. Match the user's mental model

Use product/domain language rather than internal implementation vocabulary.

Check:
- labels;
- entity names;
- grouping;
- ordering;
- units;
- date/time conventions;
- workflow sequence.

Do not expose database/framework terminology unless users actually use that terminology.

## 6. User control and freedom

Check:
- clear back/cancel/close behavior;
- reversible actions where appropriate;
- undo for low-cost reversible destructive changes;
- confirmation for high-risk irreversible changes;
- no forced dead ends;
- navigation does not unexpectedly discard work.

## 7. Consistency and predictability

Equivalent things should:
- look equivalent;
- have equivalent names;
- appear in predictable locations;
- behave equivalently.

Check:
- save semantics;
- dialog buttons;
- keyboard behavior;
- row actions;
- filters;
- pagination;
- breadcrumbs;
- success/error feedback.

## 8. Error prevention

Prefer preventing an error over explaining it later when practical.

Check:
- duplicate submission protection;
- dangerous defaults;
- destructive confirmations;
- impossible combinations;
- invalid dates/ranges;
- accidental navigation with unsaved changes;
- permissions surfaced before users invest unnecessary work.

## 9. Error recovery

A useful error explains:
1. what failed;
2. what it affects;
3. what the user can do next.

For data-entry errors:
- preserve entered values;
- identify the specific fields;
- move or direct focus appropriately;
- avoid clearing the form.

## 10. Recognition over recall

Keep needed context visible.

Examples:
- show selected filters;
- retain relevant record identity in dialogs;
- show units beside values;
- show previous choices where useful;
- do not require users to remember a code from a previous screen if it can be carried forward safely.

## 11. Flexibility and efficiency

Where appropriate support:
- keyboard operation;
- bulk actions;
- good defaults;
- search;
- filtering;
- saved state;
- shortcuts for expert users;
- efficient tab order.

Do not optimize expert efficiency at the expense of discoverability for normal users without a reason.

## 12. Information architecture

Review:
- main navigation;
- grouping of features;
- naming;
- hierarchy depth;
- findability;
- route/page titles;
- breadcrumbs for deep structures;
- search/filter relationship;
- page orientation.

Questions:
- Can users tell where they are?
- Can they predict where a feature lives?
- Are categories mutually understandable?
- Are closely related features unnecessarily separated?
- Are unrelated concepts combined under vague labels?

## 13. Navigation state

Inspect:
- current section highlighting;
- back behavior;
- scroll position restoration where useful;
- selected filters/tabs after returning;
- deep links;
- browser history;
- Cmd/Ctrl-click and middle-click for navigational links.

## 14. Onboarding and discoverability

When a feature is non-obvious:
- explain it at introduction or first use;
- prefer contextual guidance to long documentation;
- use smart defaults;
- avoid making users configure everything before seeing value.

Do not add tutorials for self-evident controls.

## 15. Help

Where help is needed:
- keep its location consistent;
- make contact/help mechanisms easy to find;
- make inline help task-specific;
- avoid help that merely repeats the label.

## 16. Dense/data-heavy applications

Do not mistake density for poor UX.

Evaluate whether density:
- supports expert workflows;
- preserves scanning;
- uses alignment and grouping;
- gives clear status and action hierarchy;
- remains accessible and responsive.

A professional operational dashboard can be intentionally dense and still excellent.
