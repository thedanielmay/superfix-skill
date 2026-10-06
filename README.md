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

- **Simple** - runs inline on the main thread: branch, implement, impacted tests, simplify, re-run tests, review (the issue text is the brief), security audit only when the diff touches risky areas, verification, PR.
- **Moderate/Complex** - dispatches an autonomous agent with the context file and plan. If the run dies, restart from the latest progress comment, plan checkboxes, and branch log. Finished stages are not redone.

Every path simplifies before review (never after), re-runs tests after simplifying, then reviews, security-audits, and verifies against the original repro or baseline before declaring done. Skill names are Claude Code names; where a name does not resolve (notably under opencode), the step runs inline from its purpose and the PR body says so. Tests and verification are never skipped.

### Close (Phase 4)

Pushes the branch, creates a PR with `Closes #N` in the body, and watches CI checks when the repo has them. The issue closes when the PR merges, never on PR creation.

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

### Claude Code

```bash
# From your project root (requires Claude Code with plugin support)
claude skill install https://github.com/thedanielmay/superfix-skill
```

After a new release, pull it in with:

```bash
claude plugin marketplace update thedanielmay
claude plugin update superfix@thedanielmay
```

Then restart Claude Code. The update only applies after a restart.

### opencode

opencode reads the skill straight from a local checkout. Clone it once, then symlink it into your skills directory:

```bash
git clone https://github.com/thedanielmay/superfix-skill.git ~/projects/superfix-skill
ln -s ~/projects/superfix-skill ~/.agents/skills/superfix
```

Keep the clone on `main` when you are not mid-edit, so opencode runs released text. There is no install or update step beyond `git pull`.

---

## What's inside

```
SKILL.md                        Root manifest (skills CLI discovery, kept in sync)
skills/
  superfix/
    SKILL.md                    Full skill implementation and phase definitions
.claude-plugin/plugin.json      Plugin manifest and version
.github/workflows/             Sync check: fails a PR when the two SKILL.md copies differ
CONTRIBUTING.md                 How to work on this repo
```

The skill itself is prompt-based - no compiled code, no runtime dependencies. All behaviour is defined in `skills/superfix/SKILL.md`, mirrored at the repo root.

---

## Status

1.1.0. In production, supersedes `change-pipeline`. The classification rules, phase sequences, and skill inventory live in the SKILL.md files.
