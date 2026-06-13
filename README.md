# superfix-skill

Intelligent development orchestrator for Claude Code — takes a GitHub issue or freeform description and drives it end-to-end to a merged PR.

---

## Overview

`superfix` is a Claude Code skill that acts as the single front-door for all development work. You give it a GitHub issue number (`#42`) or describe what needs doing in plain English; it classifies the problem, assembles the right sub-skill set, and manages the full pipeline — exploration, planning, expert review, implementation, testing, code review, and PR — without requiring you to invoke individual skills manually or break the work into steps yourself.

It supersedes the older `change-pipeline` skill.

---

## When to use / Triggers

Invoke `superfix` (via `/superfix` in Claude Code) whenever you have:

- A GitHub issue number: `/superfix #42`, `/fix #42`, `/implement #42`
- A freeform description: `/superfix "the login button is broken on mobile"`
- No arguments — it will ask for an issue number or description

The skill triggers automatically on the keywords `superfix`, `issue #N`, `fix #N`, or `implement #N`.

---

## What it does

### Problem Profile (Phase 0)

Reads the full issue — body, labels, all comments — and classifies it:

| Classification | Types |
|----------------|-------|
| Problem type | `bug`, `performance`, `ux`, `architecture`, `security`, `feature` |
| Complexity tier | `Simple`, `Moderate`, `Complex` (provisional; confirmed after exploration) |

Posts a Problem Profile as a GitHub comment if an issue was referenced. Keeps the issue body as a living spec and adds timestamped progress comments at each phase transition.

### Explore (Phase 1)

Runs type-aware exploration before writing any code:

- **bug** — systematic debugging + execution path tracing
- **performance** — hot-path mapping + call graph + baseline measurement
- **ux** — component tree, design tokens, layout patterns
- **architecture** — full system mapping, dependency graph, structural analysis
- **security** — auth/data flow tracing + pre-plan security scan
- **feature** — quick lookup (Simple) or full explorer + architect (Moderate/Complex)

### Design & Plan (Phase 2, Moderate/Complex only)

Type-specific design step (brainstorming, threat modelling, UX iteration), then a written plan saved to `docs/superpowers/plans/YYYY-MM-DD-<slug>.md` plus a context file passed to every subagent. All Moderate and Complex work goes through a blocking expert panel review before implementation.

### Execute (Phase 3)

- **Simple** — runs inline on the main thread
- **Moderate/Complex** — dispatches an autonomous agent with the context file and plan

Execute sequence for every type includes: TDD (where applicable), implementation, tests, code review, security audit, silent-failure hunting, type design analysis (if new types introduced), simplification, and verification before completion.

### Close (Phase 4)

Pushes the branch, creates a PR, posts a closing comment on the GitHub issue, and closes the issue once the PR is confirmed merged.

### Model policy

Applied automatically — no user configuration needed:

| Task | Model |
|------|-------|
| File reads, symbol lookups, quick checks | Haiku |
| Exploration, planning, implementation, review | Sonnet |
| Expert panel, complex architecture, ambiguous triage | Opus |

---

## Installation

This repo is structured as a Claude Code installable plugin with a skill manifest.

```bash
# From your project root (requires Claude Code with plugin support)
claude skill install https://github.com/thedanielmay/superfix-skill
```

The skill manifest is at the repo root (`SKILL.md`). The implementation lives in `skills/superfix/SKILL.md`.

---

## What's inside

```
SKILL.md                        Root manifest (skills CLI discovery)
skills/
  superfix/
    SKILL.md                    Full skill implementation and phase definitions
```

The entire skill is prompt-based — no compiled code, no runtime dependencies. All behaviour is defined in `skills/superfix/SKILL.md`.

---

## Status

Active. The skill is used in production and supersedes `change-pipeline`. The classification rules, phase sequences, and skill inventory are kept up to date in the SKILL.md files.
