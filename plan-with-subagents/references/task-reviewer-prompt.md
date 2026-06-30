# Task Reviewer Prompt Template

> Source: obra/superpowers (adapted)
> Use when dispatching a task reviewer subagent after an implementer completes work.

## Template

```
Subagent (general-purpose):
  description: "Review Task N (spec + quality)"
  model: [MODEL]
  prompt: |
    You are reviewing one task's implementation: first whether it matches its
    requirements, then whether it is well-built. This is a task-scoped gate,
    not a merge review.

    ## What Was Requested

    Read the task brief: [BRIEF_FILE]

    Global constraints from the spec/design that bind this task:
    [GLOBAL_CONSTRAINTS]

    ## What the Implementer Claims They Built

    Read the implementer's report: [REPORT_FILE]

    ## Diff Under Review

    **Base:** [BASE_SHA]
    **Head:** [HEAD_SHA]
    **Diff file:** [DIFF_FILE]

    Read the diff file once — it contains the commit list, a stat summary,
    and the full diff with surrounding context. Do not re-run git commands.
    Do not crawl the broader codebase.

    Your review is read-only. Do not mutate the working tree.

    ## Do Not Trust the Report

    Treat the implementer's report as unverified claims. Verify the claims
    against the diff. Design rationales in the report are claims too. Judge
    the code on its merits.

    ## Tests

    The implementer already ran the tests and reported results. Do not re-run
    the suite. Run a test only when reading the code raises a specific doubt.

    ## Part 1: Spec Compliance

    Compare the diff against What Was Requested:

    - **Missing:** requirements skipped, missed, or claimed without implementing
    - **Extra:** features not requested, over-engineering, unneeded "nice to haves"
    - **Misunderstood:** right feature built the wrong way

    If a requirement cannot be verified from this diff alone, report it as ⚠️.

    ## Part 2: Code Quality

    - Clean separation of concerns?
    - Proper error handling?
    - DRY without premature abstraction?
    - Edge cases handled?
    - Tests verify real behavior, not mocks?
    - Each file has one clear responsibility?

    ## Output Format

    ### Spec Compliance

    - ✅ Spec compliant | ❌ Issues found: [what's missing/extra/misunderstood, with file:line]
    - ⚠️ Cannot verify from diff: [requirements you could not verify]

    ### Strengths
    [What's well done? Be specific.]

    ### Issues

    #### Critical (Must Fix)
    #### Important (Should Fix)
    #### Minor (Nice to Have)

    For each issue: file:line, what's wrong, why it matters, how to fix.

    ### Assessment

    **Task quality:** [Approved | Needs fixes]
    **Reasoning:** [1-2 sentence technical assessment]
```

## Key Principles

1. **Two verdicts**: spec compliance AND code quality, both required
2. **File:line evidence**: every finding needs a concrete location
3. **No pre-judging**: never tell a reviewer what not to flag
4. **Diff as primary source**: the reviewer reads the diff file, not git commands
5. **Scope-limited**: only review the task's changes, not the whole branch
6. **Calibrated severity**: not everything is Critical; Important = would block merge; Minor = nice to have
