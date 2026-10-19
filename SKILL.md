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
| `/issue "description"`, in a git repo with a GitHub remote | Use the text. Search once: `gh issue list --state open --search "<3 key words>" --limit 5`. Diagnose read-only, keeping the record in the file-mode journal. The last numbered question of the decision message offers to create the issue (see journal.md) |
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

Write the result in the Coverage, Trigger and Evidence lines at the top of the Problem Profile
(the plain coverage line for the decision message is in `references/journal.md`).
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
Diagnosis fixes nothing. Before approval the only writes allowed are the
journal, a scratch folder outside the repo, and a detached worktree in it
(removed before the stop): no branch, no edits to tracked files, no Qik writes.
Also allowed before approval, PRIVATE repo only: evidence pictures uploaded to
its `assets` release through the upload gate in references/evidence.md, and creating the `assets` release and its tag, only after the workflow and ownership checks, and only for a private repo you own.
Write `Loaded: explore.md, diagnose.md` in the decision comment, or in your next
message if there is no issue.

### After exploration: confirm complexity tier

Re-assess the provisional tier. If scope is larger than described, upgrade and state why. Put the confirmed tier in the decision comment.

End of Phase 1, every tier: write `## Problems`, the evidence note (failing check
and output, baseline, cause confirmed or suspected, ruled out and how, Tools
used). Later steps read evidence from here.

### Evidence pictures: if the problem is something you could see on a screen, take them (read references/evidence.md first)
Read `references/evidence.md` in full before the first picture; write `Loaded: evidence.md` in the decision comment. A web page, app screen, rendered document or UI always counts as a screen: `NONE (no screen)` is only for command output, tests, servers and config.
- Command, test, log and backend output stays text, never an image. Probe first: BROWSER-SCRIPT, BROWSER-MCP (only when the list is NO-LIST) or NO-BROWSER.
- Red box numbered like the problem, one caption that says it all in words. Width or height 0: no mark.
- Upload only with evidence.md's one upload command, only to a PRIVATE repo. Public: upload nothing. Any entry in the secrets list, or a saved login: upload nothing until the owner has looked and replied "post the pictures" (after those pictures, in this run).
- Never paste a session secret into a browser tool call; Claude in Chrome is never a picture source. Never read a mark-*.side file.

## Stop gate

Every tier, every run, unless the fast lane was asked for in this run.

1. The issue body (or journal file) has the Status line, ## Problems, ## Options and ## Done when written (journal.md template) BEFORE the decision comment is posted. A comment without the body update is not a stop.
   The ## Done when section quotes the owner's own description of the problem (redacted):
   that is the acceptance criterion.
   The decision comment's AI detail has the required `Pictures: TAKEN <n> | NONE (no screen: <why>) | NO-BROWSER | HELD (<why>) | LOCAL (public repo) | NOT-POSTED (<why>)` line (journal.md); a stop without it is not complete.
2. Status line: "Waiting for you: <N> questions".
3. Run the redaction check (below), then post ONE decision comment, or write
   it to the file-mode journal. It holds every question for this run,
   numbered, each with the recommended answer, the effort and the budget.
   Simple with one problem: three lines (problem, fix, effort) and "Go?".
   No issue was given and the repo has a GitHub remote: the LAST numbered question is always
   the create-issue question (journal.md). Never leave it out or move it.
4. Say the same in chat and END THE TURN. Do not create a branch, edit a
   tracked file, write to Qik, read references/execute.md or
   references/briefs.md, or start any Phase 2 or 3 step until a go arrives.

Go: "yes", "go", "1 yes, 2 option two", "keep going", "keep executing", "do
it", or any reply that answers every question. "Keep going" style replies
say yes to every question that has a recommended answer. The create-issue
question has none: unless the owner says yes to it explicitly, it is no (keep
the journal file, create nothing), on public and private repos alike. A reply that answers only some questions: ask
only the rest. Anything else (a question, a new fact): answer it, update the
record, stay stopped.
The `assets` release question (evidence.md) has no recommended answer either: anything but an explicit yes to it is no.

On go: write ## Decision (below) as a body update, no comment. Run `git fetch
origin`, then record approval-sha = `git rev-parse origin/<default-branch>` and
the approval time. The work branch starts from that sha, so the budget and the
solved check never count other people's commits.
Status "Fixing problem 1 of <N>".

Fast lane: only when THIS run's request says so ("just fix it", "don't
wait"). Only for one problem, Simple tier, row Code, type not security; never
Qik. Record approval-sha (after `git fetch origin`) and the approval time at
the moment the owner asks. No create-issue question: keep the file-mode
journal. Still run Phase 1, write ## Problems and post the decision message as
a notice; the redaction check, budget and solved check all still apply.
Otherwise say in one line why it does not apply, and stop.

### Decision and redaction

Write the ## Decision section only after the owner answers, in your own
words: what was chosen, for which problem, any condition. Never paste the owner's message.
Example: "P1: option A (fix the loop bound). Budget as proposed. Approved by the
owner in chat, 2026-10-19 14:32." Last line, not for the owner: "Internal: approval-sha <40 hex>".

Keep a session list of every credential, password or token the owner gives you,
in any message, in this run's file `~/.superfix/runs/<run-key>/secrets` (key and recipe in
references/redaction.md; create the folder as soon as the key is known; it survives a restart, delete only this run's folder at the end). Before
ANY push, commit, issue create, comment, body edit or PR create, run the
redaction checks over the diff, the commit messages and every body and title
file. Each check prints one word (CLEAN, BLOCKED <files>, NO-LIST, NO-RUN-FOLDER); silence is
never a pass; NO-LIST passes only when the run folder exists, NO-RUN-FOLDER stops. BLOCKED (a session credential) stops the post until redacted.
Pattern hits are only reported and you decide: code reading a variable
(`password = request.form[...]`) is fine. Never write [redacted] into source
code; a real credential in the diff means stop and ask. Post only with
--body-file, never inline --body; a --title from chat goes in a file and is
checked first. A credential in the reporter's original issue body: stop, post
nothing, ask the owner to edit it. If something already leaked: delete the comment (never edit it,
GitHub keeps edit history), tell the owner to rotate the credential, and say
what leaked where.
Pictures: no upload except through evidence.md's upload command; a pattern hit in a picture blocks it.

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

Proposed in the decision message, fixed at approval. Defaults: Simple 6 commits,
2 hours, the files named in ## Options plus their tests; Moderate 15 commits, 4
hours, the files in the plan plus their tests; Complex as stated in the plan.
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

### Qik configuration (provisional)

Qik configuration (provisional). Load the qik skill first. No branch.
Moderate or Complex Qik work: plan and context files go in `~/.superfix/journal/<name>/`,
never in a repo, and the fix agent brief carries the four rules below.
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
git switch -c <fix|feature>/<N-or-date>-<slug> <approval-sha>   # the approved commit, not a newer origin
```
`<N-or-date>` is the issue number, or today's date for freeform work. That prevents slug collisions.

