---
name: superfix
description: >-
  Intelligent development orchestrator — accepts a GitHub issue number or
  freeform description of a bug, feature, UX change, or architecture change
  and drives it to a merged PR. Classifies the problem, assembles the right
  skill set, and manages the full workflow. Triggers on: superfix, issue #N,
  fix #N, implement #N, or any work description.
---

# Superfix Orchestrator

Intelligent front-door for all development work. Accepts a GitHub issue or freeform description, classifies the problem, assembles the right skill set, and drives it to a merged PR without requiring manual skill invocation or step breakdown.

Supersedes `change-pipeline` — do not invoke change-pipeline.

---

## Model & Effort Policy

Applied automatically. No user configuration required.

| Task category | Model | Effort |
|---------------|-------|--------|
| File reads, symbol lookups, quick checks | Haiku | High |
| Exploration, planning, implementation, review | Sonnet | High |
| Expert panel, complex architecture judgment, ambiguous cross-cutting triage | Opus | High |

State model+effort inline at every dispatch: `[sonnet/high - codebase exploration]`

---

## Input Handling

| Input form | How to get context |
|------------|-------------------|
| `/issue #N` | `gh issue view N` — read title, body, labels, all comments |
| `/issue "description"` | Use the text directly — do not search for a matching issue |
| `/issue` (no args) | Ask: "GitHub issue number or describe what needs doing?" |

GitHub-specific steps (posting comments, closing) run only when an issue was referenced.

If `gh issue view` fails (auth error, repo not set, issue not found), surface the error immediately. Do not silently fall back to "no issue" mode — confirm with the user whether to continue without GitHub integration or abort.

---

## Phase 0 — Problem Profile

Read the full input — body, labels, all comments — before classifying. Never classify from title alone.

Produce a **Problem Profile**:

```
Primary type:    [bug | performance | ux | architecture | security | feature]
Secondary type:  [optional — set when issue spans two types]
Complexity tier: [Simple | Moderate | Complex]  ← provisional; confirmed after exploration
Skill manifest:  [ordered skills — merged from primary + secondary paths if compound]
Expert panel:    [yes — all Moderate and Complex]
Agent execution: [yes — all Moderate and Complex]
```

**Compound issues:** When an issue spans two types (e.g. bug + security, UX + performance), set both `primary_type` and `secondary_type`. Merge skill manifests — run Phase 1 exploration tools from both types; append Phase 3 execute additions from the secondary type to the primary path.

Post as first GitHub comment if issue exists:
```bash
gh issue comment <N> --body "🔍 Problem Profile: [type] / [tier] — [one sentence summary]. Skill manifest: [list]. Starting exploration."
```

State it in conversation if no issue.

---

## GitHub Issue as Work Journal

When working from a GitHub issue, the issue is the single source of truth for the work. Apply this pattern throughout the pipeline:

**Issue body = living spec/plan**
Keep the issue body current. After Phase 0 and after any plan is written or significantly revised, edit the issue body to reflect the current spec, scope, and key decisions. The body should always answer: "what are we building, why, and what's out of scope?"

```bash
gh issue edit <N> --body "$(cat <<'EOF'
## Summary
<one paragraph: what this is and why>

## Scope
<what is in scope>

## Out of scope
<what is explicitly excluded>

## Key decisions
- <decision 1>
- <decision 2>

## Plan
docs/superpowers/plans/<filename>.md
EOF
)"
```

**Progress comments = timestamped changelog**
Each significant phase transition gets a progress comment — not an edit to the body. Comments accumulate as a readable audit trail of what happened and when.

Required progress comment triggers:
- Phase 0 complete: problem profile posted (already required above)
- Phase 1 complete: complexity tier confirmed, key findings summarised
- Phase 2 complete: plan approved after expert panel (already required above)
- Phase 3 complete: implementation done, tests green, PR created (already required in Phase 4)
- Any significant scope change or blocker encountered

Comment format:
```bash
gh issue comment <N> --body "✅ Phase N complete — [one sentence summary of outcome]. Next: [next step]."
```

**This applies only when an issue was referenced.** Freeform-description invocations skip all GitHub journal steps.

---

## Classification Rules

### Type detection (apply in priority order)

