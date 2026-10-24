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
- For turning a warning into a refusal, the safe order: (1) fix the documented workflow so a correct session never trips it, (2) make the underlying record robust with no exit-code change, (3) switch the failure on with a remedy message that names the exact command
- For narrowing a gate: fail closed by exempting only the named prose uses and keeping everything else flagged, with the old-vs-new table over both directions before the pattern is chosen

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
- Where: copy mode by default, for every criteria-mode file (data, guide or process): no branch, no commit, no PR; plan and context files go in `~/.superfix/journal/<name>/`, as for Qik; budget commits count only in git. The work branch (SKILL.md's shared block) only when criteria.md section 9's three conditions all hold: `visibility` prints PRIVATE, the owner said yes to question (b) with no names or contact details in the files, and `scan` is clean on the diff; never in a repo inside a cloud mount.

```
criteria.md lockcheck (CRITERIA-LOCK-OK, else stop); every measure through criteria.md's tool, in its sandbox
→ change the branch file, or the copy from criteria.md's copy command
→ criteria.md's attempt command on the change (--label try<n>; the tool runs every locked script itself, at most 5 per epoch), then the progress command; an approved amendment goes through criteria.md's amend
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
- Scale review depth to the diff: a small Simple fix does not run the whole chain; any skipped review goes under Not tested with why
- Loose ends the review finds in things the change itself made are not scope creep: fix them and report them
- Checklist for move-only refactors: move verbatim, re-import every name in the old module, prove byte identity per name AND whole-file identity, prove every global a moved function reads is bound in the new module, check `dir(module)` identical and import order; import-time side effects go under Not tested
- When a reviewer keeps finding new wordings, the rule is at the wrong level: look for the structure the defect lives in instead of widening an exclusion list
- Every fix round needs a regression probe against the PREVIOUS head (whatever warned there must still warn), not only the new red tests

### Independent review (gate, prompt and Moderate/Complex changes)
- When: after the PR is open, before `gh pr checks`, for Moderate and Complex, and for any diff that touches a gate or a prompt: `crit.py`, `redact-check.py`, `project.py`, `project.md`, any `tests/` script, `SKILL.md`, or a `references/*.md` file.
- The reviewer reads two things only: the PR number and the owner's own words from `## Problems`. Not the plan, the context file, the brief, the journal, or the diff.
- It runs `gh pr view <N> --json title,body,files` and `gh pr diff <N>` itself, so everything it knows comes through the PR.
- One verdict comment on the PR: `INDEPENDENT-REVIEW PASS|FAIL <n> findings`, then its findings with confidence, and the same review header as the code review rules above.
- FAIL blocks ready for review. A second pass is allowed; after that, escalate as the code review rules say.
- The main thread records the verdict's URL in the final comment, and a missing verdict goes under Not tested.

Limits:
- Nothing records what the reviewer was given, so a run can say it passed only the PR number and the owner's words and do otherwise.
- Independence means a fresh context with no plan or diff, not a separate account or a different model.
- A PASS cannot be proven deserved: the comment proves a reviewer posted, not that it read anything.
- Anyone with write access to the repo can post the verdict line.
- The path half of the trigger over-triggers on small `references/` edits and cannot tell a prompt edit from a typo fix.
- Passes cannot be counted from comments, because a comment can be edited or a second one posted elsewhere.

### Test scope

- Impacted files only during implementation: `pytest <file> -n auto` / `npm run test -- --run <file>`
- Full test suite once at end, before verification
- Verification re-runs the failing check in ## Problems (solved check in SKILL.md) or the baseline on the real surface (test, curl, CLI, Playwright, or the measured timing for performance), pastes the output, and states whether the issue's stated goal is met
- After pictures: SKILL.md Solved check and references/evidence.md
- Labels, diagrams, gap notes: SKILL.md, journal.md, diagrams.md, gaps.md
- Criteria mode: SKILL.md, criteria.md, journal.md
- Select impacted tests from the changed-file list and run those files by name, never `-k <word>`
- A corpus comparison reports how many corpus items exercise the changed path: the hit count, each hit line, and a persistent copy under /private/tmp that a reviewer can use
- Clear `__pycache__` and set `PYTHONDONTWRITEBYTECODE=1` before any mutant run
- A new test row that pins a gate or a check must kill a mutant: delete or widen the thing it claims to pin and show the row goes red, in a table. Other rows need only red on base.

### Tests-only changes

A tests-only change (new characterisation tests with no code change) replaces the solved check with negative controls: mutate the code, show the right test goes red, and revert. Keep at least one code-reviewer pass even on tests-only diffs.

### Shell and worktree

- Create worktrees with `git -C <repo> worktree add`, never assuming the session cwd is the repo; take the repo path as input.
- In a worktree flow, run `git branch --show-current` first and never create a branch the orchestrator already made.
- Never stash in a worktree flow; copy new files aside before any stash.
- Run a commit that may outlast the 600 s Bash limit with run_in_background from the start and wait for the exit notification.
- Never run two suites in one worktree at once.
- Quote for zsh: `$T` is not word-split (use `${=T}`) and `$T:lib` parses as a modifier (use `${T}:lib`). Write skill scripts for zsh, or run them through `bash -c`.

### Proof output and PR body

- Tee full check output to a file and quote the tail; a pipe through `head` drops the pass/fail lines.
- Generate the red-on-base list by running the head test file against base and paste the output; take the main sha and receipt from the same locked step. PR body fields (counts, line numbers, shas) come from command output, never memory.

### Merged tree (Phase 4)

- Before opening the PR, `git fetch origin` and compare with the proof: if origin/main moved after the solved check, merge main into the branch and re-prove (solved check runs 1 to 3 again on the merged tree).
- If the tree is not re-proved, write "merged tree not re-tested" under Not tested in the PR body and the final comment, naming the new main sha.
- Merge commits are exempt from the session-trailer rule.
