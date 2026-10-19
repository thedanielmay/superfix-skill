# Execute sequences, code review rules and test scope

Moved from SKILL.md 1.1.1 (superfix-skill#42); edited in 1.3.0. SKILL.md says when to read this file.

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
