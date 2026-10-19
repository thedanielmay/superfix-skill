# superfix-skill

Intelligent development orchestrator for Claude Code - takes a GitHub issue or freeform description and drives it end-to-end to an opened PR with CI green.

---

## Overview

`superfix` is a Claude Code skill that acts as the single front-door for all development work. You give it a GitHub issue number (`#42`) or describe what needs doing in plain English; it classifies the problem, assembles the right sub-skill set, and manages the full pipeline - exploration, planning, expert review, implementation, testing, code review, and PR - without requiring you to invoke individual skills manually or break the work into steps yourself.

It supersedes the older `change-pipeline` skill.

Since 1.3.0 it diagnoses first and stops for your approval before it fixes anything (see "Diagnose and stop" below).

The skill file is kept short. The long parts (the issue journal, the diagnosis method, agent briefs, redaction, exploration by type, the execute sequences and review rules, the skill inventory) live in `skills/superfix/references/` and are read only when a step needs them.

---

## When to use / Triggers

Invoke `superfix` (via `/superfix` in Claude Code) whenever you have:

- A GitHub issue number: `/superfix #42`, `/fix #42`, `/implement #42`
- A freeform description: `/superfix "the login button is broken on mobile"`
- No arguments - it will ask for an issue number or description

The skill triggers automatically on the keywords `superfix`, `issue #N`, `fix #N`, or `implement #N`.

Qik configuration and other non-code problems are reached only by typing `/superfix`. There is no automatic trigger for them.

---

## What it does

### Problem Profile (Phase 0)

Reads the full issue - body, labels, all comments - and classifies it:

| Classification | Types |
|----------------|-------|
| Problem type | `bug`, `performance`, `ux`, `architecture`, `security`, `feature` |
| Complexity tier | `Simple`, `Moderate`, `Complex` (provisional; confirmed after exploration) |

Before the type, it runs a coverage check (below). The Problem Profile is not posted on its own: it goes into the one decision message at the stop. The issue body stays a living spec, with a Status line on top and the reporter's text kept under `## Original report`. Without an issue, the same record goes in a local file at `~/.superfix/journal/`, outside the repo.

### Explore and diagnose (Phase 1)

Runs type-aware exploration before writing any code, inside a diagnosis method (`references/diagnose.md`): a check that fails on the reported symptom first, then 3 to 5 ranked guesses at the cause, each tested. "Confirmed" needs a test that tells the guesses apart. Before approval nothing is written except the journal and a scratch folder outside the repo. The exploration skills by type:

- **bug** - systematic debugging + execution path tracing
- **performance** - hot-path mapping + call graph + baseline measurement
- **ux** - component tree, design tokens, layout patterns
- **architecture** - full system mapping, dependency graph, structural analysis
- **security** - auth/data flow tracing + pre-plan security scan
- **feature** - quick lookup (Simple) or full explorer + architect (Moderate/Complex)

### Diagnose and stop

Every run stops after diagnosis, whatever its size, unless that run's request says "just fix it" (one Simple code problem, not security).

- The issue body gets `## Problems` (evidence), `## Options` (with a recommendation) and `## Done when` (your own description of the problem, which must stop being true).
- One decision message holds every question, numbered. Reply in one line, for example "1 yes, 2 option two". "Keep executing" means yes to every recommendation.
- Without an issue, inside a repo on GitHub, the same message asks whether to create one. It names the repo's visibility first.
- The message proposes a budget in plain words, for example "Up to 2 hours, touching these 3 files. I stop and ask if I go over."
- Your answer is written into `## Decision` in Superfix's own words, never pasted, so a password in a reply never reaches GitHub.

Coverage check: it says which kind of problem this is, and quotes the words that made it decide.

| Kind | Matches when the report mentions | What Superfix does |
|------|----------------------------------|--------------------|
| Code | files in the repo, a test, a stack trace, CLI or page output | diagnose and fix |
| Qik configuration | a Qik interface, section, form, role, workflow, definition, a qik.dev link | diagnose and fix in the draft only, marked provisional (not yet proven by a test); you always publish |
| Everything else | documents, process, sheets, business | diagnosis only, low confidence |

Passwords and tokens: it keeps a list of every credential given in the session and checks every comment, body edit, commit and PR against it before anything is posted (`references/redaction.md`). Name a 1Password item instead of typing a password.

### Design & Plan (Phase 2, Moderate/Complex only)

Type-specific design step (brainstorming, threat modelling, UX iteration), then a written plan saved to `docs/superpowers/plans/YYYY-MM-DD-<slug>.md` plus a context file passed to every subagent. All Moderate and Complex work goes through a blocking expert panel review before implementation.

### Execute (Phase 3)

- **Simple** - runs inline on the main thread: branch, implement, impacted tests, simplify, re-run tests, review (the issue text is the brief), security audit only when the diff touches risky areas, verification, PR.
- **Moderate/Complex** - dispatches an autonomous agent with the context file, the plan and the brief file (`references/briefs.md`). If the run dies, restart from the Status line, `## Problems`, `## Decision`, the latest progress comment, plan checkboxes (when a plan exists), and branch log. Finished stages are not redone.
- **Budget** - set at approval. Over any limit (commits, files, time) it stops with `BUDGET STOP` and asks: extend, cut scope, or stop.
- **Solved check (code)** - the failing check fails on the approved base commit, passes with the fix, and fails again when the fix is taken out in a scratch copy. All three results are posted. If the fix fails twice, it stops and says its diagnosis was wrong.

