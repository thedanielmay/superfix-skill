# Phase 2 and dispatch (Moderate and Complex)

New in 1.7.5 ([superfix-skill#144](https://github.com/thedanielmay/superfix-skill/issues/144)). SKILL.md (Phase 2) says when to read this file: in full, at go, before Phase 2, together with execute.md, on every Moderate or Complex run. These are rules for the main thread, so briefs.md (which is pasted into the fix agent's prompt) does not hold them. The blocks moved here word for word from SKILL.md. The plan comment and the context file template moved here word for word from `journal.md` in 1.7.7 (#144 step C); "Comment format above" in the plan comment means `journal.md` (Comment format). Simple runs never read this file. "The shared block above" in the dispatch section is SKILL.md's branch block under Simple path.

### Expert panel
Invoke `expert-panel` [opus/high] after plan is written, at the plan→implementation joint.

- Format: synthesised must-fixes / should-fixes / verdict only - no per-panelist narration
- Must-fix findings addressed before implementation proceeds
- Update the plan with any must-fix resolutions
- Post comment if issue exists:
  the plan comment (Plan comment, below), posted with `--body-file`.

**Max 2 expert panel passes.** If must-fix items remain after pass 2, escalate to the user with specific questions.

If the panel overturns the approved option or breaks the approved budget, go back to the owner at once with one batched decision message (Stop gate form) and wait. That is not a pass. Must-fix items left after pass 2 go to the owner in the same message form.

### Moderate and Complex dispatch
Create branch with the shared block above before dispatching the agent (except Qik work, which has no branch). Architecture: create the worktree from `<approval-sha>` instead of creating a branch first.

By default invoke `Agent` tool [sonnet/high for implementation; opus/high for architecture judgment]. If the user has their own rule that sends build work to another executor, for example a global instruction file, follow that rule for implementation steps instead. Other users keep this dispatch. Pass:
- Branch name
- Context file path
- Plan file path
- Problem Profile (type, tier, skill manifest)
- Model/effort policy: most appropriate model per task, high effort
- Absolute path of `references/execute.md`. The agent reads it first. Agents do not load this file, so they only know what the brief tells them.
- Absolute path of `references/briefs.md`, with its fix agent brief copied into the prompt.
- The budget and approval-sha from `## Decision`.
- The session list path `~/.superfix/runs/<run-key>/secrets`, written out in full, and the absolute path of `references/redaction.md`.
- When a problem has a before picture: the absolute path of `references/evidence.md`, the BROWSER-SCRIPT interpreter and the run folder (each picture's `evidence/<name>.json` says how to retake it).

Agent runs the full execute sequence autonomously. Surfaces only:
- Blockers requiring human judgment (with specific question, not just "stuck")
- Final PR link when complete
- A message starting BUDGET STOP (the main thread posts it, see Budget)

The agent may commit, push and open the PR only after the redaction checks pass (briefs.md states the rule). Issue comments and the Status line are posted by the main thread, which re-runs the budget commands and the redaction checks itself first.
The agent ticks the plan file's task checkboxes as each task completes.

### Plan comment (Moderate, Complex, after the expert panel)

```
> **In plain English:** The plan passed expert review and I am starting the fix. Nothing needed from you now.

Plan: docs/superpowers/plans/<filename>.md
Key decisions: [brief summary]
Labels: <LABELS-NOW>
```
Post it with `--body-file` (Comment format above).

### Context file (Moderate, Complex)

After plan is written, create `docs/superpowers/plans/<slug>-context.md` using this structure:

```markdown
# Context: <slug>

## Problem Profile
- Primary type: <type>
- Secondary type: <type or none>
- Complexity: <tier>
- Skill manifest: <ordered list>

## Problem Description
<full issue text or conversation summary>

## Plan
Path: docs/superpowers/plans/<plan-filename>.md

## Key Decisions from Exploration
- <decision 1>
- <decision 2>

## Relevant Files
- <path>: <why relevant>

## Evidence
<copied from ## Problems in the issue body or journal file>
```