| Signals | Type |
|---------|------|
| Labels: `bug`, `regression`; keywords: "broken", "error", "exception", "crash", "not working", "fails" | `bug` |
| Labels: `performance`, `perf`, `optimization`; keywords: "slow", "latency", "N+1", "cache", "index", "timeout" | `performance` |
| Labels: `ui`, `ux`, `frontend`, `design`, `a11y`; keywords: "layout", "style", "visual", "animation", "mobile", "component", "accessibility" | `ux` |
| Labels: `security`, `vuln`, `cve`; keywords: "injection", "auth bypass", "XSS", "CSRF", "exposed", "CVE", "vulnerability" | `security` |
| Labels: `architecture`, `refactor`, `epic`; cross-cutting scope, multiple subsystems, structural change | `architecture` |
| Everything else | `feature` |

### Complexity tier (provisional from issue text; confirmed after exploration)

| Tier | Criteria |
|------|----------|
| **Simple** | 1–3 files, fix obvious from description, no design decisions |
| **Moderate** | Multiple files, some design choices, scope is clear |
| **Complex** | Architectural impact, unclear scope, cross-cutting concerns, or risky changes |

**Complexity can be upgraded** (Simple→Moderate, Moderate→Complex) after exploration reveals more scope. It cannot be downgraded.

**Already-fixed escape hatch:** If exploration reveals the issue is already resolved on current `main`, post a comment explaining this, close the issue as won't-fix, and stop — do not run the pipeline for a non-issue.

---

## Phase 1 — Explore

Run before writing a single line of code. Exploration is type-aware.

### Exploration by type

**`bug`**
- `superpowers:systematic-debugging` — frames the failure, classifies root cause category [sonnet/high]
- `feature-dev:code-explorer` — traces the affected execution paths [sonnet/high]
- `diagnose` — escalation if `systematic-debugging` cannot identify the root cause category after one pass, or the identified cause is speculative rather than confirmed by code evidence [sonnet/high]

**`performance`**
- `feature-dev:code-explorer` — maps the hot path end-to-end [sonnet/high]
- `grepai-trace-graph` — builds recursive call graph of the slow path [sonnet/high]
- Measure before planning: run actual timing/profiling. Record baseline numbers in context file.

**`ux`**
- `feature-dev:code-explorer` — reads component tree, design tokens, layout patterns [sonnet/high]
- Note existing impeccable/ui-ux-pro-max conventions already in use

**`architecture`**
- `feature-dev:code-explorer` — full system mapping, data flows, module boundaries [sonnet/high]
- `architecture-deep-dive` — structural analysis, strengths/weaknesses [opus/high]
- `grepai-trace-graph` — dependency graph across subsystems [sonnet/high]
- `improve-codebase-architecture` — identifies shallow modules, structural candidates [sonnet/high]

**`security`**
- `feature-dev:code-explorer` — traces auth flows, data flows, trust boundaries [sonnet/high]
- `code-security-audit` — run on relevant files pre-plan to understand current exposure [sonnet/high]

**`feature` Simple**
- Built-in `Explore` agent — quick symbol/file lookup, "where does this slot in?" — max 5 minutes [haiku/high]

**`feature` Moderate/Complex**
- `feature-dev:code-explorer` — traces where feature integrates [sonnet/high]
- `feature-dev:code-architect` — maps existing patterns, identifies what can be reused [sonnet/high]

### After exploration: confirm complexity tier

Re-assess the provisional tier. If scope is larger than described, upgrade and state why. Post updated comment if issue exists.

---

## Phase 2 — Design & Plan

Applies to **Moderate and Complex** only. Simple goes directly to Phase 3.

### Design step (type-specific, before writing-plans)

| Type | Design approach |
|------|----------------|
| `bug` | No design step — exploration output feeds directly into plan |
| `performance` | Plan based on measured baseline; state target improvement metric |
| `ux` | `superpowers:brainstorming` [opus/high] → `ui-ux-pro-max` or `impeccable` sub-skill as appropriate → `accessibility` (WCAG 2.2 check) |
| `architecture` | `superpowers:brainstorming` [opus/high] — explore structural options before committing |
| `security` | `security` skill — produce threat model; identify trust boundaries and attack surface [opus/high] |
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

### Expert panel (all Moderate + Complex — blocking)

Invoke `expert-panel` [opus/high] after plan is written, at the plan→implementation joint.

- Format: synthesised must-fixes / should-fixes / verdict only — no per-panelist narration
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

## Phase 3 — Execute

### Simple path (main thread, no agent)

Create branch before touching any file:
```bash
git checkout -b fix/<slug>     # bug/security
git checkout -b feature/<slug> # feature/ux/performance/architecture
```

