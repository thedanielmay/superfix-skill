---
name: superfix
description: >-
  Intelligent development orchestrator - accepts a GitHub issue number or
  freeform description of a bug, feature, UX change, or architecture change
  and drives it to an opened PR with CI green. Classifies the problem,
  assembles the right skill set, and manages the full workflow. Triggers on:
  superfix, issue #N, fix #N, implement #N, or a request to fix, build or
  change something in code.
  It diagnoses first and stops for approval before fixing.
---

# Superfix Orchestrator

Intelligent front-door for all development work. Accepts a GitHub issue or freeform description, classifies the problem, assembles the right skill set, and drives it to an opened PR (CI green, ready for review) without requiring manual skill invocation or step breakdown.

It diagnoses first and stops for approval before fixing: one decision message per run, then the fix, then proof that it worked.

Supersedes `change-pipeline` - do not invoke change-pipeline.

## Model & Effort Policy

Applied automatically. No user configuration required.

| Task category | Model | Effort |
|---------------|-------|--------|
| File reads, symbol lookups, quick checks | Haiku | High |
| Exploration, planning, implementation, review | Sonnet | High |
| Expert panel, brainstorming, complex architecture judgment, ambiguous cross-cutting triage | Opus | High |

State model+effort inline at every dispatch: `[sonnet/high - codebase exploration]`

Skill names are Claude Code names. If a name does not resolve, use the opencode equivalent from the inventory; if neither exists, do the step inline from its stated purpose and write `ran inline: <skill>` in the PR body. Never skip tests or verification.

## Input Handling

| Input form | How to get context |
|------------|-------------------|
| `/issue #N` | `gh issue view N` - read title, body, labels, all comments |
| `/issue "description"`, in a git repo with a GitHub remote | Use the text. Search once: `gh issue list --state open --search "<3 key words>" --limit 5`. Diagnose read-only, keeping the record in the file-mode journal. Question 1 of the decision message offers to create the issue (see journal.md) |
| `/issue "description"`, anywhere else | Use the text. Keep the record in the file-mode journal. No issue question |
| `/issue` (no args) | Ask: "GitHub issue number or describe what needs doing?" |

GitHub steps (comments, closing) run only when an issue exists. Without one,
the same record goes in the file-mode journal outside the repo (see journal.md),
never in the working tree. Read `references/journal.md` before the first
comment, body edit or journal entry.

If `gh issue view` fails (auth error, repo not set, issue not found), surface the error immediately. Do not silently fall back to "no issue" mode - confirm with the user whether to continue without GitHub integration or abort.

## Phase 0 - Problem Profile

Read the full input - body, labels, all comments - before classifying. Never classify from title alone.

Run the Coverage check (Classification Rules) first, then type and tier.

Produce a **Problem Profile**:

```
Coverage:        [Code | Qik configuration | Everything else]  (one per problem)
Trigger:         ["<the exact words from the report that matched>"]
Evidence:        [one observation that confirms it, e.g. the file exists]
Primary type:    [bug | performance | ux | architecture | security | feature]
Secondary type:  [optional - set when issue spans two types]
Complexity tier: [Simple | Moderate | Complex]  ← provisional; confirmed after exploration
Skill manifest:  [ordered skills - merged from primary + secondary paths if compound]
Expert panel:    [yes - all Moderate and Complex]
Agent execution: [yes - all Moderate and Complex]
```

**Compound issues:** When an issue spans two types (e.g. bug + security, UX + performance), set both `primary_type` and `secondary_type`. Merge skill manifests - run Phase 1 exploration tools from both types; append Phase 3 execute additions from the secondary type to the primary path.

Do not post it as a comment. The Problem Profile goes in the AI detail part of the one decision comment at the Stop gate.

State it in conversation if no issue.

## GitHub Issue as Work Journal

