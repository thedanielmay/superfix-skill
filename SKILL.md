---
name: superfix
description: >-
  Intelligent development orchestrator - accepts a GitHub issue number or
  freeform description of a bug, feature, UX change, or architecture change
  and drives it to an opened PR with CI green. Classifies the problem,
  assembles the right skill set, and manages the full workflow. Triggers on:
  superfix, issue #N, fix #N, implement #N, or a request to fix, build or
  change something in code.
---

# Superfix Orchestrator

Intelligent front-door for all development work. Accepts a GitHub issue or freeform description, classifies the problem, assembles the right skill set, and drives it to an opened PR (CI green, ready for review) without requiring manual skill invocation or step breakdown.

Supersedes `change-pipeline` - do not invoke change-pipeline.

---

## Model & Effort Policy

Applied automatically. No user configuration required.

| Task category | Model | Effort |
|---------------|-------|--------|
| File reads, symbol lookups, quick checks | Haiku | High |
| Exploration, planning, implementation, review | Sonnet | High |
| Expert panel, brainstorming, complex architecture judgment, ambiguous cross-cutting triage | Opus | High |

State model+effort inline at every dispatch: `[sonnet/high - codebase exploration]`

Skill names are Claude Code names. If a name does not resolve, use the opencode equivalent from the inventory; if neither exists, do the step inline from its stated purpose and write `ran inline: <skill>` in the PR body. Never skip tests or verification.

---

## Input Handling

| Input form | How to get context |
|------------|-------------------|
| `/issue #N` | `gh issue view N` - read title, body, labels, all comments |
| `/issue "description"` | Use the text directly - do not search for a matching issue |
| `/issue` (no args) | Ask: "GitHub issue number or describe what needs doing?" |

GitHub-specific steps (posting comments, closing) run only when an issue was referenced. When one is referenced, Read `references/journal.md` first (see the work journal section).

If `gh issue view` fails (auth error, repo not set, issue not found), surface the error immediately. Do not silently fall back to "no issue" mode - confirm with the user whether to continue without GitHub integration or abort.

---

## Phase 0 - Problem Profile

Read the full input - body, labels, all comments - before classifying. Never classify from title alone.

Produce a **Problem Profile**:

```
Primary type:    [bug | performance | ux | architecture | security | feature]
Secondary type:  [optional - set when issue spans two types]
Complexity tier: [Simple | Moderate | Complex]  ← provisional; confirmed after exploration
Skill manifest:  [ordered skills - merged from primary + secondary paths if compound]
Expert panel:    [yes - all Moderate and Complex]
Agent execution: [yes - all Moderate and Complex]
```

**Compound issues:** When an issue spans two types (e.g. bug + security, UX + performance), set both `primary_type` and `secondary_type`. Merge skill manifests - run Phase 1 exploration tools from both types; append Phase 3 execute additions from the secondary type to the primary path.

Post as first GitHub comment if issue exists:
```bash
gh issue comment <N> --body "🔍 Problem Profile: [type] / [tier] - [one sentence summary]. Skill manifest: [list]. Starting exploration."
```

State it in conversation if no issue.

---

## GitHub Issue as Work Journal