```
create branch → (bug: failing test or repro command first) → implement → impacted tests
→ simplify → re-run impacted tests → code-reviewer (issue text passed inline as the brief)
→ code-security-audit ONLY IF the diff touches auth, input parsing, SQL, shell, secrets or dependencies
→ verification-before-completion → PR
```

### Moderate + Complex path (autonomous agent)

Create branch with the shared block above before dispatching the agent (except Qik work, which has no branch). Architecture: create the worktree from `<approval-sha>` instead of creating a branch first.

Invoke `Agent` tool [sonnet/high for implementation; opus/high for architecture judgment]. Pass:
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

On restart (limit, crash, new session): re-read the Status line, `## Problems`, `## Decision`, the budget and approval-sha (its `Internal:` line) from the issue body or journal file, the latest progress comment on the issue (if any), the plan file's task checkboxes if a plan exists, and `git log` on the branch. The secrets list is the file `~/.superfix/runs/<run-key>/secrets` (the same key, built again: the run key on the journal's issue line, else the issue number, else the journal file name; redaction.md); do not start a new one, and a NO-RUN-FOLDER stops. Continue from the first unfinished stage. Do not redo finished stages.

### Solved check

Runs inside `verification-before-completion`, on both paths. Code only (Qik: see above).
"Solved" means three runs, each recorded with output in the final comment.
<s1>, <s3> are new folders outside the repo (`mktemp -d`), written out in full.
  Run 1, base fails: `git worktree add --detach <s1> <approval-sha>`, then
     `git -C <s1> checkout <branch> -- <new or changed test paths>`; run the
     failing check from ## Problems in <s1>.
  Run 2, fix passes: the same check on the branch.
     Run 2 also takes the after picture of each problem that had a before
     picture: same page and size, green box, same number (evidence.md).
  Run 3, revert fails: `git worktree add --detach <s3> HEAD`, then
     `git -C <s3> diff <approval-sha>..HEAD -- . ':!test' ':!tests' ':!*.test.*' | git -C <s3> apply -R`;
     run the check in <s3>, expect failure. The branch is never touched.
  After each run, and whenever a step fails: `git worktree remove --force <path>; git worktree prune`.
Run 2 must also show the owner's description quoted in ## Done when no longer
holds.
If run 3 passes, the check does not detect the problem: fix the check, not the
code, and re-run all three.
When run 3 does not apply, say why in one line and put it under Not tested;
it is not counted as a pass:
  - refactor meant to keep behaviour: no failing check exists; full suite
    passes before and after instead
  - a brand-new module or feature, where taking the code out cannot fail
    meaningfully (only by import or missing command)
Two failed run-2 attempts, whatever the cause given: stop. Post:
  "My fix failed twice, so my diagnosis was wrong. Work kept on the branch.
   Used 1 hour 10 minutes of 2 hours. Reply 1 to re-diagnose (about 20 minutes) or 2 to stop."
Status "Waiting for you: 1 question". Never re-diagnose quietly.

### Execute sequences by type, code review rules, test scope

These are in `references/execute.md`. Read it in full before implementing (see the start of Phase 3).

## Phase 4 - Close

Invoke `superpowers:finishing-a-development-branch` [sonnet/high]. Standard choice: push and create PR. The PR body includes `Closes #<N>` so GitHub closes the issue when the PR merges into the default branch.

If the repo has CI, run `gh pr checks <PR> --watch`. Fix red checks under the same review rules (two passes, then escalate).
Post the final comment only after checks are green, or after two fix passes with the red checks listed.

The PR body and the final comment both end with `## Not tested`: one bullet per
thing not checked, and why. An empty list says "Nothing known untested". Never leave it out.

If GitHub issue exists, post the final comment from `references/journal.md` and set the Status line to "Ready for review: PR <link>". Without an issue, write it as a journal entry and say it in chat.
The final comment carries one before-and-after picture per problem with pictures (a problem with a before picture has an after picture or a stated reason), the website line, the cost estimate and the undo line (journal.md).

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
- Uploading a picture without the upload command, or to a public repo

## Out of Scope

- `roadmap-planning` - sits above this orchestrator; invoke separately for planning work
- Observability tooling - post-deployment concern; not part of pre-merge workflow

---

## Skill Inventory Reference

The table of every skill this orchestrator can employ, with the opencode name or fallback for each, is in `references/inventory.md`. Read it only when a named skill does not resolve (see Model & Effort Policy).
