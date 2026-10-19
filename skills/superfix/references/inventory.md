# Skill inventory

Moved word for word from SKILL.md 1.1.1 (superfix-skill#42). SKILL.md says when to read this file.

Diagnosis tools and their fallbacks (Explore, a report-only `general-purpose` agent, episodic memory, git history, Playwright, Qik read tools) are in `references/diagnose.md`.

| Skill (Claude Code) | Phase | Types | opencode or fallback |
|-------|-------|-------|----------------------|
| `feature-dev:code-explorer` | 1 | all except feature/Simple | `code-explorer` subagent |
| `feature-dev:code-architect` | 1 | feature Mod/Complex | `code-architect` subagent |
| `grepai-trace-graph` | 1 | performance, architecture | same name, else inline recursive search |
| `superpowers:systematic-debugging` | 1 | bug | `systematic-debugging` skill |
| `diagnose` | 1 | bug (escalation) | same name, else inline |
| `architecture-deep-dive` | 1 | architecture | inline structural review |
| `improve-codebase-architecture` | 1 + 3 | architecture | same name, else inline |
| `superpowers:brainstorming` | 2 | ux, architecture, feature Mod/Complex | `brainstorming` skill |
| `ui-ux-pro-max` | 2 | ux | inline from UX intent |
| `impeccable` (sub-skills) | 2 + 3 | ux | inline from UX intent |
| `accessibility` | 2 + 3 | ux | same name both |
| threat model (inline) | 2 | security | `security-audit` for guidance, else inline |
| `code-security-audit` | 1 (security - pre-plan scan) + 3 (all) | all | same name, else inline review |
| `superpowers:writing-plans` | 2 | Moderate + Complex | `writing-plans` skill |
| `expert-panel` | 2 | all Moderate + Complex | same where installed, else structured self-review |
| `superpowers:test-driven-development` | 3 | bug, ux, feature | `test-driven-development` skill |
| `react-vite-best-practices` | 3 | ux | same name, else inline |
| `example-skills:webapp-testing` | 3 | ux (Playwright visual) | `webapp-testing`, else Playwright steps inline |
| `pr-review-toolkit:code-reviewer` | 3 | all | `code-reviewer` subagent |
| `pr-review-toolkit:silent-failure-hunter` | 3 | all | `silent-failure-hunter` subagent |
| `pr-review-toolkit:type-design-analyzer` | 3 | architecture, feature (new types only) | `type-design-analyzer` subagent |
| `pr-review-toolkit:review-pr` | 3 | existing PR (shortcut) | inline review with the same brief |
| `simplify` | 3 | all | `code-simplifier` subagent, else `refactor` skill, else inline |
| `superpowers:verification-before-completion` | 3 | all | `verification-before-completion` skill |
| `superpowers:subagent-driven-development` | 3 | Complex only | `subagent-driven-development` skill |
| `superpowers:using-git-worktrees` | 3 | architecture | `using-git-worktrees` skill |
| `superpowers:finishing-a-development-branch` | 4 | all | `finishing-a-development-branch` skill |
| `magick` (ImageMagick 7, a command, not a skill) | 1 + 3 | pictures (references/evidence.md) | none: no pictures, Not tested line |
| `tesseract` (OCR, a command) | 1 + 3 | pictures: secret check before upload | none: NO-OCR, nothing uploaded, Not tested line |
| Python `playwright` module with a Chromium browser (a library) | 1 + 3 | pictures: BROWSER-SCRIPT | Playwright MCP after NO-LIST, else NO-BROWSER |