When working from a GitHub issue, the issue is the single source of truth for the work. The body template, the progress comment triggers and the comment format are in `references/journal.md` (in this skill's base directory). Read it in full as soon as an issue is referenced or the file-mode journal is needed, before the first comment, body edit or journal entry, and write `Loaded: journal.md` in the decision comment.

## Classification Rules

### Coverage check (before type and tier)

| Row | Matches when the report mentions | I can |
|-----|----------------------------------|-------|
| Code | files in this repo, a test, a stack trace, CLI or page output from this repo | diagnose and fix |
| Qik configuration | a Qik interface, section, form, role, workflow, definition, a qik.dev link | diagnose and fix in the draft only (provisional: not yet proven by a test) |
| Everything else | documents, process, sheets, business, anything not above | diagnose only, low confidence |

Write the result in the Coverage, Trigger and Evidence lines at the top of the Problem Profile.
The plain coverage line for the decision message is in `references/journal.md`.
Never name a row without the quoted trigger and the evidence.
A report with several problems: check each problem separately. Problems in
"Everything else" stop at diagnosis even after approval.
Several problems are "P1, P2"; "compound" still means one issue spanning two types.

### Type detection (apply in priority order; security signals win over every other type)

| Signals | Type |
|---------|------|
| Labels: `security`, `vuln`, `cve`; keywords: "injection", "auth bypass", "XSS", "CSRF", "exposed", "CVE", "vulnerability" | `security` |
| Labels: `bug`, `regression`; keywords: "broken", "error", "exception", "crash", "not working", "fails" | `bug` |
| Labels: `performance`, `perf`, `optimization`; keywords: "slow", "latency", "N+1", "cache", "index", "timeout" | `performance` |
| Labels: `ui`, `ux`, `frontend`, `design`, `a11y`; keywords: "layout", "style", "visual", "animation", "mobile", "component", "accessibility" | `ux` |
| Labels: `architecture`, `refactor`, `epic`; cross-cutting scope, multiple subsystems, structural change | `architecture` |
| Everything else | `feature` |

If a security signal and another type both match (for example "XSS error"), `security` is primary and the other type is secondary (see Compound issues).

### Complexity tier (provisional from issue text; confirmed after exploration)

| Tier | Criteria |
|------|----------|
| **Simple** | 1-3 files, fix obvious from description, no design decisions |
| **Moderate** | Multiple files, some design choices, scope is clear |
| **Complex** | Architectural impact, unclear scope, cross-cutting concerns, or risky changes |

**Complexity can be upgraded** (Simple→Moderate, Moderate→Complex) after exploration reveals more scope. It cannot be downgraded.

**Already-fixed escape hatch:** If exploration reveals the issue is already resolved on current `main`, post the repro evidence showing it already works and ask the user before closing. Never close someone's issue on agent judgement alone - do not run the pipeline for a non-issue until the user confirms.

## Phase 1 - Explore and Diagnose

Run before writing a single line of code. Exploration is type-aware.
Read `references/explore.md` and `references/diagnose.md` in full now. Run the
exploration for the primary (and secondary) type inside the diagnosis method:
the exploration skills collect the evidence, the method decides what it proves.
Diagnosis does not fix anything. Before approval the only writes allowed are
the journal, a scratch folder outside the repo, and a detached worktree in that
folder (removed before the stop). No branch. No edits to tracked files. No Qik
writes. Write `Loaded: explore.md, diagnose.md` in the decision comment, or in
your next message to the user if there is no issue.

### After exploration: confirm complexity tier

Re-assess the provisional tier. If scope is larger than described, upgrade and state why. Put the confirmed tier in the decision comment.

End of Phase 1, every tier: write `## Problems` (the evidence note: failing
check and its output, baseline numbers, cause confirmed or suspected, ruled
out and how, Tools used). Later steps read evidence from here.

## Stop gate

Every tier, every run, unless the fast lane was asked for in this run.

1. ## Problems, ## Options and ## Done when are written (journal.md template).
   The ## Done when section quotes the owner's own description of the problem (redacted):
   that is the acceptance criterion.
2. Status line: "Waiting for you: <N> questions".
3. Run the redaction check (below), then post ONE decision comment, or write
   it to the file-mode journal. It holds every question for this run,
   numbered, each with the recommended answer, the effort and the budget.
   Simple with one problem: three lines (problem, fix, effort) and "Go?".
4. Say the same in chat and END THE TURN. Do not create a branch, edit a
   tracked file, write to Qik, read references/execute.md or
   references/briefs.md, or start any Phase 2 or 3 step until a go arrives.

Go: "yes", "go", "1 yes, 2 option two", "keep going", "keep executing", "do
it", or any reply that answers every question. "Keep going" style replies
accept every recommendation. A reply that answers only some questions: ask
only the rest. Anything else (a question, a new fact): answer it, update the
record, stay stopped.

On go: write ## Decision (below) as a body update, no comment. Record
approval-sha = `git rev-parse origin/<default-branch>` and the approval time.
Status "Fixing problem 1 of <N>".

Fast lane: only when THIS run's request says so ("just fix it", "don't
wait"). Only for one problem, Simple tier, row Code, type not security.
Still run Phase 1 and write ## Problems; post the decision message as a
notice and continue. Otherwise say in one line why it does not apply, and stop.

### Decision and redaction

Write the ## Decision section only after the owner answers, in your own
words: what was chosen, for which problem, any condition. Never paste the owner's message.
Example: "P1: option A (fix the loop bound). Budget as proposed. Approved by the
owner in chat, 2026-10-19 14:32. approval-sha: <40 hex>."

Keep a session list of every credential, password or token the owner gives you,
in any message. Before ANY push, issue create, comment, body edit, PR create or
--body-file, run the redaction check in references/redaction.md over the diff,
the commit messages and every body file. A match blocks the post until
redacted. If something already leaked: delete the comment (never edit it,
GitHub keeps edit history), tell the owner to rotate the credential, and say
what leaked where.

## Phase 2 - Design & Plan

Applies to **Moderate and Complex** only. Simple goes to Phase 3 after the Stop gate.

### Design step (type-specific, before writing-plans)

| Type | Design approach |
|------|----------------|
| `bug` | No design step - exploration output feeds directly into plan |
| `performance` | Plan based on measured baseline; state target improvement metric |
| `ux` | `superpowers:brainstorming` [opus/high] → `ui-ux-pro-max` or `impeccable` sub-skill as appropriate → `accessibility` (WCAG 2.2 check) |
| `architecture` | `superpowers:brainstorming` [opus/high] - explore structural options before committing |
| `security` | Threat model, done inline (no skill of this name exists; `security-audit` can inform it): identify trust boundaries and attack surface [opus/high] |
| `feature` | `superpowers:brainstorming` [opus/high] (Moderate/Complex only) |

### Plan

Invoke `superpowers:writing-plans` [sonnet/high]. Save to `docs/superpowers/plans/YYYY-MM-DD-<slug>.md`.

Plan must document:
- What files change and why
- Key design decisions made
- What is explicitly NOT in scope
- For performance: baseline measurement and target

### Context file

After plan is written, create the context file `docs/superpowers/plans/<slug>-context.md` from the template in `references/journal.md` (Context file).

**Pass this file path to every execution subagent.** Every execution subagent reads the same source of truth. Diagnosis agents get the fan-out brief instead (`references/diagnose.md`).

### Expert panel (all Moderate + Complex - blocking)

Invoke `expert-panel` [opus/high] after plan is written, at the plan→implementation joint.

- Format: synthesised must-fixes / should-fixes / verdict only - no per-panelist narration
- Must-fix findings addressed before implementation proceeds
- Update the plan with any must-fix resolutions
- Post comment if issue exists:
  the plan comment in `references/journal.md`, posted with `--body-file`.

**Max 2 expert panel passes.** If must-fix items remain after pass 2, escalate to the user with specific questions.

If the panel overturns the approved option or breaks the approved budget, go back to the owner at once with one batched decision message (Stop gate form) and wait. That is not a pass. Must-fix items left after pass 2 go to the owner in the same message form.

## Phase 3 - Execute

Before implementing, Read `references/execute.md` in full (this skill's base directory). It holds the execute sequences by type, the code review rules and the test scope. Write `Loaded: execute.md` in the final comment, or in your next message to the user if there is no issue.

### Budget

Proposed in the decision message, fixed at approval. Defaults:
  Simple:   6 commits, 2 hours, the files named in ## Options plus their tests
  Moderate: 15 commits, 4 hours, the files in the plan plus their tests
  Complex:  as stated in the plan
Plain wording: "Up to 2 hours, touching these 3 files. I stop and ask if I go over."

Measure before every commit (main thread or fix agent):
  commits: git rev-list --count <approval-sha>..HEAD -- . ':(exclude)docs/superpowers/plans'
  files:   git diff --name-only <approval-sha>...HEAD   (any file not named = over)
  time:    date, minus the approval time in ## Decision
  Qik:     draft writes made as part of the fix (writes made only to verify do not count)
The journal is outside the repo, and plan commits are excluded, so neither counts.
Over any limit: stop. A fix agent returns a message whose first line is exactly
BUDGET STOP; the main thread posts it (callout first), sets the status line to
"Stopped: over budget (<which>)" and ends the turn. Offer: 1 extend, 2 cut
scope, 3 stop. Never continue past a limit on your own.
Max 2 review passes and max 2 expert panel passes are unchanged.

### Qik configuration (provisional)

Qik configuration (provisional). Load the qik skill first. No branch.
1. Back up before the first edit: the exact before text and the undo step, in a
   folder outside any repo. No backup, no edit.
2. Edit the draft only. Never publish. Say "in the draft", never "live".
3. Close the issue only after the owner replies "published" and the change is
   checked on the live site. The ready message ends: 'Reply "published" when
   you have published. To undo, tell me "undo P1". The backup is in <folder>.'
4. If the qik skill has no backup recipe for what you are changing, stop and
   ask. Do not invent one.
Qik records solved-check runs 1 and 2 only; run 3 (restore, then re-apply) goes under Not tested.

### Simple path (main thread, no agent)

Create branch before touching any file (shared block, both paths):
```bash
git status --porcelain            # must print nothing, else stop and ask
git fetch origin
git switch -c <fix|feature>/<N-or-date>-<slug> origin/<default-branch>
```
`<N-or-date>` is the issue number, or today's date for freeform work. That prevents slug collisions.

```
create branch → (bug: failing test or repro command first) → implement → impacted tests
→ simplify → re-run impacted tests → code-reviewer (issue text passed inline as the brief)
→ code-security-audit ONLY IF the diff touches auth, input parsing, SQL, shell, secrets or dependencies
→ verification-before-completion → PR
```

### Moderate + Complex path (autonomous agent)

Create branch with the shared block above before dispatching the agent. Architecture: create the worktree from `origin/<default-branch>` instead of creating a branch first.

Invoke `Agent` tool [sonnet/high for implementation; opus/high for architecture judgment]. Pass:
- Branch name
- Context file path
- Plan file path
- Problem Profile (type, tier, skill manifest)
- Model/effort policy: most appropriate model per task, high effort
- Absolute path of `references/execute.md`. The agent reads it first. Agents do not load this file, so they only know what the brief tells them.
- Absolute path of `references/briefs.md`, with its fix agent brief copied into the prompt.
- The budget and approval-sha from `## Decision`.
- The session redaction file path and the absolute path of `references/redaction.md`.

Agent runs the full execute sequence autonomously. Surfaces only:
- Blockers requiring human judgment (with specific question, not just "stuck")
- Final PR link when complete
- A message starting BUDGET STOP (the main thread posts it, see Budget)

Before posting anything the agent returns, the main thread re-runs the budget commands and the redaction check itself.

The agent ticks the plan file's task checkboxes as each task completes.

On restart (limit, crash, new session): read the Status line, `## Problems` and `## Decision` (issue body or journal file), the latest progress comment on the issue (if any), the plan file's task checkboxes if a plan exists, and `git log` on the branch. Continue from the first unfinished stage. Do not redo finished stages.

### Solved check

Runs inside `verification-before-completion`, on both paths. Code only (Qik: see above).
"Solved" means three runs, each recorded with output in the final comment:
  Run 1, base fails:   the failing check from ## Problems, on approval-sha.
  Run 2, fix passes:   the same check on the branch.
  Run 3, revert fails: in a scratch worktree of HEAD, reverse-apply the
     non-test part of `git diff <approval-sha>...HEAD`, run the check, expect
     failure, remove the worktree. The branch is never touched.
Run 2 must also show the owner's description quoted in ## Done when no longer
holds.
If run 3 passes, the check does not detect the problem: fix the check, not the
code, and re-run all three.
When run 3 does not apply, say why in one line and put it under Not tested:
  - refactor meant to keep behaviour: no failing check exists; full suite
    passes before and after instead
  - new feature whose check cannot run without it: run 3 fails by import or
    missing command; record that, it still counts
Two failed run-2 attempts, whatever the cause given: stop. Post:
  "My fix failed twice, so my diagnosis was wrong. Work kept on the branch.
   Used 1h10 of 2h. 1 re-diagnose (about 20 min), 2 stop."
Status "Waiting for you: 1 question". Never re-diagnose quietly.

### Execute sequences by type, code review rules, test scope

These are in `references/execute.md`. Read it in full before implementing (see the start of Phase 3).

## Phase 4 - Close

Invoke `superpowers:finishing-a-development-branch` [sonnet/high]. Standard choice: push and create PR. The PR body includes `Closes #<N>` so GitHub closes the issue when the PR merges into the default branch.

If the repo has CI, run `gh pr checks <PR> --watch`. Fix red checks under the same review rules (two passes, then escalate).
Post the final comment only after checks are green, or after two fix passes with the red checks listed.

The PR body and the final comment both end with:
## Not tested
- <each thing not checked, and why>
An empty list says "Nothing known untested". Never leave it out.

If GitHub issue exists, post the final comment from `references/journal.md` and set the Status line to "Ready for review: PR <link>". Without an issue, write it as a journal entry and say it in chat.

If the PR targets a non-default branch, `Closes` does not fire. Close manually only after `gh pr view <PR> --json state -q .state` returns `MERGED`.

## Shortcuts

| Situation | Shortcut |
|-----------|----------|
| Plan already exists in `docs/superpowers/plans/` | Run exploration as normal; skip design step and `writing-plans`; create context file from existing plan; verify plan reflects current codebase state before expert panel. The Stop gate still applies; offer the existing plan as the recommended option. |
| PR already exists | Use `pr-review-toolkit:review-pr` instead of `code-reviewer` in execute phase |

## Red Flags

- Classifying from title alone - always read full body, labels, and all comments first
- Triaging complexity before exploring the codebase
- Skipping exploration for any tier
- Starting implementation on Moderate/Complex without an approved plan
- Skipping expert panel on Moderate or Complex
- Execution subagents without the context file and briefs.md - undefined hand-offs produce blind reviews
- Claiming tests pass without a fresh run
- Declaring done without checking the original goal was actually achieved
- Upgrading Simple→Moderate/Complex after implementation has started - stop, commit/stash partial work, return to Phase 2, write a plan accounting for what's already implemented, run expert panel, then send a decision request with the new budget and wait
- Closing a GitHub issue without confirming the PR is merged
- Invoking `change-pipeline` - it is superseded; do not use
- Updating only GitHub comments but never the issue body - the body is the living spec; let it drift and the issue becomes unreadable out of context
- Editing the issue body for progress updates instead of adding a comment - body = current state, comments = history (except the Status line and ## Decision, which are body updates by design)
- Starting any fix, branch or tracked-file edit on any tier before the Stop gate gets a go
- Posting, pushing or creating anything before the redaction check
- Naming a coverage row without a quoted trigger and evidence
- Calling it fixed without the solved check (three runs, with output)

## Out of Scope

- `roadmap-planning` - sits above this orchestrator; invoke separately for planning work
- Observability tooling - post-deployment concern; not part of pre-merge workflow

## Skill Inventory Reference

The table of every skill this orchestrator can employ, with the opencode name or fallback for each, is in `references/inventory.md`. Read it only when a named skill does not resolve (see Model & Effort Policy).