Every path simplifies before review (never after), re-runs tests after simplifying, then reviews, security-audits, and verifies against the original repro or baseline before declaring done. Skill names are Claude Code names; where a name does not resolve (notably under opencode), the step runs inline from its purpose and the PR body says so. Tests and verification are never skipped.

### Close (Phase 4)

Pushes the branch, creates a PR with `Closes #N` in the body, and watches CI checks when the repo has them. The final comment is posted only after the checks are green. The issue closes when the PR merges, never on PR creation.

Not tested: the PR body and the final comment always end with a `## Not tested` list. An empty list says "Nothing known untested".

### Model policy

Applied automatically - no user configuration needed:

| Task | Model |
|------|-------|
| File reads, symbol lookups, quick checks | Haiku |
| Exploration, planning, implementation, review | Sonnet |
| Expert panel, complex architecture, ambiguous triage | Opus |

---

## Dependencies

Nothing is hard-required. Superfix names Claude Code skills; any step whose skill is not installed runs inline from its stated purpose, and the PR body records `ran inline: <skill>`. Tests and verification are never skipped. Install the below for full behavior. Every skill superfix can employ is listed, including the ones that run inline.

**Plugin packs (Claude Code):**

- `superpowers` ([obra/superpowers](https://github.com/obra/superpowers)) - systematic-debugging, brainstorming, test-driven-development, verification-before-completion, writing-plans, finishing-a-development-branch, subagent-driven-development, using-git-worktrees. Not available in opencode; runs inline there.
- `feature-dev` ([anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official)) - code-explorer and code-architect agents. opencode: built-in Explore agent for exploration, inline otherwise.
- `pr-review-toolkit` ([same repo](https://github.com/anthropics/claude-plugins-official)) - code-reviewer, silent-failure-hunter and type-design-analyzer agents, plus the review-pr command. opencode: inline review with the same brief.
- `expert-panel` ([thedanielmay/expert-panel-skill](https://github.com/thedanielmay/expert-panel-skill)) - same where installed, else structured self-review.

**Same-name skills (both harnesses; installed copies verified identical to source):**

- `diagnose` ([javimosch/supercli](https://github.com/javimosch/supercli))
- `improve-codebase-architecture` ([same repo](https://github.com/javimosch/supercli))
- `grepai-trace-graph` ([yoanbernabeu/grepai-skills](https://github.com/yoanbernabeu/grepai-skills))
- `react-vite-best-practices` ([AsyrafHussin/agent-skills](https://github.com/AsyrafHussin/agent-skills))
- `security-audit` ([cloudflare/security-audit-skill](https://github.com/cloudflare/security-audit-skill))
- `code-security-audit` ([LeonMelamud/claude-code-security-review](https://github.com/LeonMelamud/claude-code-security-review))
- `refactor` ([github/awesome-copilot](https://github.com/github/awesome-copilot))
- `api-response-optimization` ([aj-geddes/useful-ai-prompts](https://github.com/aj-geddes/useful-ai-prompts))
- `accessibility` ([addyosmani/web-quality-skills](https://github.com/addyosmani/web-quality-skills)) - installed copy is v1.1, upstream is v2.0.

**Flagged: employed inline (no install resolves them here):**

- `architecture-deep-dive` - installed in this Claude Code setup, no verifiable upstream found; missing in opencode. Runs as an inline structural review.
- `ui-ux-pro-max` ([nextlevelbuilder/ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill)), `impeccable` ([pbakaus/impeccable](https://github.com/pbakaus/impeccable)) - registered but not installed in either harness here. Runs inline from UX intent.
- `security` (threat-model step) - no such skill exists in either harness; the closest family is the memstack security skills ([cwinvestments/memstack](https://github.com/cwinvestments/memstack)). Always runs inline.
- `webapp-testing` - ships as `example-skills:webapp-testing` in [anthropics/skills](https://github.com/anthropics/skills); where it is not installed the Playwright steps run inline.
- `simplify` - bundled with some Claude Code versions, not a plugin. The fallback is the `code-simplifier` agent, then `refactor` above, else inline.

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
references                      Symlink to skills/superfix/references (for the root copy)
skills/
  superfix/
    SKILL.md                    Full skill implementation and phase definitions
    references/
      journal.md                Issue body template, Status line, comments, decision message, file-mode journal
      diagnose.md               Diagnosis method, stop rules, tools and fallbacks, review header, fan-out brief
      briefs.md                 Execution brief for the fix agent (read only after approval)
      redaction.md              Credential check before any post, commit or PR
      explore.md                Exploration by type
      execute.md                Execute sequences by type, review rules, test scope
      inventory.md              Every skill used, with its opencode name or fallback
tests/
  prompts.md                    Fixed test prompts and pass criteria for a release
  preservation-check.py         Lists every line of the last release that is gone; fails on unexplained ones
  preservation-1.3.0.md         One justification per removed or changed line
.claude-plugin/plugin.json      Plugin manifest and version
.github/workflows/             Sync check: fails a PR when the two SKILL.md copies differ
CONTRIBUTING.md                 How to work on this repo
```

The skill itself is prompt-based - no compiled code, no runtime dependencies. All behaviour is defined in `skills/superfix/SKILL.md` (mirrored at the repo root) and the files in `skills/superfix/references/` it tells the model to read. `tests/` is never loaded at run time.

---

## Status

1.3.0. In production, supersedes `change-pipeline`. The classification rules and phase sequences live in the SKILL.md files; the skill inventory and the other long parts live in `skills/superfix/references/`. Qik configuration support is provisional through 1.3.0.