```
create branch → explore → implement → tests
→ pr-review-toolkit:code-reviewer [sonnet/high]
→ code-security-audit [sonnet/high]
→ simplify [sonnet/high]
→ verification-before-completion [sonnet/high]
→ PR
```

### Moderate + Complex path (autonomous agent)

Create branch before dispatching agent:
```bash
git checkout -b fix/<slug>     # bug/security
git checkout -b feature/<slug> # feature/ux/performance/architecture
```

Invoke `Agent` tool [sonnet/high for implementation; opus/high for architecture judgment]. Pass:
- Branch name
- Context file path
- Plan file path
- Problem Profile (type, tier, skill manifest)
- Model/effort policy: most appropriate model per task, high effort

Agent runs the full execute sequence autonomously. Surfaces only:
- Blockers requiring human judgment (with specific question, not just "stuck")
- Final PR link when complete

**Wakeup defaults:** implementer 15 min, reviewer 10 min, gate 12 min.

### Execute sequences by type

**`bug`**
```
superpowers:test-driven-development (write failing test first) [sonnet/high]
→ implement fix (superpowers:subagent-driven-development for Complex) [sonnet/high]
→ run tests (impacted files: pytest <file> -n auto / npm run test -- --run <file>)
→ pr-review-toolkit:code-reviewer [sonnet/high]
→ code-security-audit [sonnet/high]
→ simplify [sonnet/high]
→ pr-review-toolkit:silent-failure-hunter [sonnet/high]
→ verification-before-completion [sonnet/high]
```

**`performance`**

TDD not required — the test suite guards correctness. If the performance change modifies logic (not just queries/caching/indexes), run `superpowers:test-driven-development` first.

```
implement improvement [sonnet/high]
→ run tests
→ measure again (confirm improvement vs baseline — must show measurable gain)
→ pr-review-toolkit:code-reviewer [sonnet/high]
→ code-security-audit [sonnet/high]
→ simplify [sonnet/high]
→ pr-review-toolkit:silent-failure-hunter [sonnet/high]
→ verification-before-completion [sonnet/high]
```

**`ux`**
```
superpowers:test-driven-development [sonnet/high]
→ implement [sonnet/high]
→ react-vite-best-practices (if React components changed) [sonnet/high]
→ Playwright visual verification (document-skills:webapp-testing) [sonnet/high]
→ accessibility (WCAG 2.2 check on changed components) [sonnet/high]
→ pr-review-toolkit:code-reviewer [sonnet/high]
→ code-security-audit [sonnet/high]
→ simplify [sonnet/high]
→ pr-review-toolkit:silent-failure-hunter [sonnet/high]
→ verification-before-completion [sonnet/high]
```

**`architecture`**
```
implement (worktree via superpowers:using-git-worktrees; superpowers:subagent-driven-development for Complex) [sonnet/high]
→ run full test suite
→ improve-codebase-architecture (validate structural changes meet deep-module criteria) [sonnet/high]
→ pr-review-toolkit:type-design-analyzer (if diff contains new type/interface/class/dataclass) [sonnet/high]
→ pr-review-toolkit:code-reviewer [sonnet/high]
→ code-security-audit [sonnet/high]
→ simplify [sonnet/high]
→ pr-review-toolkit:silent-failure-hunter [sonnet/high]
→ verification-before-completion [sonnet/high]
```

**`security`**
```
implement fix [sonnet/high]
→ run tests
→ code-security-audit (primary — 80%+ confidence threshold) [sonnet/high]
→ pr-review-toolkit:code-reviewer (cross-check) [sonnet/high]
→ simplify [sonnet/high]
→ pr-review-toolkit:silent-failure-hunter [sonnet/high]
→ verification-before-completion [sonnet/high]
```

**`feature` Moderate/Complex**
```
superpowers:test-driven-development [sonnet/high]
→ implement (superpowers:subagent-driven-development for Complex) [sonnet/high]
→ run tests
→ pr-review-toolkit:type-design-analyzer (if diff contains new type/interface/class/dataclass) [sonnet/high]
→ pr-review-toolkit:code-reviewer [sonnet/high]
→ code-security-audit [sonnet/high]
→ simplify [sonnet/high]
→ pr-review-toolkit:silent-failure-hunter [sonnet/high]
→ verification-before-completion [sonnet/high]
```

### Code review rules (all types)

