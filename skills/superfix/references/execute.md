# Execute sequences, code review rules and test scope

Moved from SKILL.md 1.1.1 (superfix-skill#42); edited in 1.3.0. SKILL.md says when to read this file.

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

### Execute sequences by type

**`bug`**
```
superpowers:test-driven-development (write failing test first) [sonnet/high]
→ implement fix (superpowers:subagent-driven-development for Complex) [sonnet/high]
→ run tests (impacted files: pytest <file> -n auto / npm run test -- --run <file>)
→ simplify [sonnet/high]
→ re-run impacted tests
→ pr-review-toolkit:code-reviewer [sonnet/high]
→ code-security-audit [sonnet/high]
→ pr-review-toolkit:silent-failure-hunter [sonnet/high]
→ verification-before-completion [sonnet/high]
```

**`performance`**

TDD not required - the test suite guards correctness. If the performance change modifies logic (not just queries/caching/indexes), run `superpowers:test-driven-development` first.

```
implement improvement [sonnet/high]
→ run tests
→ measure again (confirm improvement vs baseline - must show measurable gain)
→ simplify [sonnet/high]
→ re-run impacted tests
→ pr-review-toolkit:code-reviewer [sonnet/high]
→ code-security-audit [sonnet/high]
→ pr-review-toolkit:silent-failure-hunter [sonnet/high]
→ verification-before-completion [sonnet/high]
```

**`ux`**
```
superpowers:test-driven-development [sonnet/high]
→ implement [sonnet/high]
→ react-vite-best-practices (if React components changed) [sonnet/high]
→ Playwright visual verification (example-skills:webapp-testing) [sonnet/high]
→ accessibility (WCAG 2.2 check on changed components) [sonnet/high]
→ simplify [sonnet/high]
→ re-run impacted tests
→ pr-review-toolkit:code-reviewer [sonnet/high]
→ code-security-audit [sonnet/high]
→ pr-review-toolkit:silent-failure-hunter [sonnet/high]
→ verification-before-completion [sonnet/high]
```

**`architecture`**
```
implement (worktree via superpowers:using-git-worktrees; superpowers:subagent-driven-development for Complex) [sonnet/high]
→ run full test suite
→ improve-codebase-architecture (validate structural changes meet deep-module criteria) [sonnet/high]
→ pr-review-toolkit:type-design-analyzer (if diff contains new type/interface/class/dataclass) [sonnet/high]
→ simplify [sonnet/high]
→ re-run impacted tests
→ pr-review-toolkit:code-reviewer [sonnet/high]
→ code-security-audit [sonnet/high]
→ pr-review-toolkit:silent-failure-hunter [sonnet/high]
→ verification-before-completion [sonnet/high]
```

**`security`**
```
implement fix [sonnet/high]
→ run tests
→ simplify [sonnet/high]
→ re-run impacted tests
→ pr-review-toolkit:code-reviewer (cross-check) [sonnet/high]
→ code-security-audit (primary - 80%+ confidence threshold) [sonnet/high]
→ pr-review-toolkit:silent-failure-hunter [sonnet/high]
→ verification-before-completion [sonnet/high]
```

**`feature` Moderate/Complex**
```
superpowers:test-driven-development [sonnet/high]
→ implement (superpowers:subagent-driven-development for Complex) [sonnet/high]
→ run tests
→ pr-review-toolkit:type-design-analyzer (if diff contains new type/interface/class/dataclass) [sonnet/high]
→ simplify [sonnet/high]
→ re-run impacted tests
→ pr-review-toolkit:code-reviewer [sonnet/high]
→ code-security-audit [sonnet/high]
→ pr-review-toolkit:silent-failure-hunter [sonnet/high]
→ verification-before-completion [sonnet/high]
```

### Criteria mode sequence (Everything else problems, after go; references/criteria.md)

Criteria mode never reuses a code sequence above. Simple runs it on the main thread; Moderate and Complex give the fix agent this file, criteria.md and briefs.md.
- Where: a PRIVATE git repo outside any cloud mount gets the work branch (SKILL.md's shared block). Anything else (no git, a repo inside a cloud mount, a PUBLIC repo with personal or financial data, a Google file, a process) is copy mode: no branch, no commit, no PR; plan and context files go in `~/.superfix/journal/<name>/`, as for Qik; budget commits count only in git.

```
criteria.md lockcheck (CRITERIA-LOCK-OK, else stop)
→ change the branch file, or the copy from criteria.md's copy command
→ measure every check criterion on the change (--out try<n>), then the attempt and progress commands
→ repeat until every C passes, or STOP-NO-PROGRESS, STOP-CAP or a budget limit
→ review: a general-purpose agent [sonnet/high] with the review header; it reads the criterion lines, the original and the change, and looks for a check met in a way that misses the problem (a row deleted instead of merged, a value blanked, a definition read another way)
→ criteria.md's three runs (run 1 the original, run 2 the change, run 3 the negative control)
→ verification-before-completion: does the owner's description in ## Done when still hold?
→ comment check (CRITERIA-OK after LINES-OK), final comment; copy mode names the copy and the saved diff on the Mac
→ finish (ORIGINAL-UNCHANGED, WORK-DELETED) when the job ends
```

### Code review rules (all types)

- Every review agent brief starts with this review header (the same text as in `references/diagnose.md`): "Report only. Do not edit, write or create files, and do not run commands that change anything. Return findings with confidence; the caller applies fixes." After the agent returns, `git status --porcelain` must show no change it made
- Fix every **high-confidence** finding - one issue, one fix, re-verify
- Skip false positives - note and move on
- Max 2 review passes (one pass is one run of the whole review chain over the full diff); if high-confidence issues remain after pass 2, escalate to user
- Impacted tests re-run after `simplify`, before review starts
- `code-security-audit` always runs after `code-reviewer`, not instead of it

### Test scope

- Impacted files only during implementation: `pytest <file> -n auto` / `npm run test -- --run <file>`
- Full test suite once at end, before verification
- Verification re-runs the failing check in ## Problems (solved check in SKILL.md) or the baseline on the real surface (test, curl, CLI, Playwright, or the measured timing for performance), pastes the output, and states whether the issue's stated goal is met
- After pictures: SKILL.md Solved check and references/evidence.md
- Labels, diagrams, gap notes: SKILL.md, journal.md, diagrams.md, gaps.md
- Criteria mode: SKILL.md, criteria.md, journal.md