When working from a GitHub issue, the issue is the single source of truth for the work. The body template, the progress comment triggers and the comment format are in `references/journal.md` (in this skill's base directory). Read it in full as soon as an issue is referenced, before the first comment or body edit, and write `Loaded: journal.md` in the Problem Profile comment.

---

## Classification Rules

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

---

## Phase 1 - Explore

Run before writing a single line of code. Exploration is type-aware.

### Exploration by type

Read `references/explore.md` in full (this skill's base directory) and run the exploration listed for the primary type, and for the secondary type if there is one. Write `Loaded: explore.md` in the Phase 1 progress comment, or in your next message to the user if there is no issue.

### After exploration: confirm complexity tier

Re-assess the provisional tier. If scope is larger than described, upgrade and state why. Post updated comment if issue exists.

---

## Phase 2 - Design & Plan

Applies to **Moderate and Complex** only. Simple goes directly to Phase 3.

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
```

**Pass this file path to every subagent.** Every subagent reads the same source of truth.

### Expert panel (all Moderate + Complex - blocking)

Invoke `expert-panel` [opus/high] after plan is written, at the plan→implementation joint.

- Format: synthesised must-fixes / should-fixes / verdict only - no per-panelist narration
- Must-fix findings addressed before implementation proceeds
- Update the plan with any must-fix resolutions
- Post comment if issue exists:

```bash
gh issue comment <N> --body "📋 Plan approved after expert panel review. Starting implementation.

Plan: docs/superpowers/plans/<filename>.md
Key decisions: [brief summary]"
```

**Max 2 expert panel passes.** If must-fix items remain after pass 2, escalate to the user with specific questions.

---

## Phase 3 - Execute

Before implementing, Read `references/execute.md` in full (this skill's base directory). It holds the execute sequences by type, the code review rules and the test scope. Write `Loaded: execute.md` in the Phase 3 progress comment, or in your next message to the user if there is no issue.

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

Agent runs the full execute sequence autonomously. Surfaces only:
- Blockers requiring human judgment (with specific question, not just "stuck")
- Final PR link when complete

The agent ticks the plan file's task checkboxes as each task completes.

On restart (limit, crash, new session): read the latest progress comment on the issue (if any), the plan file's task checkboxes, and `git log` on the branch. Continue from the first unfinished stage. Do not redo finished stages.

### Execute sequences by type, code review rules, test scope

These are in `references/execute.md`. Read it in full before implementing (see the start of Phase 3).

---

## Phase 4 - Close

Invoke `superpowers:finishing-a-development-branch` [sonnet/high]. Standard choice: push and create PR. The PR body includes `Closes #<N>` so GitHub closes the issue when the PR merges into the default branch.

If GitHub issue exists:
```bash
gh issue comment <N> --body "🚀 PR #<PR> created - ready for review."
```

If the PR targets a non-default branch, `Closes` does not fire. Close manually only after `gh pr view <PR> --json state -q .state` returns `MERGED`.

If the repo has CI, run `gh pr checks <PR> --watch`. Fix red checks under the same review rules (two passes, then escalate).

---

## Shortcuts

| Situation | Shortcut |
|-----------|----------|
| Plan already exists in `docs/superpowers/plans/` | Run exploration as normal; skip design step and `writing-plans`; create context file from existing plan; verify plan reflects current codebase state before expert panel |
| PR already exists | Use `pr-review-toolkit:review-pr` instead of `code-reviewer` in execute phase |

---

## Red Flags

- Classifying from title alone - always read full body, labels, and all comments first
- Triaging complexity before exploring the codebase
- Skipping exploration for any tier
- Starting implementation on Moderate/Complex without an approved plan
- Skipping expert panel on Moderate or Complex
- Subagents without the context file - undefined hand-offs produce blind reviews
- Claiming tests pass without a fresh run
- Declaring done without checking the original goal was actually achieved
- Upgrading Simple→Moderate/Complex after implementation has started - stop, commit/stash partial work, return to Phase 2, write a plan accounting for what's already implemented, run expert panel, then continue
- Closing a GitHub issue without confirming the PR is merged
- Invoking `change-pipeline` - it is superseded; do not use
- Updating only GitHub comments but never the issue body - the body is the living spec; let it drift and the issue becomes unreadable out of context
- Editing the issue body for progress updates instead of adding a comment - body = current state, comments = history

---

## Out of Scope

- `roadmap-planning` - sits above this orchestrator; invoke separately for planning work
- Observability tooling - post-deployment concern; not part of pre-merge workflow

---

## Skill Inventory Reference

The table of every skill this orchestrator can employ, with the opencode name or fallback for each, is in `references/inventory.md`. Read it only when a named skill does not resolve (see Model & Effort Policy).