- Fix every **high-confidence** finding — one issue, one fix, re-verify
- Skip false positives — note and move on
- Max 2 review passes; if high-confidence issues remain after pass 2, escalate to user
- `code-security-audit` always runs after `code-reviewer`, not instead of it

### Test scope

- Impacted files only during implementation: `pytest <file> -n auto` / `npm run test -- --run <file>`
- Full test suite once at end, before verification

---

## Phase 4 — Close

Invoke `superpowers:finishing-a-development-branch` [sonnet/high]. Standard choice: push and create PR.

If GitHub issue exists:
```bash
gh issue comment <N> --body "🚀 PR #<PR> created — ready for review."

# Guard: only close if still open (PR may have auto-closed on merge)
ISSUE_STATE=$(gh issue view <N> --json state -q .state)
if [ "$ISSUE_STATE" = "OPEN" ]; then
  gh issue close <N> --comment "Fixed in PR #<PR>"
fi
```

---

## Shortcuts

| Situation | Shortcut |
|-----------|----------|
| Plan already exists in `docs/superpowers/plans/` | Run exploration as normal; skip design step and `writing-plans`; create context file from existing plan; verify plan reflects current codebase state before expert panel |
| PR already exists | Use `pr-review-toolkit:review-pr` instead of `code-reviewer` in execute phase |
| Tests unchanged by change | Skip that test suite |

---

## Red Flags

- Classifying from title alone — always read full body, labels, and all comments first
- Triaging complexity before exploring the codebase
- Skipping exploration for any tier
- Starting implementation on Moderate/Complex without an approved plan
- Skipping expert panel on Moderate or Complex
- Running `code-security-audit` instead of `code-reviewer` — both are required, in that order
- Subagents without the context file — undefined hand-offs produce blind reviews
- Claiming tests pass without a fresh run
- Declaring done without checking the original goal was actually achieved
- Upgrading Simple→Moderate/Complex after implementation has started — stop, commit/stash partial work, return to Phase 2, write a plan accounting for what's already implemented, run expert panel, then continue
- Closing a GitHub issue without confirming the PR is merged
- Invoking `change-pipeline` — it is superseded; do not use
- Updating only GitHub comments but never the issue body — the body is the living spec; let it drift and the issue becomes unreadable out of context
- Editing the issue body for progress updates instead of adding a comment — body = current state, comments = history

---

## Out of Scope

- `roadmap-planning` — sits above this orchestrator; invoke separately for planning work
- Observability tooling — post-deployment concern; not part of pre-merge workflow

---

## Skill Inventory Reference

| Skill | Phase | Types |
|-------|-------|-------|
| `feature-dev:code-explorer` | 1 | all except feature/Simple |
| `feature-dev:code-architect` | 1 | feature Mod/Complex |
| `grepai-trace-graph` | 1 | performance, architecture |
| `superpowers:systematic-debugging` | 1 | bug |
| `diagnose` | 1 | bug (escalation) |
| `architecture-deep-dive` | 1 | architecture |
| `improve-codebase-architecture` | 1 + 3 | architecture |
| `superpowers:brainstorming` | 2 | ux, architecture, feature Mod/Complex |
| `ui-ux-pro-max` | 2 | ux |
| `impeccable` (sub-skills) | 2 + 3 | ux |
| `accessibility` | 2 + 3 | ux |
| `security` | 2 | security |
| `code-security-audit` | 1 (security — pre-plan scan) + 3 (all) | all |
| `api-response-optimization` | 2 | performance |
| `python-performance-optimization` | 2 | performance (backend) |
| `sql-optimization-patterns` | 2 | performance (DB) |
| `postgresql-optimization` | 2 | performance (DB) |
| `superpowers:writing-plans` | 2 | Moderate + Complex |
| `expert-panel` | 2 | all Moderate + Complex |
| `superpowers:test-driven-development` | 3 | bug, ux, feature |
| `react-vite-best-practices` | 3 | ux |
| `document-skills:webapp-testing` | 3 | ux (Playwright visual) |
| `pr-review-toolkit:code-reviewer` | 3 | all |
| `pr-review-toolkit:silent-failure-hunter` | 3 | all |
| `pr-review-toolkit:type-design-analyzer` | 3 | architecture, feature (new types only) |
| `simplify` | 3 | all |
| `superpowers:verification-before-completion` | 3 | all |
| `superpowers:subagent-driven-development` | 3 | Complex only |
| `superpowers:using-git-worktrees` | 3 | architecture |
| `superpowers:finishing-a-development-branch` | 4 | all |
