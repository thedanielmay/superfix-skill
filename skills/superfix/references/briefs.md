# Execution brief

New in 1.3.0. Read only after the owner approves at the Stop gate. Agents never load SKILL.md, so a rule kept only there is invisible to them. The fix agent dispatch passes this file by absolute path and copies the brief below into the agent prompt. The review header and the fan-out brief used during diagnosis are in `references/diagnose.md`; review agents during execution get the review header written out in `references/execute.md`.

### Fix agent brief (Moderate, Complex; Phase 3)

FIX AGENT BRIEF (Moderate, Complex): branch, context file, plan file, Problem
Profile, execute.md path, this file's path, the budget and approval-sha from
the ## Decision section, the session redaction file path. Before every commit, run the
budget commands; over any limit, stop and return a message whose first line is
exactly BUDGET STOP, then done, left, used versus budget. Before every push or
post, run the redaction check (references/redaction.md, absolute path given).
Run the solved check before declaring done. Tick plan checkboxes as you go.
Do not post to GitHub; return results to the caller.

Budget commands (copy into the brief with the real values):

```bash
git rev-list --count <approval-sha>..HEAD -- . ':(exclude)docs/superpowers/plans'   # commits
git diff --name-only <approval-sha>...HEAD                                          # files; any file not named = over
date                                                                                # time, minus the approval time
```

Solved check (copy into the brief): run 1, the failing check from `## Problems` on approval-sha, fails. Run 2, the same check on the branch, passes. Run 3, in a scratch worktree of HEAD, reverse-apply the non-test part of `git diff <approval-sha>...HEAD`, run the check, expect failure, remove the worktree; the branch is never touched. Return all three outputs. Two failed run-2 attempts, whatever the cause: stop and return "My fix failed twice, so my diagnosis was wrong." with used versus budget.
